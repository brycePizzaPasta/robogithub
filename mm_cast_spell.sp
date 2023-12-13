#include <sourcemod>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <tf2wearables>
#include <tf2attributes>
#include <tf_ontakedamage>
#include <tf_custom_attributes>
#include <stocksoup/var_strings>

bool g_button_held[MAXPLAYERS + 1] = {false, ...};
float g_Recharge[MAXPLAYERS + 1] = {0.0, ...};
float g_RechargeCooldown = 1.0;
float g_skill;
int g_Spell[MAXPLAYERS + 1] = {0,...};
int g_stat_Charges[MAXPLAYERS + 1] = {0,...};
int g_book[MAXPLAYERS + 1] = {-1,...}
int g_player_charges[MAXPLAYERS + 1] = {0,...}
//Diefferent spell based on cond
int g_SpellOnCond;
int g_Cond;

// #define s0 "Fireball";
// #define s1 "Swarm of Bats";
// #define s2 "Overheal";
// #define s3	"Pumpkin MIRV", 
// #define s4	"Blast Jump", 
// #define s5 	"Stealth", 
// #define s6	"Shadow Leap", 
// #define s7 	"Ball O' Lightning", 
// #define s8	"Power Up", 
// #define s9	"Meteor Shower", 
// #define s10	"Summon MONOCULUS", 
// #define s11	"Skeletons Horde"

static const char Spell_String[][256] =
{
    "Fireball", 
    "Swarm of Bats", 
    "Overheal", 
    "Pumpkin MIRV", 
    "Blast Jump", 
    "Stealth", 
    "Shadow Leap", 
    "Ball O' Lightning", 
    "Power Up", 
    "Meteor Shower",
    "Summon MONOCULUS", 
    "Skeletons Horde"
};

bool HasStat(int attacker)
{
	char stat_buffer[256];
	if (!TF2CustAttr_GetString(attacker, "Spell-Caster", stat_buffer, sizeof(stat_buffer))) {
		return false;
	}
	g_Spell[attacker] = ReadIntVar(stat_buffer, "Spell", 0);
	g_RechargeCooldown = ReadFloatVar(stat_buffer, "Cooldown", 5.0);
	g_SpellOnCond = ReadIntVar(stat_buffer, "SpellOnCond", -1);
	g_Cond = ReadIntVar(stat_buffer, "Cond", -1);
	g_stat_Charges[attacker] = ReadIntVar(stat_buffer, "Charges", 1);

	if(g_Spell[attacker] == -1) return false;

	return true;
}
bool isready[MAXPLAYERS + 1] = {false,...}; 
public Action OnClientCommandKeyValues(int client, KeyValues kvCommand)
{
    char sCommand[64];
    kvCommand.GetSectionName(sCommand,sizeof(sCommand));
    if (strcmp(sCommand,"+use_action_slot_item_server") == 0)//The client pressed his action key (Default:H)
    {
		//Add some logic here to check for if the number of charges was changed
        if(HasStat(client))
		{
			if(g_book[client])
			{
				g_player_charges[client] = GetEntProp(g_book[client], Prop_Send, "m_iSpellCharges");
				PrintToChatAll("Had charges: %i",g_player_charges[client])
				if(g_player_charges[client]>0)
				{
					g_button_held[client] = true;
					g_Recharge[client] = GetEngineTime() + g_RechargeCooldown;
					isready[client] = false;
				}
			}else
			{
			PrintToChatAll("Had no charge");
			g_button_held[client] = false;
			}
			
		}
		
    }
}
public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	if (HasStat(client))
	{
		// if( GetEntProp(client, Prop_Data, "m_afButtonPressed" )) 
		// {
		// PrintToChatAll("BUTTON");	
        //     g_button_held[client] = true;
		// }
		
		if( GetEntProp(client, Prop_Data, "m_afButtonPressed" ) & (IN_ATTACK3|IN_USE) ) 
		{
			
            g_button_held[client] = true;
		}

		if( GetEntProp(client, Prop_Data, "m_afButtonReleased" ) & (IN_ATTACK3|IN_USE) ) 
		{
			//  PrintToChatAll("Release");
			g_button_held[client] = false;
            
		}

		//0 = Shadow Leap
		//PrintToChat(client, "Throwing spell!");
		// UpdateCharge(client);
		g_skill = GetEngineTime();
		DrawHUD(client);
		
	}
	return Plugin_Continue;
}

