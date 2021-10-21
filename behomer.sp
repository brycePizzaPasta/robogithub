#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <sm_logger>
#include <berobot_constants>
#include <berobot>
#include <sdkhooks>
#include <tf_custom_attributes>

#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Manual Homer"
#define ROBOT_ROLE "Damage"
#define ROBOT_DESCRIPTION "Manual Homing Rockets"

#define GSOLDIER		"models/bots/soldier_boss/bot_soldier_boss.mdl"
#define SPAWN	"#mvm/giant_heavy/giant_heavy_entrance.wav"
#define DEATH	"mvm/giant_soldier/giant_soldier_explode.wav"
#define LOOP	"mvm/giant_soldier/giant_soldier_loop.wav"

#define LEFTFOOT        ")mvm/giant_soldier/giant_soldier_step01.wav"
#define LEFTFOOT1       ")mvm/giant_soldier/giant_soldier_step03.wav"
#define RIGHTFOOT       ")mvm/giant_soldier/giant_soldier_step02.wav"
#define RIGHTFOOT1      ")mvm/giant_soldier/giant_soldier_step04.wav"

#define GUNFIRE	")mvm/giant_soldier/giant_soldier_rocket_shoot.wav"
#define GUNFIRE_CRIT	")mvm/giant_soldier/giant_soldier_rocket_shoot_crit.wav"
#define GUNFIRE_EXPLOSION	")mvm/giant_soldier/giant_soldier_rocket_explode.wav"


#define MAX_ENTITY_LIMIT 2048

bool g_bHomingEnabled[MAX_ENTITY_LIMIT + 1];
float g_flHomingAccuracy[MAX_ENTITY_LIMIT + 1];
int g_iLauncher[MAX_ENTITY_LIMIT + 1];

float g_flHomingPoint[MAX_ENTITY_LIMIT + 1][3];
int g_iLatestProjectile[MAX_ENTITY_LIMIT + 1];

Handle g_KillTimer[MAX_ENTITY_LIMIT + 1];

int g_iBlueGlowModelID = -1;
int g_iRedGlowModelID = -1;

public Plugin:myinfo = 
{
	name = "[TF2] Be the Giant Homer Soldier",
	author = "Erofix using the code from: Pelipoika, PC Gamer, Jaster and StormishJustice",
	description = "Play as the Giant Homer",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}

char LOG_TAGS[][] = {"VERBOSE", "INFO", "ERROR"};
enum(<<= 1)
{
    SML_VERBOSE = 1,
    SML_INFO,
    SML_ERROR,
}

public OnPluginStart()
{
    SMLoggerInit(LOG_TAGS, sizeof(LOG_TAGS), SML_ERROR, SML_FILE);

    LoadTranslations("common.phrases");

    //	HookEvent("post_inventory_application", EventInventoryApplication, EventHookMode_Post);
    AddNormalSoundHook(BossHomer);

    Robot robot;
    robot.name = ROBOT_NAME;
    robot.role = ROBOT_ROLE;
    robot.class = "Soldier";
    robot.shortDescription = ROBOT_DESCRIPTION;
    robot.sounds.spawn = SPAWN;
    robot.sounds.loop = LOOP;
    robot.sounds.death = DEATH;
    AddRobot(robot, MakeGiantSoldier, PLUGIN_VERSION);
}

public void OnPluginEnd()
{
	RemoveRobot(ROBOT_NAME);
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
//	CreateNative("BeGiantPyro_MakeGiantSoldier", Native_SetGiantPyro);
//	CreateNative("BeGiantPyro_IsGiantPyro", Native_IsGiantPyro);
	return APLRes_Success;
}

public OnMapStart()
{
	PrecacheModel(GSOLDIER);
	PrecacheSound(SPAWN);
	PrecacheSound(DEATH);
	PrecacheSound(LOOP);

	PrecacheSound(GUNFIRE);
	PrecacheSound(GUNFIRE_CRIT);
	PrecacheSound(GUNFIRE_EXPLOSION);
	

	PrecacheSound(LEFTFOOT);
	PrecacheSound(LEFTFOOT1);
	PrecacheSound(RIGHTFOOT);
	PrecacheSound(RIGHTFOOT1);
	
	//PrecacheSound(SOUND_GUNFIRE);
	//PrecacheSound(SOUND_WINDUP);
	g_iBlueGlowModelID = PrecacheModel("sprites/blueglow1.vmt");
	g_iRedGlowModelID = PrecacheModel("sprites/redglow1.vmt");
}

/* public EventInventoryApplication(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(g_bIsGSoldier[client])
	{
		g_bIsGSoldier[client] = false;
	}
} */

public Action:SetModel(client, const String:model[])
{
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		SetVariantString(model);
		AcceptEntityInput(client, "SetCustomModel");

		SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
	}
}

