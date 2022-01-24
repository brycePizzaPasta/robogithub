#pragma semicolon 1
#include <sourcemod>
#include <berobot_constants>
#include <berobot>
#include <sdkhooks>

#pragma newdecls required

#include <sdktools>

enum TFBossHealthState {
	HealthState_Default = 0,
	HealthState_Healing // displays a green health bar
};

methodmap TFMonsterResource {
	property int Index {
		public get() {
			return EntRefToEntIndex(view_as<int>(this));
		}
	}
	
	property int BossHealthPercentageByte {
		public get() {
			return GetEntProp(this.Index, Prop_Send, "m_iBossHealthPercentageByte");
		}
		public set(int value) {
			value = value > 0xFF? 0xFF : value;
			value = value < 0? 0 : value;
			SetEntProp(this.Index, Prop_Send, "m_iBossHealthPercentageByte", value);
		}
	}
	
	property TFBossHealthState BossHealthState {
		public get() {
			int index = this.Index;
			return view_as<TFBossHealthState>(GetEntProp(index, Prop_Send, "m_iBossState"));
		}
		public set(TFBossHealthState value) {
			SetEntProp(this.Index, Prop_Send, "m_iBossState", value);
		}
	}
	
	/**
	 * Updates the monster resource health display to display the current health of the
	 * specified entity.
	 */
	public void LinkHealth(int entity) {
		int hEntity = EntRefToEntIndex(entity);
		
		if (IsValidEntity(hEntity)) {
			int iMaxHealth = GetEntProp(hEntity, Prop_Data, "m_iMaxHealth");
			
			// account for max unbuffed health on clients, stored in player resource entity
			if (entity > 0 && entity <= MaxClients) {
				int resource = GetPlayerResourceEntity();
				if (IsValidEntity(resource)) {
					iMaxHealth = GetEntProp(resource, Prop_Send, "m_iMaxHealth", _, entity);
				}
			}
			
			int iHealth = GetEntProp(hEntity, Prop_Data, "m_iHealth");
			
			this.BossHealthPercentageByte = RoundToCeil(float(iHealth) / iMaxHealth * 255);
		}
	}
	
	/**
	 * Returns the first monster_resource entity, with an option to create it if it doesn't
	 * exist.
	 */
	public static TFMonsterResource GetEntity(bool create = false) {
		int hMonsterResource = FindEntityByClassname(-1, "monster_resource");
		
		if (hMonsterResource == -1) {
			hMonsterResource = CreateEntityByName("monster_resource");
			
			if (hMonsterResource == -1) {
				DispatchSpawn(hMonsterResource);
			}
		}
		
		return view_as<TFMonsterResource>(EntIndexToEntRef(hMonsterResource));
	}
}


#define PLUGIN_VERSION "0.0.0"
public Plugin myinfo = {
	name = "[TF2] Assign Boss Healthbar",
	author = "nosoop",
	description = "Attempts to assign the boss healthbar to a player.",
	version = PLUGIN_VERSION,
	url = "https://github.com/nosoop/"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("SetBossHealth", Native_SetBossHealth);
	CreateNative("UnSetBossHealth", Native_UnSetBossHealth);

	return APLRes_Success;
}

int g_iBossTarget = -1;

public void OnPluginStart() {
	LoadTranslations("common.phrases");
	
	RegAdminCmd("sm_setboss", SetBossHealthTarget, ADMFLAG_ROOT);
	//RegAdminCmd("sm_setbosshud", SetBossHealth, ADMFLAG_ROOT);
//	RegServerCmd("sm_unsetbosshud", UnSetBossHealth);
	
	
	HookEvent("post_inventory_application", OnInventoryApplied);

	HookEvent("player_death", Event_Death_RemoveHUD, EventHookMode_Post);

	
}

public void OnPluginEnd() {
	TFMonsterResource resource = TFMonsterResource.GetEntity(false);
	if (IsValidEntity(resource.Index)) {
		resource.BossHealthPercentageByte = 0;
	}
}

public Action Event_Death_RemoveHUD(Event event, const char[] name, bool dontBroadcast)
{

	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	//The client was a boss and died
	if (client == g_iBossTarget) {
		SDKUnhook(g_iBossTarget, SDKHook_PostThink, OnBossPostThink);
	
	RemoveHUD();
	}

}

public void RemoveHUD(){
	g_iBossTarget = -1;
	int iEnt = MaxClients + 1;
	while ((iEnt = FindEntityByClassname(iEnt, "monster_resource")) != -1)
	{
		if (IsValidEntity(iEnt))
		{
			AcceptEntityInput(iEnt, "Kill");
			
		}
	} 

}


