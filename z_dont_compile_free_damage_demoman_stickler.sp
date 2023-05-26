#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <berobot_constants>
#include <berobot>
#include <tf_custom_attributes>
#include <sdkhooks.inc>

#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Stickler"
#define ROBOT_ROLE "Damage"
#define ROBOT_CLASS "Demoman"
#define ROBOT_SUBCLASS "Grenades"
#define ROBOT_DESCRIPTION "Rapid Stickies"
#define ROBOT_TIPS "+25%% faster firing speed\nReloads full cip at once\nLonger Sticky arm time"

#define GDEKNIGHT		"models/bots/demo_boss/bot_demo_boss.mdl"
#define SPAWN	"#mvm/giant_heavy/giant_heavy_entrance.wav"
#define DEATH	"mvm/sentrybuster/mvm_sentrybuster_explode.wav"
#define LOOP	"mvm/giant_demoman/giant_demoman_loop.wav"
// #define STICKYLAUNCHER "models/weapons/w_models/w_stickybomb_launcher.mdl"

#define LEFTFOOT        ")mvm/giant_demoman/giant_demoman_step_01.wav"
#define LEFTFOOT1       ")mvm/giant_demoman/giant_demoman_step_03.wav"
#define RIGHTFOOT       ")mvm/giant_demoman/giant_demoman_step_02.wav"
#define RIGHTFOOT1      ")mvm/giant_demoman/giant_demoman_step_04.wav"
// int modelIndex;
public Plugin:myinfo =
{
	name = "[TF2] Be the Giant Toofty",
	author = "Erofix using the code from: Pelipoika, PC Gamer, Jaster and StormishJustice",
	description = "Play as the Giant Demoknight from MvM",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}

public OnPluginStart()
{
	LoadTranslations("common.phrases");

	RobotDefinition robot;
	robot.name = ROBOT_NAME;
	robot.role = ROBOT_ROLE;
	robot.class = ROBOT_CLASS;
	robot.subclass = ROBOT_SUBCLASS;
	robot.shortDescription = ROBOT_DESCRIPTION;
	robot.sounds.spawn = SPAWN;
	robot.sounds.loop = LOOP;
	robot.sounds.death = DEATH;
	robot.deathtip = ROBOT_ON_DEATH;
	AddRobot(robot, MakeToofty, PLUGIN_VERSION);

	AddNormalSoundHook(BossMortar);
}