public Action:BossHomer(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{
	if (!IsValidClient(entity)) return Plugin_Continue;
	if (!IsRobot(entity, ROBOT_NAME)) return Plugin_Continue;

	if (strncmp(sample, "player/footsteps/", 17, false) == 0)
	{
		if (StrContains(sample, "1.wav", false) != -1)
		{
			Format(sample, sizeof(sample), LEFTFOOT);
			EmitSoundToAll(sample, entity);
		}
		else if (StrContains(sample, "3.wav", false) != -1)
		{
			Format(sample, sizeof(sample), LEFTFOOT1);
			EmitSoundToAll(sample, entity);
		}
		else if (StrContains(sample, "2.wav", false) != -1)
		{
			Format(sample, sizeof(sample), RIGHTFOOT);
			EmitSoundToAll(sample, entity);
		}
		else if (StrContains(sample, "4.wav", false) != -1)
		{
			Format(sample, sizeof(sample), RIGHTFOOT1);
			EmitSoundToAll(sample, entity);
		}
		return Plugin_Changed;
	}

	
	if (strncmp(sample, ")weapons/", 9, false) == 0)
	{
		if (StrContains(sample, "rocket_shoot.wav", false) != -1)
		{
			Format(sample, sizeof(sample), GUNFIRE);
			EmitSoundToAll(sample, entity);
			
		}
		else if (StrContains(sample, "rocket_shoot_crit.wav", false) != -1)
		{
			Format(sample, sizeof(sample), GUNFIRE_CRIT);
			EmitSoundToAll(sample, entity);
		}
		
		//Explosion doesnæt quite work
		/* 		else if (StrContains(sample, "explode1.wav", false) != -1)
		{
			Format(sample, sizeof(sample), GUNFIRE_EXPLOSION);
			EmitSoundToAll(sample, entity);
		}
		else if (StrContains(sample, "explode2.wav", false) != -1)
		{
			Format(sample, sizeof(sample), GUNFIRE_EXPLOSION);
			EmitSoundToAll(sample, entity);
		}
		else if (StrContains(sample, "explode3.wav", false) != -1)
		{
			Format(sample, sizeof(sample), GUNFIRE_EXPLOSION);
			EmitSoundToAll(sample, entity);
		} */
		return Plugin_Changed;
	}
	if (volume == 0.0 || volume == 0.9997) return Plugin_Continue;
}

MakeGiantSoldier(client)
{
	SMLogTag(SML_VERBOSE, "Createing Homer");
	TF2_SetPlayerClass(client, TFClass_Soldier);
	TF2_RegeneratePlayer(client);

	new ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	if (ragdoll > MaxClients && IsValidEntity(ragdoll)) AcceptEntityInput(ragdoll, "Kill");
	decl String:weaponname[32];
	GetClientWeapon(client, weaponname, sizeof(weaponname));
	if (strcmp(weaponname, "tf_weapon_", false) == 0) 
	{
		SetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_iWeaponState", 0);
		TF2_RemoveCondition(client, TFCond_Slowed);
	}
	CreateTimer(0.0, Timer_Switch, client);
	SetModel(client, GSOLDIER);
	
	int iHealth = 3800;
		
	int MaxHealth = 200;
	//PrintToChatAll("MaxHealth %i", MaxHealth);
	
	int iAdditiveHP = iHealth - MaxHealth;
	
	TF2_SetHealth(client, iHealth);
	// PrintToChatAll("iHealth %i", iHealth);
	
	// PrintToChatAll("iAdditiveHP %i", iAdditiveHP);
	
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.75);
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", true);
	TF2Attrib_SetByName(client, "max health additive bonus", float(iAdditiveHP));
	TF2Attrib_SetByName(client, "ammo regen", 100.0);
	TF2Attrib_SetByName(client, "move speed penalty", 0.6);
	TF2Attrib_SetByName(client, "damage force reduction", 0.4);
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.4);
	TF2Attrib_SetByName(client, "airblast vertical vulnerability multiplier", 0.1);
	TF2Attrib_SetByName(client, "health from packs decreased", 0.0);
	TF2Attrib_SetByName(client, "cancel falling damage", 1.0);
	TF2Attrib_SetByName(client, "patient overheal penalty", 0.0);
	TF2Attrib_SetByName(client, "mult_patient_overheal_penalty_active", 0.0);
	//TF2Attrib_SetByName(client, "override footstep sound set", 3.0);
	TF2Attrib_SetByName(client, "health from healers increased", 3.0);
	TF2Attrib_SetByName(client, "rage giving scale", 0.85);
	UpdatePlayerHitbox(client, 1.75);
	
	TF2_RemoveCondition(client, TFCond_CritOnFirstBlood);
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);
	
	PrintToChat(client, "1. You are now Homer soldier !");
	
}

stock TF2_SetHealth(client, NewHealth)
{
	SetEntProp(client, Prop_Send, "m_iHealth", NewHealth, 1);
	SetEntProp(client, Prop_Data, "m_iHealth", NewHealth, 1);
}

