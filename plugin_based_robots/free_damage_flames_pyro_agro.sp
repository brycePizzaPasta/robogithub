#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <sm_logger>
#include <berobot_constants>
#include <berobot>

#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Agro"
#define ROBOT_ROLE "Damage"
#define ROBOT_CLASS "Pyro"
#define ROBOT_SUBCLASS "Flames"
#define ROBOT_DESCRIPTION "Degreaser, Scorch shot, Maul"
#define ROBOT_TIPS "You have 3 weapons\nScorch shot homes in on burning players\nHeal 200 on extinguish"
#define ROBOT_ON_DEATH "Agro's Scorch Shot homes in on burning players"

#define GPYRO		"models/bots/pyro_boss/bot_pyro_boss.mdl"
#define SPAWN	"#mvm/giant_heavy/giant_heavy_entrance.wav"
#define DEATH	"mvm/sentrybuster/mvm_sentrybuster_explode.wav"
#define LOOP	"mvm/giant_pyro/giant_pyro_loop.wav"

#define SOUND_GUNFIRE	")mvm/giant_pyro/giant_pyro_flamethrower_loop.wav"
#define SOUND_WINDUP	")mvm/giant_pyro/giant_pyro_flamethrower_start.wav"

#define LOFILONGWAVE 470
#define HANDSOMEDEVIL 31135
#define PHOBOS 30652


public Plugin:myinfo = 
{
	name = "[TF2] Be the Giant Agro Pyro",
	author = "Erofix using the code from: Pelipoika, PC Gamer, Jaster and StormishJustice",
	description = "Play as the Giant Agro Pyro from Kritzkast",
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

// new bool:Locked1[MAXPLAYERS+1];
// new bool:Locked2[MAXPLAYERS+1];
// new bool:Locked3[MAXPLAYERS+1];
// new bool:CanWindDown[MAXPLAYERS+1];

public OnPluginStart()
{
	SMLoggerInit(LOG_TAGS, sizeof(LOG_TAGS), SML_ERROR, SML_FILE);

	LoadTranslations("common.phrases");

	RobotDefinition robot;
	robot.name = ROBOT_NAME;
	robot.role = ROBOT_ROLE;
	robot.class = ROBOT_CLASS;
	robot.subclass = ROBOT_SUBCLASS;
	robot.shortDescription = ROBOT_DESCRIPTION;
	robot.sounds.spawn = SPAWN;
	robot.sounds.loop = LOOP;
	robot.sounds.gunfire = SOUND_GUNFIRE;
	robot.sounds.windup = SOUND_WINDUP;
	robot.sounds.death = DEATH;
	robot.deathtip = ROBOT_ON_DEATH;
	robot.footstep = ROBOT_FOOTSTEP_GIANTCOMMON;
	robot.difficulty = ROBOT_DIFFICULTY_EASY;
	// robot.weaponsound = ROBOT_WEAPON_SOUND_FLAMETHROWER;

	AddRobot(robot, MakeGiantPyro, PLUGIN_VERSION);
}

public void OnPluginEnd()
{
	RemoveRobot(ROBOT_NAME);
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
//	CreateNative("BeGiantPyro_MakeGiantPyro", Native_SetGiantPyro);
//	CreateNative("BeGiantPyro_IsGiantPyro", Native_IsGiantPyro);
	return APLRes_Success;
}

public OnMapStart()
{
//



	
	// PrecacheSound(SOUND_GUNFIRE);
	// PrecacheSound(SOUND_WINDUP);
	
}

public Action:SetModel(client, const String:model[])
{
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		SetVariantString(model);
		AcceptEntityInput(client, "SetCustomModel");

		SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
	}
}