public void Recharge_Spell(int client) {
	
    int index = g_Spell[client];
    


    if (TF2_IsPlayerInCondition(client, g_Cond))
    {
        index = g_SpellOnCond;
    }
    
    if (g_Cond == 11 && IsKritzed(client))
    {
            index = g_SpellOnCond;
    }
	

		int ent = FindSpellbook(client);
		if (ent) {
			SetEntProp(ent, Prop_Send, "m_iSpellCharges", g_stat_Charges[client]);
			SetEntProp(ent, Prop_Send, "m_iSelectedSpellIndex", index);
			g_book[client] = ent;
		}else
		{
			g_book[client] = -1;
		}



}

public int FindSpellbook(int client) {
	int i = -1;
	while ((i = FindEntityByClassname(i, "tf_weapon_spellbook")) != -1) {
		if (IsValidEntity(i) && GetEntPropEnt(i, Prop_Send, "m_hOwnerEntity") == client && !GetEntProp(i, Prop_Send, "m_bDisguiseWeapon"))
		{
			PrintToChatAll("Book found");
			return i;
		}
	}
	PrintToChatAll("No book found");
	return 0;
}



void DrawHUD(int client)
{
	char sHUDText[128];
	int iCountDown = RoundToCeil(g_Recharge[client] - g_skill);
	char SpellText[64];

	// PrintToChatAll("Gcond %i", g_Cond);
    if (TF2_IsPlayerInCondition(client, g_Cond))
    {
        Format(SpellText, sizeof(SpellText), "%s", Spell_String[g_SpellOnCond]);
    }else
    {
       Format(SpellText, sizeof(SpellText), "%s", Spell_String[g_Spell[client]]);
    }

    if (g_Cond == 11 && IsKritzed(client))
    {
        Format(SpellText, sizeof(SpellText), "%s", Spell_String[g_SpellOnCond]);
    }

	Format(sHUDText, sizeof(sHUDText), "%s: %i   ", SpellText, iCountDown);
	
	if(iCountDown <= 0)
	{
	Format(sHUDText, sizeof(sHUDText), "%s: Ready!", SpellText);

	SetHudTextParams(1.0, 0.8, 0.5, 0, 255, 0, 255);
	//Give The Spell
//	GiveSpellCharge(client);

	} else {
		SetHudTextParams(1.0, 0.8, 0.5, 255, 255, 255, 255);
		
		
	}
	
	ShowHudText(client, -2, sHUDText);


	if (!isready[client] && iCountDown <= 0)
	{
	TF2_AddCondition(client, TFCond_InHealRadius, 0.5);
	// PrintToChatAll("Ready!");
	isready[client] = true;	
	}

	// Old code where the button did the attack
	// if (g_button_held[client] && iCountDown <= 0 && IsPlayerAlive(client))
	// {
	// PrintToChatAll("Pressing button to cast spell");
	// RequestFrame(Recharge_Spell, client);
	// g_Recharge[client] = GetEngineTime() + g_RechargeCooldown;
	// isready[client] = false;
	// }
	if (iCountDown <= 0 && IsPlayerAlive(client) && isready[client] == true)
	{
		if (g_player_charges[client]< 1)RequestFrame(Recharge_Spell, client);
	}
}

public bool IsKritzed(int client){
	if (TF2_IsPlayerInCondition(client, (TFCond_Buffed)) || TF2_IsPlayerInCondition(client, (TFCond_CritCanteen)))
	{
		return true;
	}else
	{
		return false;
	}
}