public Action:Timer_Switch(Handle:timer, any:client)
{
	if (IsValidClient(client))
		GiveGiantPyro(client);
}

stock GiveGiantPyro(client)
{
	if (IsValidClient(client))
	{
		g_bHomingEnabled[client] = true;
		TF2_RemoveAllWearables(client);

		TF2_RemoveWeaponSlot(client, 0);
		TF2_RemoveWeaponSlot(client, 1);
		TF2_RemoveWeaponSlot(client, 2);
		CreateWeapon(client, "tf_weapon_rocketlauncher", 513, 6, 1, 2, 0);
		
//		CreateWeapon(client, "tf_weapon_shovel", 447, 6, 1, 2, 0);
		
		
		CreateHat(client, 1063, 10, 6, true); //Gatebot
		//CreateHat(client, 647, 10, 6, true); //The All-Father
		//CreateHat(client, 343, 10, 6, true);//Professor speks

		int Weapon1 = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
		//int Weapon2 = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
		
		if(IsValidEntity(Weapon1))
		{
			TF2Attrib_RemoveAll(Weapon1);
			
			TF2Attrib_SetByName(Weapon1, "damage penalty", 0.7);
			TF2Attrib_SetByName(Weapon1, "maxammo primary increased", 2.5);
			TF2Attrib_SetByName(Weapon1, "killstreak tier", 1.0);			
		//	TF2Attrib_SetByName(Weapon1, "clipsize increase on kill", 4.0);		
			TF2Attrib_SetByName(Weapon1, "clip size upgrade atomic", 2.0);
			TF2Attrib_SetByName(Weapon1, "fire rate bonus", 1.1);
			TF2Attrib_SetByName(Weapon1, "faster reload rate", 3.5);
			TF2CustAttr_SetString(Weapon1, "reload full clip at once", "1.0");
			TF2Attrib_SetByName(Weapon1, "projectile speed decreased", 0.8);
			TF2Attrib_SetByName(Weapon1, "killstreak tier", 1.0);

			TF2CustAttr_SetString(Weapon1, "crosshair guided projectiles", "1.0");
			TF2CustAttr_SetString(Weapon1, "projectile lifetime", "5.0");
			//TF2CustAttr_SetString(Weapon1, "homing_proj_mvm", "detection_radius=250.0 homing_mode=1 projectilename=tf_projectile_rocket");			
		//	TF2Attrib_SetByName(Weapon1, "rocket specialist", 1.0);
			//TF2Attrib_SetByName(Weapon1, "dmg penalty vs buildings", 0.5);
			
			
		//	TF2Attrib_SetByName(Weapon1, "disable fancy class select anim", 1.0);
						
\			
		}
		

	}
}


public Native_SetGiantPyro(Handle:plugin, args)
	MakeGiantSoldier(GetNativeCell(1));

	
stock bool:IsValidClient(client)
{
	if (client <= 0) return false;
	if (client > MaxClients) return false;
	return IsClientInGame(client);
}

bool CreateHat(int client, int itemindex, int level, int quality, bool scale)
{
	int hat = CreateEntityByName("tf_wearable");
	
	if (!IsValidEntity(hat))
	{
		return false;
	}
	
	char entclass[64];
	GetEntityNetClass(hat, entclass, sizeof(entclass));
	SetEntData(hat, FindSendPropInfo(entclass, "m_iItemDefinitionIndex"), itemindex);
	SetEntData(hat, FindSendPropInfo(entclass, "m_bInitialized"), 1); 	
	SetEntData(hat, FindSendPropInfo(entclass, "m_iEntityLevel"), level);
	SetEntData(hat, FindSendPropInfo(entclass, "m_iEntityQuality"), quality);
	SetEntProp(hat, Prop_Send, "m_bValidatedAttachedEntity", 1);  	
	
	//TFTeam iTeam = view_as<TFTeam>(GetEntProp(client, Prop_Send, "m_iTeamNum"));
		
//		CreateHat(client, 183, 10, 6, true); //Sergeant's Drill Hat
		//CreateHat(client, 647, 10, 6, true); //The All-Father
		//CreateHat(client, 343, 10, 6, false);//Professor Speks

	switch (itemindex)
	{
	case 183://Sergeant's Drill Hat
		{
/* 			if (iTeam == TFTeam_Blue){
				TF2Attrib_SetByDefIndex(hat, 142, 12807213.0);
				TF2Attrib_SetByDefIndex(hat, 261, 12807213.0);
			}
			if (iTeam == TFTeam_Red){
				TF2Attrib_SetByDefIndex(hat, 142, 12091445.0);
				TF2Attrib_SetByDefIndex(hat, 261, 12091445.0);
			} */
		}
	case 647://The All-Father
		{
/* 			
			if (iTeam == TFTeam_Blue){
				TF2Attrib_SetByDefIndex(hat, 142, 12807213.0);
				TF2Attrib_SetByDefIndex(hat, 261, 12807213.0);
			}
			if (iTeam == TFTeam_Red){
				TF2Attrib_SetByDefIndex(hat, 142, 12091445.0);
				TF2Attrib_SetByDefIndex(hat, 261, 12091445.0);
			} */
		}
	case 343://Professor Speks
	{
		TF2Attrib_SetByDefIndex(hat, 542, 1.0);//item style
	}
	


	}
	
	if (scale == true){
		SetEntData(hat, FindSendPropInfo(entclass, "m_flModelScale"), 0.75);
	}

	DispatchSpawn(hat);
	EquipWearable(client, hat);
	return true;
}

