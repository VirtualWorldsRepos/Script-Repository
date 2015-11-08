/*
	BATTLE TACTICS - PLAYER CLASS v0.0.1a
	Author: Code Slacker
	Description: Handles player health, money and building
	
	<LICENSE>
	    Copyright (C) 2011  Code Slacker
	
	    This program is free software: you can redistribute it and/or modify
	    it under the terms of the GNU General Public License as published by
	    the Free Software Foundation, either version 3 of the License, or
	    (at your option) any later version.
	
	    This program is distributed in the hope that it will be useful,
	    but WITHOUT ANY WARRANTY; without even the implied warranty of
	    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	    GNU General Public License for more details.
	
	    You should have received a copy of the GNU General Public License
	    along with this program.  If not, see <http://www.gnu.org/licenses/>.	
	</LICENSE>
	
*/

/*
	=======================================
	CHANGE LOG
	
	=======================================
*/


// CONSTANTS
// link message numbers
integer g_LMNUM_PLAYER = 8;

// channels
integer g_CHANNEL_GLOBAL = -9454200;		// global server messages (such as "kill")
integer g_CHANNEL_PLAYERS = -9454201;		// channel for Player messages
integer g_CHANNEL_HUD = -9454202;			// channel for HUD messages
integer g_CHANNEL_REPAIR = -9454204;		// channel for repair messages

// teams
integer g_TEAM_RED = 0;
integer g_TEAM_BLUE = 1;

// stats
integer g_MAX_HEALTH = 100;					// maximum health the class has
integer g_DEF_POINTS = 5;					// defense points the class has

// prices
integer g_PRICE_REPAIR = 150;				// cost to repair structures
integer g_PRICE_BUILD_TANK_FACTORY = 400;	// cost to build a tank factory
integer g_PRICE_BUILD_AIRBASE = 500;		// cost to build an airbase
integer g_PRICE_BUILD_BARRACKS = 75;		// cost to build barracks
integer g_PRICE_BUILD_SNIPER_TOWER = 75;	// cost to build a sniper tower
integer g_PRICE_BUILD_TANK = 150;			// cost to build a tank
integer g_PRICE_BUILD_TANK_MINE = 50;		// cost to build an anti-tank mine
integer g_PRICE_BUILD_FLAK_GUN = 150;		// cost to build an anti-flak gun

// build names
string g_BUILD_NAME_TANK_FACTORY = "tank_factory";
string g_BUILD_NAME_AIRBASE = "airbase";
string g_BUILD_NAME_BARRACKS = "barracks";
string g_BUILD_NAME_SNIPER_TOWER = "sniper_tower";
string g_BUILD_NAME_TANK = "tank";
string g_BUILD_NAME_TANK_MINE = "at_mine";
string g_BUILD_NAME_FLAK_GUN = "flak";

// sounds

key g_OWNER;								// the owner's key



// VARIABLES
integer g_health;							// amount of health the class has
integer g_money;							// amount of money the player has
integer g_team;								// team the player is on


// <configuration section>
integer g_configRefNum;						// number of refineries
integer g_configRefAmount;					// the amount of money each refinery generates
float g_configRefInterval;					// the interval for generating money
integer g_configInitialMoney;				// initial amount of money to start off with
integer g_configMaxFactories;				// maximum number of factories allowed to be built
// </configuration section>

// listen handles
integer g_lhGlobal;							// global messages handle
integer g_lhPlayers;						// the player handle
integer g_lhHUD;							// the HUD handle

float g_playerHeight;						// height of the player

// board properties
vector g_boardPos;							// position of the board (used for build position limiting)

// keys
key g_player;								// the player's key
key g_uuid;									// the UUID of this object
key g_board;								// the board's key (used for checking if the build position is in range)


// FUNCTIONS
// Initialization
Init()
{
	g_OWNER = llGetOwner();
	g_uuid = llGetKey();
	
	llSetStatus(STATUS_PHANTOM, TRUE);
	
	llParticleSystem([]);		// clear any particles
	
	g_health = g_MAX_HEALTH;
	// UpdateHealthBar();
	
	g_lhGlobal = llListen(g_CHANNEL_GLOBAL, "Battle Tactics Game v1", NULL_KEY, "");
	g_lhPlayers = llListen(g_CHANNEL_PLAYERS, "Battle Tactics Game v1", NULL_KEY, "");
}


// Impair damage
Damage(integer attack)
{
	integer dmg = llRound((attack / g_DEF_POINTS) * 2);
	
	g_health -= dmg;
	
	// dead
	if (g_health <= 0)
	{
		Destroy();
		return;
	}
	
	UpdateText();
}


// Updates the health bar and money text
UpdateText()
{
	string text = "Money: " + (string)g_money + "\n(" + (string)g_health + "%) ";
	
	float red = (100 - g_health) / (float)g_MAX_HEALTH;
	float green = g_health / (float)g_MAX_HEALTH;
	vector color = <red, green, 0.0>;
	
	integer num_of_bars = llFloor(g_health / 10);
	
	integer i;
	for (i=0; i<num_of_bars; i++)
	{
		text += "█";
	}
	
	llSetText(text, color, 1.0);
	
	float alpha = (g_health / 100.0) + 0.2;		// set the alpha but don't let it get too low
	llSetAlpha(alpha, ALL_SIDES);
		
}


// Destroys the object
Destroy()
{
	llSetText("**** DEAD ****", <1.0, 0.0, 0.0>, 1.0);

	llSleep(5.0);
	
	llListenRemove(g_lhGlobal);
	
	llDie();		// kill the object
}