MakeGiantPyro(client)
{
	SMLogTag(SML_VERBOSE, "Createing Agro");
	TF2_SetPlayerClass(client, TFClass_Pyro);
	//TF2_RespawnPlayer(client);
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
	SetModel(client, GPYRO);
	
	RoboSetHealth(client,TFClass_Pyro, 3000, 1.5);

	// PrintToChatAll("iHealth %i", iHealth);
	
	// PrintToChatAll("iAdditiveHP %i", iAdditiveHP);
	
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.75);
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", true);
	TF2Attrib_SetByName(client, "ammo regen", 100.0);
	TF2Attrib_SetByName(client, "move speed penalty", 0.65);
	TF2Attrib_SetByName(client, "damage force reduction", 0.5);
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.8);

	TF2Attrib_SetByName(client, "cancel falling damage", 1.0);
	
	// TF2Attrib_SetByName(client, "override footstep sound set", 6.0);
	
	TF2Attrib_SetByName(client, "rage giving scale", 0.85);
	TF2Attrib_SetByName(client, "head scale", 0.75);

	
	
	UpdatePlayerHitbox(client, 1.75);
	
	TF2_RemoveCondition(client, TFCond_CritOnFirstBlood);
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);
	
	
	PrintHintText(client , ROBOT_TIPS);
	
	
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
		RoboRemoveAllWearables(client);
		TF2_RemoveWeaponSlot(client, 0);
		TF2_RemoveWeaponSlot(client, 1);
		TF2_RemoveWeaponSlot(client, 2);
		
		CreateRoboWeapon(client, "tf_weapon_flamethrower", 215, 6, 1, 2, 0);	
		CreateRoboWeapon(client, "tf_weapon_flaregun", 740, 6, 1, 2, 0);
		CreateRoboWeapon(client, "tf_weapon_fireaxe", 466, 6, 1, 2, 0);
		
		TFTeam iTeam = view_as<TFTeam>(GetEntProp(client, Prop_Send, "m_iTeamNum"));
		
		float TeamPaint = 0.0;

		if (iTeam == TFTeam_Blue){
			TeamPaint = 12807213.0;
		}
		if (iTeam == TFTeam_Red){
			TeamPaint = 12091445.0;
		}

		CreateRoboHat(client, LOFILONGWAVE, 10, 6, TeamPaint, 1.0, -1.0);
		CreateRoboHat(client, HANDSOMEDEVIL, 10, 6, TeamPaint, 0.75, -1.0);
		CreateRoboHat(client, PHOBOS, 10, 6, 0.0, 0.75, -1.0);

		int Weapon1 = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
		int Weapon2 = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
		int Weapon3 = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
		
		if(IsValidEntity(Weapon1))
		{
			//TF2Attrib_RemoveAll(Weapon1);
			TF2Attrib_SetByName(Weapon1, "dmg penalty vs players", 1.25);
			TF2Attrib_SetByName(Weapon1, "maxammo primary increased", 2.5);
			TF2Attrib_SetByName(Weapon1, "killstreak tier", 1.0);			
			// TF2Attrib_SetByName(Weapon1, "airblast pushback scale", 0.6);		
			TF2Attrib_SetByName(Weapon1, "dmg penalty vs buildings", 0.8);			
			TF2Attrib_SetByName(Weapon1, "flame_spread_degree", 5.0);			
			TF2Attrib_SetByName(Weapon1, "flame size bonus", 1.6);
			TF2Attrib_SetByName(Weapon1, "flame_speed", 3600.0);
			TF2Attrib_SetByName(Weapon1, "attach particle effect", 4.0);
			TF2Attrib_SetByName(Weapon1, "single wep deploy time decreased", 0.4);
			TF2Attrib_SetByName(Weapon1, "switch from wep deploy time decreased", 0.7);
			TF2Attrib_SetByName(Weapon1, "extinguish restores health", 200.0);
			
			TF2Attrib_SetByName(Weapon1, "weapon burn dmg reduced", 1.0);

		}
		
		if(IsValidEntity(Weapon2))
		{
			TF2Attrib_RemoveAll(Weapon2);
			//TF2Attrib_SetByName(Weapon2, "dmg penalty vs players", 0.5);
			TF2Attrib_SetByName(Weapon2, "Projectile speed decreased", 0.6);
			TF2Attrib_SetByName(Weapon2, "damage causes airblast", 1.0);
			TF2Attrib_SetByName(Weapon2, "mod projectile heat seek power", 3600.0);
			//TF2Attrib_SetByName(Weapon2, "apply look velocity on damage", 1500.0);
		}

		if(IsValidEntity(Weapon3))
		{
			//TF2Attrib_RemoveAll(Weapon3);
			TF2Attrib_SetByName(Weapon3, "dmg bonus vs buildings", 3.25);
			TF2Attrib_SetByName(Weapon3, "melee range multiplier", 1.4);
			TF2Attrib_SetByName(Weapon3, "fire rate penalty", 1.2);
			
			//TF2Attrib_SetByName(Weapon2, "apply look velocity on damage", 1500.0);
		}
	}
}

// public Action:OnPlayerRunCmd(iClient, &iButtons, &iImpulse, Float:fVel[3], Float:fAng[3], &iWeapon) 
// {
// 	if (IsValidClient(iClient) && IsRobot(iClient, ROBOT_NAME) && IsPlayerAlive(iClient)) 
// 	{	
// 		//add a check to prevent errors related to switching classes
		
 
// 		new weapon = GetPlayerWeaponSlot(iClient, TFWeaponSlot_Primary);
// 		iWeapon = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");

// 		if(IsValidEntity(weapon) && iWeapon == 215)//215 == flamethrower
// 		{
// 			new iWeaponState = GetEntProp(weapon, Prop_Send, "m_iWeaponState");
// 			if (iWeaponState == 1 && !Locked1[iClient])
// 			{
// 				EmitSoundToAll(SOUND_WINDUP, iClient);
// 			//	PrintToChatAll("WeaponState = Windup");
				
// 				Locked1[iClient] = true;
// 				Locked2[iClient] = false;
// 				Locked3[iClient] = false;
// 				CanWindDown[iClient] = true;
				
// 				StopSound(iClient, SNDCHAN_AUTO, SOUND_GUNFIRE);
// 			}
// 			else if (iWeaponState == 2 && !Locked2[iClient])
// 			{
// 				EmitSoundToAll(SOUND_GUNFIRE, iClient);
// 			//	PrintToChatAll("WeaponState = Firing");
				
// 				Locked2[iClient] = true;
// 				Locked1[iClient] = true;
// 				Locked3[iClient] = false;
// 				CanWindDown[iClient] = true;
				
// 				StopSound(iClient, SNDCHAN_AUTO, SOUND_WINDUP);
// 			}
// 			else if (iWeaponState == 3 && !Locked3[iClient])
// 			{

// 			//	PrintToChatAll("WeaponState = Spun Up");
				
// 				Locked3[iClient] = true;
// 				Locked1[iClient] = true;
// 				Locked2[iClient] = false;
// 				CanWindDown[iClient] = true;
				
// 				StopSound(iClient, SNDCHAN_AUTO, SOUND_GUNFIRE);
// 				StopSound(iClient, SNDCHAN_AUTO, SOUND_WINDUP);
// 			}
// 			else if (iWeaponState == 0)
// 			{
// 				if (CanWindDown[iClient])
// 				{
// 			//		PrintToChatAll("WeaponState = WindDown");

// 					CanWindDown[iClient] = false;
// 				}
				
// 				StopSound(iClient, SNDCHAN_AUTO, SOUND_GUNFIRE);
				
// 				Locked1[iClient] = false;
// 				Locked2[iClient] = false;
// 				Locked3[iClient] = false;
// 			}
// 		}
// 	}
// 	return Plugin_Continue;
// }