stock void RemoveAllWearables(int client)
{
	int edict = MaxClients+1;
	while((edict = FindEntityByClassname(edict, "tf_wearable")) != -1)
	{
		char netclass[32];
		if (GetEntityNetClass(edict, netclass, sizeof(netclass)) && StrEqual(netclass, "CTFWearable"))
		{
			if (GetEntPropEnt(edict, Prop_Send, "m_hOwnerEntity") == client && !GetEntProp(edict, Prop_Send, "m_bDisguiseWearable"))
			{
				AcceptEntityInput(edict, "Kill");
			}
		}
	}
}

stock Action RemoveWearable(int client, char[] classname, char[] networkclass)
{
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		int edict = MaxClients+1;
		while((edict = FindEntityByClassname(edict, classname)) != -1)
		{
			char netclass[32];
			if (GetEntityNetClass(edict, netclass, sizeof(netclass)) && StrEqual(netclass, networkclass))
			{
				if (GetEntPropEnt(edict, Prop_Send, "m_hOwnerEntity") == client)
				{
					AcceptEntityInput(edict, "Kill"); 
				}
			}
		}
	}
}

bool CreateWeapon(int client, char[] classname, int itemindex, int quality, int level, int slot, int paint)
{
	TF2_RemoveWeaponSlot(client, slot);
	
	int weapon = CreateEntityByName(classname);
	
	if (!IsValidEntity(weapon))
	{
		return false;
	}
	
	char entclass[64];
	GetEntityNetClass(weapon, entclass, sizeof(entclass));
	SetEntData(weapon, FindSendPropInfo(entclass, "m_iItemDefinitionIndex"), itemindex);	 
	SetEntData(weapon, FindSendPropInfo(entclass, "m_bInitialized"), 1);
	SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityQuality"), quality);
	SetEntProp(weapon, Prop_Send, "m_bValidatedAttachedEntity", 1); 
	
	if (level)
	{
		SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityLevel"), level);
	}
	else
	{
		SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityLevel"), GetRandomInt(1,99));
	}

	TF2Attrib_SetByDefIndex(weapon, 834, view_as<float>(paint));	//Set Warpaint
	
	switch (itemindex)
	{
	case 810, 736, 933, 1080, 1102:
		{
			SetEntData(weapon, FindSendPropInfo(entclass, "m_iObjectType"), 3);
		}
	case 998:
		{
			SetEntData(weapon, FindSendPropInfo(entclass, "m_nChargeResistType"), GetRandomInt(0,2));
		}
	case 1071:
		{
			TF2Attrib_SetByName(weapon, "item style override", 0.0);
			TF2Attrib_SetByName(weapon, "loot rarity", 1.0);		
			TF2Attrib_SetByName(weapon, "turn to gold", 1.0);

			DispatchSpawn(weapon);
			EquipPlayerWeapon(client, weapon);
			
			return true; 
		}		
	}

	if(quality == 9)
	{
		TF2Attrib_SetByName(weapon, "is australium item", 1.0);
		TF2Attrib_SetByName(weapon, "item style override", 1.0);
	}

	if(itemindex == 200 || itemindex == 220 || itemindex == 448 || itemindex == 15002 || itemindex == 15015 || itemindex == 15021 || itemindex == 15029 || itemindex == 15036 || itemindex == 15053 || itemindex == 15065 || itemindex == 15069 || itemindex == 15106 || itemindex == 15107 || itemindex == 15108 || itemindex == 15131 || itemindex == 15151 || itemindex == 15157 || itemindex == 449 || itemindex == 15013 || itemindex == 15018 || itemindex == 15035 || itemindex == 15041 || itemindex == 15046 || itemindex == 15056 || itemindex == 15060 || itemindex == 15061 || itemindex == 15100 || itemindex == 15101
			|| itemindex == 15102 || itemindex == 15126 || itemindex == 15148 || itemindex == 44 || itemindex == 221 || itemindex == 205 || itemindex == 228 || itemindex == 1104 || itemindex == 15006 || itemindex == 15014 || itemindex == 15028 || itemindex == 15043 || itemindex == 15052 || itemindex == 15057 || itemindex == 15081 || itemindex == 15104 || itemindex == 15105 || itemindex == 15129 || itemindex == 15130 || itemindex == 15150 || itemindex == 196 || itemindex == 447 || itemindex == 208 || itemindex == 215 || itemindex == 1178 || itemindex == 15005 || itemindex == 15017 || itemindex == 15030 || itemindex == 15034
			|| itemindex == 15049 || itemindex == 15054 || itemindex == 15066 || itemindex == 15067 || itemindex == 15068 || itemindex == 15089 || itemindex == 15090 || itemindex == 15115 || itemindex == 15141 || itemindex == 351 || itemindex == 740 || itemindex == 192 || itemindex == 214 || itemindex == 326 || itemindex == 206 || itemindex == 308 || itemindex == 996 || itemindex == 1151 || itemindex == 15077 || itemindex == 15079 || itemindex == 15091 || itemindex == 15092 || itemindex == 15116 || itemindex == 15117 || itemindex == 15142 || itemindex == 15158 || itemindex == 207 || itemindex == 130 || itemindex == 15009
			|| itemindex == 15012 || itemindex == 15024 || itemindex == 15038 || itemindex == 15045 || itemindex == 15048 || itemindex == 15082 || itemindex == 15083 || itemindex == 15084 || itemindex == 15113 || itemindex == 15137 || itemindex == 15138 || itemindex == 15155 || itemindex == 172 || itemindex == 327 || itemindex == 404 || itemindex == 202 || itemindex == 41 || itemindex == 312 || itemindex == 424 || itemindex == 15004 || itemindex == 15020 || itemindex == 15026 || itemindex == 15031 || itemindex == 15040 || itemindex == 15055 || itemindex == 15086 || itemindex == 15087 || itemindex == 15088 || itemindex == 15098
			|| itemindex == 15099 || itemindex == 15123 || itemindex == 15124 || itemindex == 15125 || itemindex == 15147 || itemindex == 425 || itemindex == 997 || itemindex == 197 || itemindex == 329 || itemindex == 15073 || itemindex == 15074 || itemindex == 15075 || itemindex == 15139 || itemindex == 15140 || itemindex == 15114 || itemindex == 15156 || itemindex == 305 || itemindex == 211 || itemindex == 15008 || itemindex == 15010 || itemindex == 15025 || itemindex == 15039 || itemindex == 15050 || itemindex == 15078 || itemindex == 15097 || itemindex == 15121 || itemindex == 15122 || itemindex == 15123 || itemindex == 15145
			|| itemindex == 15146 || itemindex == 35 || itemindex == 411 || itemindex == 37 || itemindex == 304 || itemindex == 201 || itemindex == 402 || itemindex == 15000 || itemindex == 15007 || itemindex == 15019 || itemindex == 15023 || itemindex == 15033 || itemindex == 15059 || itemindex == 15070 || itemindex == 15071 || itemindex == 15072 || itemindex == 15111 || itemindex == 15112 || itemindex == 15135 || itemindex == 15136 || itemindex == 15154 || itemindex == 203 || itemindex == 15001 || itemindex == 15022 || itemindex == 15032 || itemindex == 15037 || itemindex == 15058 || itemindex == 15076 || itemindex == 15110
			|| itemindex == 15134 || itemindex == 15153 || itemindex == 193 || itemindex == 401 || itemindex == 210 || itemindex == 15011 || itemindex == 15027 || itemindex == 15042 || itemindex == 15051 || itemindex == 15062 || itemindex == 15063 || itemindex == 15064 || itemindex == 15103 || itemindex == 15128 || itemindex == 15129 || itemindex == 15149 || itemindex == 194 || itemindex == 649 || itemindex == 15062 || itemindex == 15094 || itemindex == 15095 || itemindex == 15096 || itemindex == 15118 || itemindex == 15119 || itemindex == 15143 || itemindex == 15144 || itemindex == 209 || itemindex == 15013 || itemindex == 15018
			|| itemindex == 15035 || itemindex == 15041 || itemindex == 15046 || itemindex == 15056 || itemindex == 15060 || itemindex == 15061 || itemindex == 15100 || itemindex == 15101 || itemindex == 15102 || itemindex == 15126 || itemindex == 15148 || itemindex == 415 || itemindex == 15003 || itemindex == 15016 || itemindex == 15044 || itemindex == 15047 || itemindex == 15085 || itemindex == 15109 || itemindex == 15132 || itemindex == 15133 || itemindex == 15152 || itemindex == 1153)
	{
		if(GetRandomInt(1,15) == 1)
		{
			TF2Attrib_SetByDefIndex(weapon, 2053, 1.0);
		}
	}
	
	if(quality == 11)
	{
		if (GetRandomInt(1,10) == 1)
		{
			TF2Attrib_SetByDefIndex(weapon, 2025, 1.0);
		}
		else if (GetRandomInt(1,10) == 2)
		{
			TF2Attrib_SetByDefIndex(weapon, 2025, 2.0);
			TF2Attrib_SetByDefIndex(weapon, 2014, GetRandomInt(1,7) + 0.0);
		}
		else if (GetRandomInt(1,10) == 3)
		{
			TF2Attrib_SetByDefIndex(weapon, 2025, 3.0);
			TF2Attrib_SetByDefIndex(weapon, 2014, GetRandomInt(1,7) + 0.0);
			TF2Attrib_SetByDefIndex(weapon, 2013, GetRandomInt(2002,2008) + 0.0);
		}
		TF2Attrib_SetByDefIndex(weapon, 214, view_as<float>(GetRandomInt(0, 9000)));
	}
	
	if (quality == 15)
	{
		switch(itemindex)
		{
		case 30666, 30667, 30668, 30665:
			{
				TF2Attrib_RemoveByDefIndex(weapon, 725);
			}
		default:
			{
				TF2Attrib_SetByDefIndex(weapon, 725, GetRandomFloat(0.0,1.0));
			}
		}
	}

	if (itemindex == 405 || itemindex == 608 || itemindex == 1101 || itemindex == 133 || itemindex == 444 || itemindex == 57 || itemindex == 231 || itemindex == 642 || itemindex == 131 || itemindex == 406 || itemindex == 1099 || itemindex == 1144)
	{
		DispatchSpawn(weapon);
		EquipWearable(client, weapon);
	}
	else
	{
		DispatchSpawn(weapon);
		EquipPlayerWeapon(client, weapon);
	}
	
	if (quality !=9)
	{
		if (itemindex == 13
				|| itemindex == 200
				|| itemindex == 23
				|| itemindex == 209
				|| itemindex == 18
				|| itemindex == 205
				|| itemindex == 10
				|| itemindex == 199
				|| itemindex == 21
				|| itemindex == 208
				|| itemindex == 12
				|| itemindex == 19
				|| itemindex == 206
				|| itemindex == 20
				|| itemindex == 207
				|| itemindex == 15
				|| itemindex == 202
				|| itemindex == 11
				|| itemindex == 9
				|| itemindex == 22
				|| itemindex == 29
				|| itemindex == 211
				|| itemindex == 14
				|| itemindex == 201
				|| itemindex == 16
				|| itemindex == 203
				|| itemindex == 24
				|| itemindex == 210)	
		{
			if (GetRandomInt(1,2) < 3)
			{
				TF2_SwitchtoSlot(client, slot);
				int iRand = GetRandomInt(1,4);
				if (iRand == 1)
				{
					TF2Attrib_SetByDefIndex(weapon, 134, 701.0);	
				}
				else if (iRand == 2)
				{
					TF2Attrib_SetByDefIndex(weapon, 134, 702.0);	
				}	
				else if (iRand == 3)
				{
					TF2Attrib_SetByDefIndex(weapon, 134, 703.0);	
				}
				else if (iRand == 4)
				{
					TF2Attrib_SetByDefIndex(weapon, 134, 704.0);	
				}
			}
		}
	}

	return true;
}

