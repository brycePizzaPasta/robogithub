#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <berobot_constants>
#include <berobot>
#include <sdkhooks>
#include <tf_custom_attributes>

#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Demopan"
#define ROBOT_ROLE "ZBOSS"
#define ROBOT_DESCRIPTION "Crit Pan"
#define ROBOT_CLASS "Demoman"
#define ROBOT_SUBCLASS "Melee"
#define ROBOT_TIPS "Hit Enemies with your Pan\nYou can't cap or block captures"

#define GDEKNIGHT		"models/bots/demo_boss/bot_demo_boss.mdl"
#define SPAWN   "mvm/ambient_mp3/mvm_siren.mp3"
#define DEATH	"mvm/mvm_tank_explode.wav"
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
	restrictions.TeamCoins = new RobotCoinRestrictionDefinition();
	restrictions.TeamCoins.Overall = 2;

	restrictions.RobotCoins = new RobotCoinRestrictionDefinition();
	restrictions.RobotCoins.PerRobot = 2.0;

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

	float scale = 1.75;	
	int iHealth = 7500;
	
	
	int MaxHealth = 175;
//	PrintToChatAll("MaxHealth %i", MaxHealth);
	
	int iAdditiveHP = iHealth - MaxHealth;
	
	TF2_SetHealth(client, iHealth);
//	 PrintToChatAll("iHealth %i", iHealth);
	
	// PrintToChatAll("iAdditiveHP %i", iAdditiveHP);
	
	

	SetEntPropFloat(client, Prop_Send, "m_flModelScale", scale);
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", true);
	float HealthPackPickUpRate =  float(MaxHealth) / float(iHealth);
	TF2Attrib_SetByName(client, "health from packs decreased", HealthPackPickUpRate);
	TF2Attrib_SetByName(client, "max health additive bonus", float(iAdditiveHP));
	TF2Attrib_SetByName(client, "damage force reduction", 0.5);
	TF2Attrib_SetByName(client, "move speed penalty", 0.85);
	TF2Attrib_SetByName(client, "cancel falling damage", 1.0);
	TF2Attrib_SetByName(client, "patient overheal penalty", 0.15);
	
	TF2Attrib_SetByName(client, "override footstep sound set", 4.0);
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.4);
	//TF2Attrib_SetByName(client, "charge impact damage increased", 1.5);
	TF2Attrib_SetByName(client, "ammo regen", 100.0);
	TF2Attrib_SetByName(client, "rage giving scale", 0.85);
	TF2Attrib_SetByName(client, "hand scale", 1.15);

	TF2Attrib_SetByName(client, "increase player capture value", -1.0);
	TF2Attrib_SetByName(client, "cannot pick up intelligence", 1.0);
	
	TF2Attrib_SetByName(client, "healing received penalty", 0.0);
	
	UpdatePlayerHitbox(client, scale);

	TF2_RemoveCondition(client, TFCond_CritOnFirstBlood);
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);
	TF2_AddCondition(client, TFCond_CritCanteen);
	
	PrintHintText(client, ROBOT_TIPS);

	//SetBossHealth(client);
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
	GiveGiantDemoKnight(client);
}

#define BountyHat 332
#define Dangeresque 295
stock GiveGiantDemoKnight(client)
{
	if (IsValidClient(client))
	{
	RoboRemoveAllWearables(client);

	TF2_RemoveWeaponSlot(client, 0);
	TF2_RemoveWeaponSlot(client, 1);
	TF2_RemoveWeaponSlot(client, 2);


	//CreateRoboWeapon(client, "tf_weapon_cannon", 996, 6, 1, 0, 0);
	// CreateRoboWeapon(client, "tf_weapon_pipebomblauncher", 19, 6, 1, 1, 0);
	CreateRoboWeapon(client, "tf_weapon_bottle", 264, 6, 1, 2, 0);

	CreateRoboWeapon(client, "tf_wearable_demoshield", 131, 6, 1, 1, 0);


	CreateRoboHat(client, BountyHat, 10, 6, 0.0, 0.75, -1.0); 
	CreateRoboHat(client, Dangeresque, 10, 6, 0.0, 0.85, -1.0); 


	int Weapon3 = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);

	if(IsValidEntity(Weapon3))
	{
	// TF2Attrib_SetByName(Weapon3, "dmg penalty vs players", 1.25);
	TF2Attrib_SetByName(Weapon3, "mod weapon blocks healing", 1.0);
	TF2Attrib_SetByName(Weapon3, "dmg penalty vs buildings", 0.25);
	TF2Attrib_SetByName(Weapon3, "killstreak tier", 1.0);
	}

	int iEntity2 = -1;
	while ((iEntity2 = FindEntityByClassname(iEntity2, "tf_wearable_demoshield")) != -1)
	{
	if (client == GetEntPropEnt(iEntity2, Prop_Data, "m_hOwnerEntity"))
	{				
		//PrintToChatAll("going through entity");
		TF2Attrib_SetByName(iEntity2, "major increased jump height", 1.125);		
		TF2Attrib_SetByName(iEntity2, "lose demo charge on damage when charging", 0.0);		
		TF2Attrib_SetByName(iEntity2, "charge recharge rate increased", 4.0);		
		TF2Attrib_SetByName(iEntity2, "charge impact damage increased", 2.0);		
		TF2Attrib_SetByName(iEntity2, "no charge impact range", 1.0);	
		TF2Attrib_SetByName(iEntity2, "mult charge turn control", 1000.0);	
		TF2Attrib_SetByName(iEntity2, "dmg taken from blast reduced", 1.0);	
		TF2Attrib_SetByName(iEntity2, "dmg taken from fire reduced", 1.0);	
		// TF2Attrib_SetByName(iEntity2, "SET BONUS: dmg from sentry reduced", 0.3);	

		
		
		break;
	}
	}	
	}
}

public void TF2_OnConditionAdded(int client, TFCond condition)
{
	
	//PrintToChatAll("CONDITION WAS: %i for %N", condition, client);
		if (IsRobot(client, ROBOT_NAME) && condition == TFCond_Charging)
		{	
			SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 750.0);

		}
	
}


// public void TF2_OnConditionRemoved(int client, TFCond condition)
// {
// 	//PrintToChatAll("CONDITION REMOVED!");
// 	if (IsRobot(client, ROBOT_NAME)){

	
//     if(condition == TFCond_RuneHaste){

// 		TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);

// 	}
// 	// TF2_RemoveCondition(client, TFCond_Dazed);
// 	// TF2_RemoveCondition(client, TFCond_KnockedIntoAir);
// 	// PrintToChatAll("Condition was: %i", condition);
//    }

// }