public Action:BossMortar(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{
	if (!IsValidClient(entity)) return Plugin_Continue;
	if (!IsRobot(entity, ROBOT_NAME)) return Plugin_Continue;

	if (strncmp(sample, "player/footsteps/", 17, false) == 0)
	{
		if (StrContains(sample, "1.wav", false) != -1)
		{
			EmitSoundToAll(LEFTFOOT, entity);
		}
		else if (StrContains(sample, "3.wav", false) != -1)
		{
			EmitSoundToAll(LEFTFOOT1, entity);
		}
		else if (StrContains(sample, "2.wav", false) != -1)
		{
			EmitSoundToAll(RIGHTFOOT, entity);
		}
		else if (StrContains(sample, "4.wav", false) != -1)
		{
			EmitSoundToAll(RIGHTFOOT1, entity);
		}
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public void OnPluginEnd()
{
	RemoveRobot(ROBOT_NAME);
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	//	CreateNative("BeGiantDemoKnight_MakeToofty", Native_SetGiantDemoKnight);
	//	CreateNative("BeGiantDemoKnight_IsGiantDemoKnight", Native_IsGiantDemoKnight);
	return APLRes_Success;
}

public OnMapStart()
{
	






	
	

	//PrecacheModel(STICKYLAUNCHER);
	// modelIndex = PrecacheModel(STICKYLAUNCHER);

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

MakeToofty(client)
{
	TF2_SetPlayerClass(client, TFClass_DemoMan);
	TF2_RegeneratePlayer(client);

	new ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	if (ragdoll > MaxClients && IsValidEntity(ragdoll)) AcceptEntityInput(ragdoll, "Kill");
	decl String:weaponname[32];
	GetClientWeapon(client, weaponname, sizeof(weaponname));
	if (strcmp(weaponname, "tf_weapon_", false) == 0)
	{
		SetEntProp(GetPlayerWeaponSlot(client, 2), Prop_Send, "m_iWeaponState", 0);
		TF2_RemoveCondition(client, TFCond_Slowed);
	}
	CreateTimer(0.0, Timer_Switch, client);
	SetModel(client, GDEKNIGHT);

	int iHealth = 3300;
	
	
	int MaxHealth = 175;
	
	int iAdditiveHP = iHealth - MaxHealth;
	
	TF2_SetHealth(client, iHealth);

	SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.75);
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", true);
	float HealthPackPickUpRate =  float(MaxHealth) / float(iHealth);
	TF2Attrib_SetByName(client, "health from packs decreased", HealthPackPickUpRate);
	TF2Attrib_SetByName(client, "max health additive bonus", float(iAdditiveHP));
	TF2Attrib_SetByName(client, "damage force reduction", 0.5);
	TF2Attrib_SetByName(client, "move speed penalty", 0.5);
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 1.3);
	TF2Attrib_SetByName(client, "patient overheal penalty", 0.15);
	
	//TF2Attrib_SetByName(client, "override footstep sound set", 4.0);
	TF2Attrib_SetByName(client, "ammo regen", 100.0);
	TF2Attrib_SetByName(client, "rage giving scale", 0.85);
	TF2Attrib_SetByName(client, "cancel falling damage", 1.0);
	//TF2Attrib_SetByName(client, "increased jump height", 0.3);
	
	UpdatePlayerHitbox(client, 1.75);

	TF2_RemoveCondition(client, TFCond_CritOnFirstBlood);
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);

	PrintHintText(client, ROBOT_TIPS);
}

stock TF2_SetHealth(client, NewHealth)
{
	SetEntProp(client, Prop_Send, "m_iHealth", NewHealth, 1);
	SetEntProp(client, Prop_Data, "m_iHealth", NewHealth, 1);
	SetEntProp(client, Prop_Data, "m_iMaxHealth", NewHealth, 1);
}

public Action:Timer_Switch(Handle:timer, any:client)
{
	if (IsValidClient(client))
	GiveGiantToofty(client);
}
#define bombbeanie 30823
stock GiveGiantToofty(client)
{
	if (IsValidClient(client))
	{
		RoboRemoveAllWearables(client);

		TF2_RemoveWeaponSlot(client, 0);
		TF2_RemoveWeaponSlot(client, 1);
		TF2_RemoveWeaponSlot(client, 2);

		
		CreateRoboWeapon(client, "tf_weapon_pipebomblauncher", 20, 8, 1, 0, 213);
		
		CreateRoboHat(client, bombbeanie, 10, 6, 0.0, 0.75, -1.0); 

		int Weapon1 = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
		if(IsValidEntity(Weapon1))
		{
			//TF2Attrib_SetByName(Weapon1, "Projectile speed increased", 1.5);
			TF2Attrib_SetByName(Weapon1, "killstreak tier", 1.0);			
			TF2Attrib_SetByName(Weapon1, "fire rate bonus", 0.25);
			TF2Attrib_SetByName(Weapon1, "Reload time increased", 2.5);
			TF2Attrib_SetByName(Weapon1, "Blast radius increased", 1.75);
			TF2Attrib_SetByName(Weapon1, "sticky arm time penalty", 0.65);
			TF2CustAttr_SetString(Weapon1, "reload full clip at once", "1.0");

			// TF2CustAttr_SetString(Weapon1, "shake on step", "amplitude=2.5 frequency=1.0 range=400.0");
			
			//TF2CustAttr_SetString(Weapon1, "weaponmodel override", STICKYLAUNCHER);

			//SetEntProp(m_nModelIndexOverrides
			//SetEntProp(Weapon1, Prop_Send, "m_nModelIndexOverrides", STICKYLAUNCHER);
			 

			// SetEntProp(Weapon1, Prop_Send, "m_nModelIndex", modelIndex);
			// SetEntProp(Weapon1, Prop_Send, "m_nModelIndexOverrides", modelIndex, _, 0);
			// SetEntProp(Weapon1, Prop_Send, "m_nModelIndexOverrides", modelIndex, _, 1);
			// SetEntProp(Weapon1, Prop_Send, "m_nModelIndexOverrides", modelIndex, _, 2);
			// SetEntProp(Weapon1, Prop_Send, "m_nModelIndexOverrides", modelIndex, _, 3);

			//SetEntityModel(Weapon1, "models/weapons/w_models/w_stickybomb_launcher.mdl");
		//	SetModel(Weapon1, STICKYLAUNCHER);
			//RequestFrame(SetCustomModel, Weapon1);
		}

	}
}

// void SetCustomModel (int Weapon1)
// {
// 	// TF2CustAttr_SetString(Weapon1, "weaponmodel override", "models/weapons/w_models/w_stickybomb_launcher.mdl");
	
// }

public void OnEntityCreated(int iEntity, const char[] sClassName) 
{
	if (StrContains(sClassName, "tf_projectile") == 0)
	{
		SDKHook(iEntity, SDKHook_Spawn, Hook_OnProjectileSpawn);
	}
	
}

public void Hook_OnProjectileSpawn(iEntity) {
	int iClient = GetEntPropEnt(iEntity, Prop_Data, "m_hOwnerEntity");
	if (0 < iClient && iClient <= MaxClients && IsRobot(iClient, ROBOT_NAME)) {
		RequestFrame(SetScale, iEntity);
	}
}

void SetScale(int iEntity)
{
	SetEntPropFloat(iEntity, Prop_Send, "m_flModelScale", 1.75);
}