stock void TF2_SwitchtoSlot(int client, int slot)
{
	if (slot >= 0 && slot <= 5 && IsClientInGame(client) && IsPlayerAlive(client))
	{
		char wepclassname[64];
		int wep = GetPlayerWeaponSlot(client, slot);
		if (wep > MaxClients && IsValidEdict(wep) && GetEdictClassname(wep, wepclassname, sizeof(wepclassname)))
		{
			FakeClientCommandEx(client, "use %s", wepclassname);
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", wep);
		}
	}
}

stock void TF2_RemoveAllWearables(int client)
{
	int wearable = -1;
	while ((wearable = FindEntityByClassname(wearable, "tf_wearable*")) != -1)
	{
		if (IsValidEntity(wearable))
		{
			int player = GetEntPropEnt(wearable, Prop_Send, "m_hOwnerEntity");
			if (client == player)
			{
				TF2_RemoveWearable(client, wearable);
			}
		}
	}

	while ((wearable = FindEntityByClassname(wearable, "tf_powerup_bottle")) != -1)
	{
		if (IsValidEntity(wearable))
		{
			int player = GetEntPropEnt(wearable, Prop_Send, "m_hOwnerEntity");
			if (client == player)
			{
				TF2_RemoveWearable(client, wearable);
			}
		}
	}

	while ((wearable = FindEntityByClassname(wearable, "tf_weapon_spellbook")) != -1)
	{
		if (IsValidEntity(wearable))
		{
			int player = GetEntPropEnt(wearable, Prop_Send, "m_hOwnerEntity");
			if (client == player)
			{
				TF2_RemoveWearable(client, wearable);
			}
		}
	}
}

