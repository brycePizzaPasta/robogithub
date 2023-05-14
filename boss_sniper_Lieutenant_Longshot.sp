#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
// #include <sdkhooks>
#include <berobot_constants>
#include <berobot>
//#include <sendproxy>
#include <tf_custom_attributes>

#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Lieutenant Longshot"
#define ROBOT_ROLE "ZBOSS"
#define ROBOT_CLASS "Sniper"
#define ROBOT_SUBCLASS "Hitscan"
#define ROBOT_DESCRIPTION "High Damage Rifle"
#define ROBOT_TIPS "Land headshots for head bonus & more damage\nYou can move while scoped\nNo blast jumps & long reload"

#define ChangeDane             "models/bots/Sniper/bot_Sniper.mdl"
#define SPAWN   "mvm/ambient_mp3/mvm_siren.mp3"
#define DEATH   "mvm/mvm_tank_explode.wav"
#define LOOP    "mvm/giant_heavy/giant_heavy_loop.wav"


public Plugin:myinfo =
{
	name = "[TF2] Be Big Robot Jbird",
	author = "Erofix using the code from: Pelipoika, PC Gamer, Jaster and StormishJustice",
	description = "Play as the Giant Jbird",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}

public OnPluginStart()
{
	LoadTranslations("common.phrases");

	//HookEvent("player_death", Event_Death, EventHookMode_Post);

	RobotDefinition robot;
	robot.name = ROBOT_NAME;
	robot.role = ROBOT_ROLE;
	robot.class = ROBOT_CLASS;
	robot.subclass = ROBOT_SUBCLASS;
	robot.shortDescription = ROBOT_DESCRIPTION;
	robot.sounds.spawn = SPAWN;
	robot.sounds.loop = LOOP;
	robot.sounds.death = DEATH;
	RestrictionsDefinition restrictions = new RestrictionsDefinition();
	// restrictions.TimeLeft = new TimeLeftRestrictionDefinition();
	// restrictions.TimeLeft.SecondsBeforeEndOfRound = 300;
	restrictions.TeamCoins = new RobotCoinRestrictionDefinition();
	restrictions.TeamCoins.Overall = 1;
	
	restrictions.RobotCoins = new RobotCoinRestrictionDefinition();
	restrictions.RobotCoins.PerRobot = 4.0;
	
	AddRobot(robot, MakeSniper, PLUGIN_VERSION, restrictions);
}

public void OnPluginEnd()
{
	RemoveRobot(ROBOT_NAME);
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	//	CreateNative("BeSuperHeavyweightChamp_MakeSniper", Native_SetSuperHeavyweightChamp);
	//	CreateNative("BeSuperHeavyweightChamp_IsSuperHeavyweightChamp", Native_IsSuperHeavyweightChamp);
	return APLRes_Success;
}

public OnMapStart()
{
	// PrecacheModel(ChangeDane);




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

MakeSniper(client)
{

	TF2_SetPlayerClass(client, TFClass_Sniper);
	TF2_RegeneratePlayer(client);

	new ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	if (ragdoll > MaxClients && IsValidEntity(ragdoll)) AcceptEntityInput(ragdoll, "Kill");
	decl String:weaponname[32];
	GetClientWeapon(client, weaponname, sizeof(weaponname));
	if (strcmp(weaponname, "tf_weapon_", false) == 2)
	{
		SetEntProp(GetPlayerWeaponSlot(client, 2), Prop_Send, "m_iWeaponState", 2);
		TF2_RemoveCondition(client, TFCond_Slowed);
	}
	CreateTimer(0.0, Timer_Switch, client);
	SetModel(client, ChangeDane);


	int iHealth = 4500;
	int MaxHealth = 125;
	int iAdditiveHP = iHealth - MaxHealth;

	TF2_SetHealth(client, iHealth);

	SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.75);
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", _:true);

	TF2Attrib_SetByName(client, "move speed penalty", 0.67);
	TF2Attrib_SetByName(client, "damage force reduction", 1.0);
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 1.0);
	float HealthPackPickUpRate =  float(MaxHealth) / float(iHealth);
	TF2Attrib_SetByName(client, "health from packs decreased", HealthPackPickUpRate);
	TF2Attrib_SetByName(client, "max health additive bonus", float(iAdditiveHP));
	TF2Attrib_SetByName(client, "cancel falling damage", 1.0);
	TF2Attrib_SetByName(client, "patient overheal penalty", 0.15);

	TF2Attrib_SetByName(client, "override footstep sound set", 2.0);
	TF2Attrib_SetByName(client, "ammo regen", 100.0);
	TF2Attrib_SetByName(client, "major increased jump height", 1.25);
	TF2Attrib_SetByName(client, "head scale", 0.75);
	TF2Attrib_SetByName(client, "rage giving scale", 0.85);
	TF2Attrib_SetByName(client, "hand scale", 1.5);
	TF2Attrib_SetByName(client, "increase player capture value", -1.0);
	TF2Attrib_SetByName(client, "cannot pick up intelligence", 1.0);
	TF2Attrib_SetByName(client, "healing received penalty", 0.0);
	// TF2Attrib_SetByName(client, "health regen", 10.0);

	UpdatePlayerHitbox(client, 1.75);

	TF2_RemoveCondition(client, TFCond_CritOnFirstBlood);
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);
	TF2_AddCondition(client, TFCond_CritCanteen);

	PrintHintText(client , ROBOT_TIPS);

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
	GiveBigRoboJbird(client);
}