public void OnInventoryApplied(Event event, const char[] name, bool dontBroadcast) {
	
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (TF2_IsGameModeMvM() && client == g_iBossTarget) {
		// should be forced to regenerate on next think
		SetEntProp(client, Prop_Send, "m_bUseBossHealthBar", false);
	}

	int iTarget = client;

	if (IsAnyRobot(client) && !IsBoss(client) && client == g_iBossTarget){
		//PrintToChatAll("%N was not a ZBOSS! but is the target, removing hud and target", client);
		RemoveHUD();
	}
	
	// if (iTarget != -1 && g_iBossTarget != iTarget) {
	// 	if (IsValidEntity(g_iBossTarget)) {
	// 		SDKUnhook(g_iBossTarget, SDKHook_PostThink, OnBossPostThink);
	// 	}
	// 	g_iBossTarget = iTarget;
	// 	SDKHook(iTarget, SDKHook_PostThink, OnBossPostThink);
	// 	ReplyToCommand(client, "Switched boss target to %N", iTarget);
		
	// }

	
}

public Action SetBossHealthTarget(int client, int argc) {
	if (!argc) {
		return Plugin_Handled;
	}
	
	char target[MAX_NAME_LENGTH + 1];
	GetCmdArg(1, target, sizeof(target));
	
	int iTarget = FindTarget(client, target, false, false);
	
	if (iTarget != -1 && g_iBossTarget != iTarget) {
		if (IsValidEntity(g_iBossTarget)) {
			SDKUnhook(g_iBossTarget, SDKHook_PostThink, OnBossPostThink);
		}
		g_iBossTarget = iTarget;
		SDKHook(iTarget, SDKHook_PostThink, OnBossPostThink);
	//	ReplyToCommand(client, "Switched boss target to %N", iTarget);
	} else {
		g_iBossTarget = -1;
	//	ReplyToCommand(client, "Removed boss target");
		
	}
	
	return Plugin_Handled;
}


public any Native_SetBossHealth(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);

	int iTarget = client;
	
	if (iTarget != -1 && g_iBossTarget != iTarget) {
		if (IsValidEntity(g_iBossTarget)) {
			SDKUnhook(g_iBossTarget, SDKHook_PostThink, OnBossPostThink);
		}
		g_iBossTarget = iTarget;
		SDKHook(iTarget, SDKHook_PostThink, OnBossPostThink);
		//ReplyToCommand(client, "Switched boss target to %N", iTarget);
	}
	
	return Plugin_Handled;
}

// public Action SetBossHealth(int client) {

// 	int iTarget = client;
	
// 	if (iTarget != -1 && g_iBossTarget != iTarget) {
// 		if (IsValidEntity(g_iBossTarget)) {
// 			SDKUnhook(g_iBossTarget, SDKHook_PostThink, OnBossPostThink);
// 		}
// 		g_iBossTarget = iTarget;
// 		SDKHook(iTarget, SDKHook_PostThink, OnBossPostThink);
// 		ReplyToCommand(client, "Switched boss target to %N", iTarget);
// 	}
	
// 	return Plugin_Handled;
// }

public any Native_UnSetBossHealth(Handle plugin, int numParams) {

	for(int i = 0; i <= MAXPLAYERS; i++)
    {
		if (i == g_iBossTarget) {
			SDKUnhook(g_iBossTarget, SDKHook_PostThink, OnBossPostThink);
    	}
	}
	

	RemoveHUD();
	
	
	return Plugin_Handled;
}





public void OnBossPostThink(int client) {
	if (client != g_iBossTarget) {
		SDKUnhook(client, SDKHook_PostThink, OnBossPostThink);
	} else {
		if (!TF2_IsGameModeMvM()) {
			// non-MvM, use monster resource health bar
			if (IsPlayerAlive(client)) {
				TFMonsterResource.GetEntity(true).LinkHealth(client);
			} else {
				TFMonsterResource.GetEntity(true).BossHealthPercentageByte = 0;
			}
		} else if (!GetEntProp(client, Prop_Send, "m_bUseBossHealthBar")) {
			// MvM, display boss health bar if it isn't already
			SetEntProp(client, Prop_Send, "m_bUseBossHealthBar", true);
		}
	}

	if (g_iBossTarget == -1){

		//PrintToChatAll("REMOVE HUD");

		int iEnt = MaxClients + 1;
		while ((iEnt = FindEntityByClassname(iEnt, "monster_resource")) != -1)
		{
			if (IsValidEntity(iEnt))
			{
				AcceptEntityInput(iEnt, "Kill");
				
			}
		} 
	}
}

public void OnClientDisconnect(int client) {
	if (client == g_iBossTarget) {
		SDKUnhook(g_iBossTarget, SDKHook_PostThink, OnBossPostThink);
		g_iBossTarget = -1;
	}
}

// Powerlord's MvM stock
stock bool TF2_IsGameModeMvM() {
	return GameRules_GetProp("m_bPlayingMannVsMachine")? true : false;
}