// public OnGameFrame()
// {
// 	for(new i = 1; i <= MaxClients; i++)
// 	{
// 		if(IsRobot(i, ROBOT_NAME))
// 		{
// 		//	SetHomingProjectile(i, "tf_projectile_arrow");
// 		//	SetHomingProjectile(i, "tf_projectile_energy_ball");
// 		//	SetHomingProjectile(i, "tf_projectile_flare");
// 		//	SetHomingProjectile(i, "tf_projectile_healing_bolt");
// 			SetHomingProjectile(i, "tf_projectile_rocket");
// 		//	SetHomingProjectile(i, "tf_projectile_sentryrocket");
// 		//	SetHomingProjectile(i, "tf_projectile_syringe");
// 		}
// 	}
// }

// SetHomingProjectile(client, const String:classname[])
// {
// 	new entity = -1; 
// 	while((entity = FindEntityByClassname(entity, classname))!=INVALID_ENT_REFERENCE)
// 	{
// 		new owner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
// 		if(!IsValidEntity(owner)) continue;
// 		if(StrEqual(classname, "tf_projectile_sentryrocket", false)) owner = GetEntPropEnt(owner, Prop_Send, "m_hBuilder");		
// 		new Target = GetClosestTarget(entity, owner);
// 		if(!Target) continue;
// 		if(owner == client)
// 		{
// 			new Float:ProjLocation[3], Float:ProjVector[3], Float:ProjSpeed, Float:ProjAngle[3], Float:TargetLocation[3], Float:AimVector[3];			
// 			GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", ProjLocation);
// 			GetClientAbsOrigin(Target, TargetLocation);
// 			TargetLocation[2] += 40.0;
// 			MakeVectorFromPoints(ProjLocation, TargetLocation , AimVector);
// 			GetEntPropVector(entity, Prop_Data, "m_vecAbsVelocity", ProjVector);					
// 			ProjSpeed = GetVectorLength(ProjVector);					
// 			AddVectors(ProjVector, AimVector, ProjVector);	
// 			NormalizeVector(ProjVector, ProjVector);
// 			GetEntPropVector(entity, Prop_Data, "m_angRotation", ProjAngle);
// 			GetVectorAngles(ProjVector, ProjAngle);
// 			SetEntPropVector(entity, Prop_Data, "m_angRotation", ProjAngle);					
// 			ScaleVector(ProjVector, ProjSpeed);
// 			SetEntPropVector(entity, Prop_Data, "m_vecAbsVelocity", ProjVector);
// 		}
// 	}	
// }

