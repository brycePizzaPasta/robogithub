#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <berobot_constants>
#include <berobot>
#include <sdkhooks>

#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Nuker"
#define ROBOT_ROLE "Damage"
#define ROBOT_DESCRIPTION "Nuke Shot"

#define GDEKNIGHT		"models/bots/demo_boss/bot_demo_boss.mdl"
#define SPAWN	"#mvm/giant_heavy/giant_heavy_entrance.wav"
#define DEATH	"mvm/sentrybuster/mvm_sentrybuster_explode.wav"
#define LOOP	"mvm/giant_demoman/giant_demoman_loop.wav"

public Plugin:myinfo =
{
	name = "[TF2] Be the Giant Major Bomber lite",
	author = "Erofix using the code from: Pelipoika, PC Gamer, Jaster and StormishJustice",
	description = "Play as the Giant Demoman",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}

public OnPluginStart()
{
    LoadTranslations("common.phrases");

    RobotDefinition robot;
    robot.name = ROBOT_NAME;
    robot.role = ROBOT_ROLE;
    robot.class = "Demoman";
    robot.shortDescription = ROBOT_DESCRIPTION;
    robot.sounds.spawn = SPAWN;
    robot.sounds.loop = LOOP;
    robot.sounds.death = DEATH;
	    RestrictionsDefinition restrictions = new RestrictionsDefinition();
    // restrictions.TimeLeft = new TimeLeftRestrictionDefinition();
    // restrictions.TimeLeft.SecondsBeforeEndOfRound = 300;
    restrictions.RobotCoins = new RobotCoinRestrictionDefinition();
    restrictions.RobotCoins.Overall = 2;


    AddRobot(robot, MakeSolar, PLUGIN_VERSION, restrictions);

}

public void OnPluginEnd()
{
	RemoveRobot(ROBOT_NAME);
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	//	CreateNative("BeGiantDemoKnight_MakeSolar", Native_SetGiantDemoKnight);
	//	CreateNative("BeGiantDemoKnight_IsGiantDemoKnight", Native_IsGiantDemoKnight);
	return APLRes_Success;
}

public OnMapStart()
{
	PrecacheModel(GDEKNIGHT);
	PrecacheSound(SPAWN);
	PrecacheSound(DEATH);
	PrecacheSound(LOOP);


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

MakeSolar(client)
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

	int iHealth = 3000;
	
	
	int MaxHealth = 175;
//	PrintToChatAll("MaxHealth %i", MaxHealth);
	
	int iAdditiveHP = iHealth - MaxHealth;
	
	TF2_SetHealth(client, iHealth);
//	 PrintToChatAll("iHealth %i", iHealth);
	
	// PrintToChatAll("iAdditiveHP %i", iAdditiveHP);
	
	

	SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.75);
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", true);
	TF2Attrib_SetByName(client, "health from packs decreased", 0.0);
	TF2Attrib_SetByName(client, "max health additive bonus", float(iAdditiveHP));
	TF2Attrib_SetByName(client, "damage force reduction", 0.5);
	TF2Attrib_SetByName(client, "move speed penalty", 0.5);
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 1.3);
	TF2Attrib_SetByName(client, "cancel falling damage", 1.0);
	TF2Attrib_SetByName(client, "patient overheal penalty", 0.15);
	TF2Attrib_SetByName(client, "mult_patient_overheal_penalty_active", 0.0);
	TF2Attrib_SetByName(client, "override footstep sound set", 4.0);
	
	TF2Attrib_SetByName(client, "charge impact damage increased", 1.5);
	TF2Attrib_SetByName(client, "ammo regen", 100.0);
	TF2Attrib_SetByName(client, "rage giving scale", 0.85);
	//TF2Attrib_SetByName(client, "increased jump height", 0.3);
	
	UpdatePlayerHitbox(client, 1.75);

	TF2_RemoveCondition(client, TFCond_CritOnFirstBlood);
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);
	
	PrintHintText(client, "You can only fire after the smoke has settled!\nUse the stickybomb in the mean time");
	PrintToChat(client, "1. You are now Giant Nuker !");
}

stock TF2_SetHealth(client, NewHealth)
{
	SetEntProp(client, Prop_Send, "m_iHealth", NewHealth, 1);
	SetEntProp(client, Prop_Data, "m_iHealth", NewHealth, 1);
}

public Action:Timer_Switch(Handle:timer, any:client)
{
	if (IsValidClient(client))
	GiveGiantDemoKnight(client);
}

#define TheFragProofFragger 30034

stock GiveGiantDemoKnight(client)
{
	if (IsValidClient(client))
	{
		RoboRemoveAllWearables(client);

		TF2_RemoveWeaponSlot(client, 0);
		TF2_RemoveWeaponSlot(client, 1);
		TF2_RemoveWeaponSlot(client, 2);


		CreateRoboWeapon(client, "tf_weapon_cannon", 996, 6, 1, 0, 0);
		CreateRoboWeapon(client, "tf_weapon_pipebomblauncher", 19, 6, 1, 1, 0);
		CreateRoboWeapon(client, "tf_weapon_bottle", 609, 6, 1, 2, 0);

		CreateRoboHat(client, TheFragProofFragger, 10, 6, 0.0, 0.75, -1.0); 


		int Weapon1 = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
		int Weapon2 = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
		int Weapon3 = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);

		if(IsValidEntity(Weapon1))
		{
			TF2Attrib_RemoveAll(Weapon1);
			
			TF2Attrib_SetByName(Weapon1, "damage bonus", 4.0);
			TF2Attrib_SetByName(Weapon1, "grenade launcher mortar mode", 0.0);
			TF2Attrib_SetByName(Weapon1, "damage causes airblast", 1.0);
			TF2Attrib_SetByName(Weapon1, "blast radius increased", 2.25);
			TF2Attrib_SetByName(Weapon1, "use large smoke explosion", 1.0);
			TF2Attrib_SetByName(Weapon1, "fire rate penalty", 20.0);
			TF2Attrib_SetByName(Weapon1, "reload time increased", 0.1);
			TF2Attrib_SetByName(Weapon1, "projectile speed decreased", 2.0);
			TF2Attrib_SetByName(Weapon1, "maxammo primary increased", 2.5);
			TF2Attrib_SetByName(Weapon1, "killstreak tier", 1.0);
			

			
			
		}
		
		if(IsValidEntity(Weapon2))
		{

			TF2Attrib_SetByName(Weapon2, "damage bonus", 0.9);
			TF2Attrib_SetByName(Weapon2, "blast radius increased", 1.25);
			TF2Attrib_SetByName(Weapon2, "override projectile type", 3.0);
			TF2Attrib_SetByName(Weapon2, "fire rate penalty", 2.2);
			TF2Attrib_SetByName(Weapon2, "reload time increased", 0.8);
			TF2Attrib_SetByName(Weapon2, "killstreak tier", 1.0);
			TF2Attrib_SetByName(Weapon2, "projectile spread angle penalty", 2.5);
			
			
		}

				if(IsValidEntity(Weapon3))
		{
			
			TF2Attrib_SetByName(Weapon3, "damage bonus", 1.25);
			TF2Attrib_SetByName(Weapon3, "killstreak tier", 1.0);
			TF2Attrib_SetByName(Weapon3, "minicritboost on kill", 10.0);
			
			
			
		}
		
	}
}

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
		SetEntPropFloat(iEntity, Prop_Send, "m_flModelScale", 1.75);
	}
}