// Activates the Player object; means the game started
Activate()
{
	vector agent_size = llGetAgentSize(g_player);
	g_playerHeight = agent_size.z;
	
	// tell move script the player's key, which in turn activates the follow interval
	llMessageLinked(LINK_THIS, g_LMNUM_PLAYER, "player_key", g_player);
	UpdateText();
	
	llSetTimerEvent(g_configRefInterval);		// refinery interval
	
}


// Function to check if the player has enough money to do something
integer CheckMoney(integer amount)
{
	// has enough
	if (g_money >= amount)
	{
		return TRUE;
	}
	
	// doesn't have enough
	else
	{
		return FALSE;
	}
}


// Build function
Build(string type)
{
	integer price;
	
	if (type == g_BUILD_NAME_TANK_FACTORY)
	{
		price = g_PRICE_BUILD_TANK_FACTORY;
	}
	
	else if (type == g_BUILD_NAME_AIRBASE)
	{
		price = g_PRICE_BUILD_AIRBASE;
	}
	
	else if (type == g_BUILD_NAME_BARRACKS)
	{
		price = g_PRICE_BUILD_BARRACKS;
	}
	
	else if (type == g_BUILD_NAME_SNIPER_TOWER)
	{
		price = g_PRICE_BUILD_SNIPER_TOWER;
	}
	
	else if (type == g_BUILD_NAME_TANK)
	{
		price = g_PRICE_BUILD_TANK;
	}
	
	else if (type == g_BUILD_NAME_TANK_MINE)
	{
		price = g_PRICE_BUILD_TANK_MINE;
	}
	
	else if (type == g_BUILD_NAME_FLAK_GUN)
	{
		price = g_PRICE_BUILD_FLAK_GUN;
	}
	
	// check if the player has enough money
	if (CheckMoney(price))
	{
		// the object's position should be at roughly the player's feet
		vector pos = llGetPos();
		pos.z = pos.z - g_playerHeight;
		
		// if on red team
		if (g_team == g_TEAM_RED)
		{
			llRezObject("classes.red." + type, pos, ZERO_VECTOR, ZERO_ROTATION, 1);
		}
		
		// blue team
		else
		{
			llRezObject("classes.blue." + type, pos, ZERO_VECTOR, ZERO_ROTATION, 1);
		}
		
		g_money -= price;
	}
	
	// not enough money
	else
	{
		llWhisper(0, "You don't have enough money to build that!");
	}
	
}


// Repair function
Repair(key id)
{
	// make sure the structure is on the same team
	list obj_details = llGetObjectDetails(id, [OBJECT_NAME]);
	string name = llList2String(obj_details, 0);

	// red	
	if (g_team == g_TEAM_RED)
	{
		
		if (llGetSubString(name, 11, 13) != "red")
		{
			llWhisper(0, "You cannot repair a structure belonging to the other team!");
			return;		// exit function
		}
		
	}
	
	// blue
	else 
	{
		if (llGetSubString(name, 11, 14) != "blue")
		{
			llWhisper(0, "You cannot repair a structure belonging to the other team!");
			return;		// exit function
		}
	}
	
	// if have enough money to repair and the structure is on the same team
	if (CheckMoney(g_PRICE_REPAIR))
	{
		llRegionSay(g_CHANNEL_REPAIR, id);
		g_money -= g_PRICE_REPAIR;
	}
	
	else
	{
		llWhisper(0, "You don't have enough money to repair anything!");
	}
	
}


default
{
	on_rez(integer param)
	{
		llResetScript();
	}
	
	state_entry()
	{
		Init();
	}
	
	listen(integer channel, string name, key id, string msg)
	{
		// if the owner's object is talking (server or building)
		if (llGetOwnerKey(id) == g_OWNER)
		{
			// global server channel
			if (channel == g_CHANNEL_GLOBAL)
			{
				if (msg == "kill")
				{
					Destroy();
				}
				
				// server start message
				else if (llGetSubString(msg, 0, 8) == "countdown")
				{
					g_board = id;		// set the board's key to this
					
					float sleep = (float)llGetSubString(msg, 9, -1);
					llSleep(sleep);
					
					Activate();
				}
			}
			
			// players channel
			else if (channel == g_CHANNEL_PLAYERS)
			{				
				// parse data
				list parsed = llParseString2List(msg, [";"], []);
				key uuid = (key)llList2String(parsed, 0);
				
				// if not talking to this object
				if (uuid != g_uuid)
				{
					return;		// exit event
				}
				
				g_player			 = (key)llList2String(parsed, 1);
				g_team 				 = (integer)llList2String(parsed, 2);
				g_configMaxFactories = (integer)llList2String(parsed, 3);
				g_configRefNum 		 = (integer)llList2String(parsed, 4);
				g_configRefAmount 	 = (integer)llList2String(parsed, 5);
				g_configRefInterval  = (float)llList2String(parsed, 6);
				
				// get the position of the board
				list obj_details = llGetObjectDetails(id, [OBJECT_POS]);
				g_boardPos = llList2Vector(obj_details, 0);
				
			}
		}
		
		
		// player HUD is talking
		else if (channel == g_CHANNEL_HUD && llGetOwnerKey(id) == g_player)
		{
			integer find_pos = llSubStringIndex(msg, ":");
			string command = llGetSubString(msg, 0, find_pos-1);
			string param = llGetSubString(msg, find_pos+1, -1);
			
			// repair command
			if (command == "repair")
			{
				Repair((key)param);
			}
			
			// build command
			else if (command == "build")
			{
				Build(param);
			}
			
		}	// end of player HUD channel
		
	}	// end of listen event
	
	
	
	timer()
	{
		g_money += g_configRefAmount * g_configRefNum;
		UpdateText();
	}
	
}