// GetClosestTarget(entity, owner)
// {
// 	new Float:TargetDistance = 0.0;
// 	new ClosestTarget = 0;
// 	for(new i = 1; i <= MaxClients; i++) 
// 	{
// 		if(!IsClientConnected(i) || !IsPlayerAlive(i) || i == owner || (GetClientTeam(owner) == GetClientTeam(i))) continue;
// 		new Float:EntityLocation[3], Float:TargetLocation[3];
// 		GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", EntityLocation);
// 		GetClientAbsOrigin(i, TargetLocation);
		
// 		new Float:distance = GetVectorDistance(EntityLocation, TargetLocation);
// 		if(TargetDistance)
// 		{
// 			if(distance < TargetDistance) 
// 			{
// 				ClosestTarget = i;
// 				TargetDistance = distance;			
// 			}
// 		}
// 		else
// 		{
// 			ClosestTarget = i;
// 			TargetDistance = distance;
// 		}
// 	}
// 	return ClosestTarget;
// }


// public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3])
// {
// 	static bool bPressed[MAXPLAYERS + 1] =  { false, ... };
// 	if (IsClientInGame(client) && IsPlayerAlive(client))
// 	{
// 		int weapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
// 		if (IsRobot(client, ROBOT_NAME))
// 		{
// 			if(buttons & IN_ATTACK2)
// 			{
// 				if(!bPressed[client])
// 				{
// 					if(IsValidEntity(g_iLatestProjectile[weapon]))
// 					{
// 						g_bHomingEnabled[g_iLatestProjectile[weapon]] = true;
// 						GetPlayerEyePosition(client, g_flHomingPoint[g_iLatestProjectile[weapon]]);
// 					}else{
// 						ClientCommand(client, "playgamesound common/wpn_denyselect.wav");
// 					}
// 					bPressed[client] = true;
// 				}
// 			}else bPressed[client] = false;

// 			if (!TF2_IsPlayerInCondition(client, TFCond_Taunting) && !TF2_IsPlayerInCondition(client, TFCond_Taunting))
// 			{
// 				float flTargetPos[3];
// 				GetPlayerEyePosition(client, flTargetPos);

// 				if (GetClientTeam(client) == 2) TE_SetupGlowSprite( flTargetPos, g_iRedGlowModelID, 0.1, 0.17, 75 );
// 				else TE_SetupGlowSprite( flTargetPos, g_iBlueGlowModelID, 0.1, 0.17, 25 );

// 				TE_SendToClient(client);
// 			}
// 		}
// 	}
// }

// bool GetPlayerEyePosition(int client, float pos[3])
// {
// 	float vAngles[3], vOrigin[3];
// 	GetClientEyePosition(client, vOrigin);
// 	GetClientEyeAngles(client, vAngles);