#define Peak 30743
#define Regalia 30895
// #define Veil 393

stock GiveBigRoboJbird(client)
{
	if (IsValidClient(client))
	{
		
	RoboRemoveAllWearables(client);

	TF2_RemoveWeaponSlot(client, 0); //SniperRifle
	TF2_RemoveWeaponSlot(client, 1); //Smg
	TF2_RemoveWeaponSlot(client, 2); // kukri

	CreateRoboWeapon(client, "tf_weapon_sniperrifle", 402, 6, 1, 0, 0);
	//CreateRoboWeapon(client, "tf_weapon_smg", 16, 6, 1, 1, 0);
	// CreateRoboWeapon(client, "tf_weapon_club", 401, 6, 1, 2, 0); //shahansah


	CreateRoboHat(client, Peak, 10, 6, 0.0, 1.0, -1.0); 
	CreateRoboHat(client, Regalia, 10, 6, 0.0, 1.0, -1.0); 
	


		
	int SniperRifle = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary); //SniperRifle
	// int Kukri = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee); //Shahanshah
	// int SMG = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary); //SMG



	if(IsValidEntity(SniperRifle))
		{
			TF2Attrib_RemoveAll(SniperRifle);
			
			TF2Attrib_SetByName(SniperRifle, "killstreak tier", 1.0);
			TF2Attrib_SetByName(SniperRifle, "dmg penalty vs buildings", 0.65);
			TF2Attrib_SetByName(SniperRifle, "dmg penalty vs players", 0.666);
			TF2Attrib_SetByName(SniperRifle, "headshot damage increase", 1.5);
			TF2Attrib_SetByName(SniperRifle, "projectile penetration", 1.0);
		
			TF2Attrib_SetByName(SniperRifle, "aiming no flinch", 1.0);
			TF2Attrib_SetByName(SniperRifle, "sniper aiming movespeed decreased", 0.5);
			//TF2Attrib_SetByName(SniperRifle, "sniper charge per sec", 10.0);
			
			TF2Attrib_SetByName(SniperRifle, "sniper fires tracer", 1.0);
			//TF2Attrib_SetByName(SniperRifle, "lunchbox adds minicrits", 3.0);
			//TF2Attrib_SetByName(SniperRifle, "apply z velocity on damage", 550.0);
			TF2Attrib_SetByName(SniperRifle, "faster reload rate", 1.25);
			
			//TF2Attrib_SetByName(SniperRifle, "heal on hit for rapidfire", 25.0);
			// TF2Attrib_SetByName(SniperRifle, "headshot damage increase", 1.33);
			//TF2CustAttr_SetString(SniperRifle, "knockback modifier", "4.0");
			//TF2CustAttr_SetString(client, "Spell-Caster", "Spell=4 Cooldown=50.0");
			
			
		}

	// if(IsValidEntity(SMG))
	// 	{
	// 		TF2Attrib_RemoveAll(SMG);
	// 		TF2Attrib_SetByName(SMG, "killstreak tier", 1.0);
	// 		TF2Attrib_SetByName(SMG, "dmg penalty vs players", 1.25);
	// 		TF2Attrib_SetByName(SMG, "dmg penalty vs buildings", 0.5);
			
	// 	}
	}
}