// 	Handle trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer, client);

// 	if (TR_DidHit(trace))
// 	{
// 		TR_GetEndPosition(pos, trace);
// 		delete trace;
// 		return true;
// 	}
// 	delete trace;
// 	return false;
// }

// public bool TraceEntityFilterPlayer(int entity, int contentsMask, any data)
// {
// 	if (entity <= 0) return true;
// 	if (entity == data) return false;

// 	char sClassname[128];
// 	GetEdictClassname(entity, sClassname, sizeof(sClassname));
// 	if (StrEqual(sClassname, "func_respawnroomvisualizer", false)) return false;
// 	else return true;
// }

// public void OnGameFrame()
// {
// 	int entity;
// 	while ((entity = FindEntityByClassname(entity, "tf_projectile_*")) != INVALID_ENT_REFERENCE)
// 	{
// 		if(IsValidEntity(g_iLauncher[entity]))
// 		{
// 			if(g_bHomingEnabled[entity])
// 			{
// 				int iOwner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
// 				if (iOwner == -1)continue;
// 				int iActiveWeapon = GetEntPropEnt(iOwner, Prop_Data, "m_hActiveWeapon");

// 				if (iActiveWeapon != g_iLauncher[entity])continue;
// 				if(
// 					!IsClientInGame(iOwner) ||
// 					!IsPlayerAlive(iOwner) ||
// 					(
// 						HasEntProp(entity, Prop_Send, "m_iDeflected") &&
// 						GetEntProp(entity, Prop_Send, "m_iDeflected") == 1
// 					)
// 				)
// 				{
// 					g_bHomingEnabled[entity] = false;
// 					continue;
// 				}

// 				float flRocketAng[3];
// 				float flRocketVec[3];
// 				float flRocketPos[3];

// 				float flTargetPos[3];
// 				float flTargetVec[3];

// 				for (int i = 0; i < 3; i++)flTargetPos[i] = g_flHomingPoint[entity][i];

// 				GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", flRocketPos);
// 				GetEntPropVector(entity, Prop_Data, "m_angRotation", flRocketAng);
// 				GetEntPropVector(entity, Prop_Data, "m_vecAbsVelocity", flRocketVec);
// 				float flRocketSpeed = GetVectorLength( flRocketVec );

// 				SubtractVectors(flTargetPos, flRocketPos, flTargetVec);
// 				ScaleVector(flTargetVec, g_flHomingAccuracy[entity]);
// 				AddVectors(flTargetVec, flRocketVec, flRocketVec);
// 				NormalizeVector(flRocketVec, flRocketVec);
// 				GetVectorAngles(flRocketVec, flRocketAng);
// 				ScaleVector(flRocketVec, flRocketSpeed);

// 				SetEntPropVector(entity, Prop_Data, "m_angRotation", flRocketAng);

// 				SetEntPropVector(entity, Prop_Data, "m_vecAbsVelocity", flRocketVec);
// 			}
// 		}
// 	}
// }
// public void OnEntityCreated(int entity, const char[] classname)
// {
// 	if (entity < 1) return;

// 	g_iLauncher[entity] = 0;
// 	g_bHomingEnabled[entity] = false;
// 	g_flHomingAccuracy[entity] = 0.0;
// 	g_iLatestProjectile[entity] = INVALID_ENT_REFERENCE;

// 	if (StrContains(classname, "tf_projectile_") != -1)
// 	{
// 		CreateTimer(0.001, Timer_OnSpawn, entity);
// 	}
// }
// public Action Timer_OnSpawn(Handle timer, any entity)
// {
// 	if (!IsValidEdict(entity))return;
// 	int iOwner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
// 	if (iOwner > 0 && iOwner <= MaxClients)
// 	{
// 		int weapon = GetEntPropEnt(iOwner, Prop_Data, "m_hActiveWeapon");
// 		if(IsValidEdict(weapon))
// 		{
// 			float flPower = 15.0;
// 			if(flPower > 0.0)
// 			{
// 				g_iLauncher[entity] = weapon;
// 				g_bHomingEnabled[entity] = false;
// 				g_flHomingAccuracy[entity] = flPower;
// 				g_iLatestProjectile[weapon] = entity;
// 			}
// 			float flLifetime = 15.0;
// 			if(flLifetime > 0.0)
// 			{
// 				g_KillTimer[entity] = CreateTimer(flLifetime, Timer_ExplodeProjectile, entity);
// 			}
// 		}
	
// 	}
// }
// public Action Timer_ExplodeProjectile(Handle timer, any rocket)
// {
// 	g_KillTimer[rocket] = INVALID_HANDLE;
// 	if(IsValidEdict(rocket))
// 	{
// 		char classname[256];
// 		GetEdictClassname(rocket, classname, sizeof(classname));

// 		if(StrContains(classname, "tf_projectile_") != -1)
// 		{
// 			AcceptEntityInput(rocket, "Kill");
// 		}
// 	}
// }