/*
	BATTLE TACTICS - SERVER CORE V0.0.1a
	Author: Code Slacker
	Description: Adds/Removes people from teams, tells the join scripts when people can join, tells debit script the price to join, starts a game, handles global server messages, communicates to HUDs
	
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
// link message numbers (LMNUM)
integer g_LMNUM_GLOBAL = 0;					// global server messages
integer g_LMNUM_CONFIG = 1;					// configuration message
integer g_LMNUM_JOIN = 2;					// join messages
integer g_LMNUM_DEBIT = 3;					// debit messages
integer g_LMNUM_BOARD = 4;					// board messages
integer g_LMNUM_MENU = 5;					// menu button messages
integer g_LMNUM_IM = 6;						// instant message messages
integer g_LMNUM_ITEMS = 7;					// item giver messages

// channel numbers
integer g_CHANNEL_GLOBAL = -9454200;		// global messages (such as "kill" or "start")
integer g_CHANNEL_ADMIN = -9454201;			// admin menu messages
integer g_CHANNEL_PLAYERS = -9454202;		// channel to communicate to the player objects
integer g_CHANNEL_HUD = -9454203;			// channel for the HUD

// team numbers
integer g_TEAM_RED = 0;
integer g_TEAM_BLUE = 1;

float g_COUNTDOWN_SECONDS = 10.0;			// seconds to countdown for a game

// inventory names
string g_INV_HUD = "Battle Tactics Hud v1";
string g_INV_HELP = "Battle Tactics Help";
string g_INV_CLASSDATA = "BT Class Data";
string g_INV_PLAYER = "bt.player";

key g_OWNER;								// the owner's UUID



// VARIABLES

// <configuration section>
integer g_configFreeplay	= TRUE;					// freeplay option (only used for the pot)
integer g_configPrice		= 1;					// the price to join (only used add for the pot)
// payout options
integer g_configPayout 		= FALSE;				// pay out to winners
integer g_configInitialPot 	= 0;					// initial pot to start each game with

integer g_configMaxFactories = 3;					// maximum number of factories allowed

// refinery options
integer g_configRefNum 		 = 2;					// number of refineries per team
integer g_configRefAmount	 = 4;					// amount of money to give each person per refinery on an interval
float g_configRefInterval	 = 1.0;					// interval to give money
integer g_configInitialMoney = 150;					// initial amount of money each player starts off with

// time options (represented in minutes)
float g_configTimeoutJoin	= 4.0;					// join time out
// </configuration section>



// pot variables
integer g_pot = 0;				// amount of money in the pot

// listen handles
integer g_lhAdmin;				// admin channel
integer g_lhHUD;				// HUD channel (only used for "ready" message)

// variables used for when rezzing Player objects
integer g_playerCounter;				// number corresponding to a player in one of the lists
integer g_playerTeam;					// the team currently being rezzed
vector g_playerPos;						// position to rez the player object
integer g_numOfRed;						// reduces llGetListLength calls
integer g_numOfBlue;

// these two lists are parallel
list g_redPlayers = [];			// list of red player keys
list g_redReady = [];			// list of red players that are ready (easier to just use llListStatistics to check if everyone is ready)

list g_bluePlayers = [];		// list of blue player keys
list g_blueReady = [];			// list of blue players that are ready

// lists used for displaying the players on each team and relaying it to the join scripts (this reduces llKey2Name calls)
list g_redNames = [];
list g_blueNames = [];




// FUNCTIONS
// Sets up the server
Setup()
{
	g_OWNER = llGetOwner();
		
	// remove previous listeners
	llListenRemove(g_lhAdmin);
	llListenRemove(g_lhHUD);
	
	// set up listeners
	g_lhAdmin = llListen(g_CHANNEL_ADMIN, "", g_OWNER, "");		// setup listener for admin commands
	g_lhHUD = llListen(g_CHANNEL_HUD, g_INV_HUD, NULL_KEY, "");
	
	llSleep(0.5);		// let the configuration script load first
	
	llOwnerSay("Requesting configuration settings...");
	
	llMessageLinked(LINK_THIS, g_LMNUM_DEBIT, "price", "hide");		// hide the price
	llMessageLinked(LINK_THIS, g_LMNUM_JOIN, "join", "no");			// tell the join scripts that joining is not allowed
	llMessageLinked(LINK_ALL_OTHERS, g_LMNUM_JOIN, "clear_text", "");	// clear the text above the join buttons
	llMessageLinked(LINK_THIS, g_LMNUM_CONFIG, "request", "");		// request configuration data
}



// Adds a player to a team (if they aren't already on another)
AddPlayer(key id, integer team)
{
		// check if they're on a team
	if (llListFindList(g_redPlayers, [id]) > -1)
	{
		llMessageLinked(LINK_THIS, g_LMNUM_IM, "You are already on red!", id);
		llMessageLinked(LINK_THIS, g_LMNUM_DEBIT, "refund", id);		// refund (let the debit script check if freeplay is on)
		return;
	}
	
	if (llListFindList(g_bluePlayers, [id]) > -1)
	{
		llMessageLinked(LINK_THIS, g_LMNUM_IM, "You are already on blue!", id);
		llMessageLinked(LINK_THIS, g_LMNUM_DEBIT, "refund", id);		// refund (let the debit script check if freeplay is on)
		return;
	}
	
	// they're not on a team
	if (team == g_TEAM_RED)
	{
		g_redPlayers += [id];
		g_redReady += [FALSE];
		g_redNames += [llKey2Name(id)];
	}
	
	else if (team == g_TEAM_BLUE)
	{
		g_bluePlayers += [id];
		g_blueReady += [FALSE];
		g_blueNames += [llKey2Name(id)];
	}
		
	UpdateText(team);
	AddPot();
	
	// create a join timeout
	if (g_configTimeoutJoin > 0.0)
	{
		float seconds = g_configTimeoutJoin * 60.0;		// convert minutes to seconds
		
		// format the timeout setting to only display 2 numbers after the decimal
		string formatted = (string)g_configTimeoutJoin;
		formatted = llGetSubString(formatted, 0, llSubStringIndex(formatted, ".")+2);
		
		llSetTimerEvent(seconds);
		llSay(0, "Waiting for new players, session will timeout in " + formatted + " minutes...");
	}
	
}



// Removes a player from the game
RemovePlayer(key id)
{
	// red team
	integer index = llListFindList(g_redPlayers, [id]);
	
	if (index > -1)
	{
		g_redPlayers = llDeleteSubList(g_redPlayers, index, index);
		g_redReady = llDeleteSubList(g_redReady, index, index);
		g_redNames = llDeleteSubList(g_redNames, index, index);
		UpdateText(g_TEAM_RED);
		RemovePot();
		
		llMessageLinked(LINK_THIS, g_LMNUM_DEBIT, "refund", id);	// refund the player
		return;
	}
	
	// blue team
	index = llListFindList(g_bluePlayers, [id]);
	
	if (index > -1)
	{
		g_bluePlayers = llDeleteSubList(g_bluePlayers, index, index);
		g_blueReady = llDeleteSubList(g_blueReady, index, index);
		g_blueNames = llDeleteSubList(g_blueNames, index, index);
		UpdateText(g_TEAM_BLUE);
		RemovePot();
		
		llMessageLinked(LINK_THIS, g_LMNUM_DEBIT, "refund", id);	// refund the player
	}
	
}



// Remove all players from the game (refunds if applicable)
RemoveAllPlayers()
{
	// freeplay
	if (g_configFreeplay)
	{
		// clear the lists
		g_redPlayers = [];
		g_redReady = [];
		g_redNames = [];
		
		g_bluePlayers = [];
		g_blueReady = [];
		g_blueNames = [];
		
		g_pot = g_configInitialPot;
		
		llMessageLinked(LINK_ALL_OTHERS, g_LMNUM_JOIN, "clear_text", "");		// clear display text
	}
	
	// not freeplay
	else
	{
		integer num_of_red = llGetListLength(g_redPlayers);
		integer i;
		for (i=0; i<num_of_red; i++)
		{
			RemovePlayer(llList2Key(g_redPlayers, 0));
		}
		
		integer num_of_blue = llGetListLength(g_bluePlayers);	
		for (i=0; i<num_of_blue; i++)
		{
			RemovePlayer(llList2Key(g_bluePlayers, 0));
		}
	}
	
}



// Makes a player ready
PlayerReady(key id)
{
	integer index = llListFindList(g_redPlayers, [id]);
	if (index > -1)
	{
		g_redReady = llListReplaceList(g_redReady, [TRUE], index, index);
		UpdateText(g_TEAM_RED);
		CheckReady();
		return;
	}
	
	index = llListFindList(g_redPlayers, [id]);
	if (index > -1)
	{
		g_redReady = llListReplaceList(g_redReady, [TRUE], index, index);
		UpdateText(g_TEAM_BLUE);
		CheckReady();
		return;
	}
	
}



// Checks if all players are ready, if so start the game
CheckReady()
{
	integer num_of_players = llGetListLength(g_redPlayers) + llGetListLength(g_bluePlayers);
	integer sum = llRound(llListStatistics(LIST_STAT_SUM, g_redReady) + llListStatistics(LIST_STAT_SUM, g_blueReady));
	
	// all players are ready
	if (sum == num_of_players)
	{
		StartGame();
	}
}



// Updates the llSetText of the team join scripts
UpdateText(integer team)
{
	string text;
	
	if (team == g_TEAM_RED)
	{
		integer num_of_red = llGetListLength(g_redNames);
		
		integer i;
		for (i=0; i<num_of_red; i++)
		{
			// ready
			if (llList2Integer(g_redReady, i))
			{
				text += "[+] ";
			}
			// not ready
			else
			{
				text += "[-] ";
			}
			
			text += llList2String(g_redNames, i) + "\n";
		}
		
		llMessageLinked(LINK_ALL_OTHERS, g_LMNUM_JOIN, "red_text", text);
	}
	
	else
	{
		integer num_of_blue = llGetListLength(g_blueNames);
		
		integer i;
		for (i=0; i<num_of_blue; i++)
		{
			// ready
			if (llList2Integer(g_blueReady, i))
			{
				text += "[+] ";
			}
			// not ready
			else
			{
				text += "[-] ";
			}
			
			text += llList2String(g_blueNames, i) + "\n";
		}
		
		llMessageLinked(LINK_ALL_OTHERS, g_LMNUM_JOIN, "blue_text", text);
	}
	
}


// Starts a new game
StartGame()
{
	llMessageLinked(LINK_ALL_OTHERS, g_LMNUM_JOIN, "join", "no");
	llMessageLinked(LINK_THIS, g_LMNUM_DEBIT, "price", "hide");
	
	rotation rot = llGetRot();
	g_playerPos = llGetPos() + (llRot2Fwd(rot) * 3);
	g_numOfRed = llGetListLength(g_redPlayers);
	g_numOfBlue = llGetListLength(g_bluePlayers);
	g_playerTeam = g_TEAM_RED;
	
	llRezObject(g_INV_PLAYER, g_playerPos, ZERO_VECTOR, ZERO_ROTATION, 1);
	// the rest will be done in the object_rez event
}



// Ends the game
EndGame(integer winning_team)
{
	llRegionSay(g_CHANNEL_GLOBAL, "kill");		// global kill message
	
	if (g_configPayout)
	{
		Payout(winning_team);
	}
	
	llMessageLinked(LINK_ALL_OTHERS, g_LMNUM_JOIN, "clear_text", "");		// clear the text above the join buttons
	llMessageLinked(LINK_ALL_OTHERS, g_LMNUM_JOIN, "join", "yes");
	llMessageLinked(LINK_THIS, g_LMNUM_DEBIT, "price", "show");
}



// Pays out to winners
Payout(integer team)
{
	// red team
	if (team == g_TEAM_RED)
	{
		integer num_of_red = llGetListLength(g_redPlayers);
		integer pot_divided;
		
		// pot divides evenly amongst players
		if ((g_pot % num_of_red) == 0)
		{
			pot_divided = g_pot / num_of_red;
		}
		// not evenly
		else
		{
			pot_divided = llFloor(g_pot / num_of_red);
		}
		
		integer i;
		for (i=0; i<num_of_red; i++)
		{
			llMessageLinked(LINK_THIS, g_LMNUM_DEBIT, (string)pot_divided, llList2Key(g_redPlayers, i));
		}
		
	}
	
	// blue team
	else
	{
		integer num_of_blue = llGetListLength(g_bluePlayers);
		integer pot_divided;
		
		// pot divides evenly amongst players
		if ((g_pot % num_of_blue) == 0)
		{
			pot_divided = g_pot / num_of_blue;
		}
		// not evenly
		else
		{
			pot_divided = llFloor(g_pot / num_of_blue);
		}
		
		integer i;
		for (i=0; i<num_of_blue; i++)
		{
			llMessageLinked(LINK_THIS, g_LMNUM_DEBIT, (string)pot_divided, llList2Key(g_bluePlayers, i));
		}
		
	}


}



// Adds to the pot
AddPot()
{
	if (!g_configFreeplay && g_configPayout)
	{
		g_pot += g_configPrice;
	}
}


// Removes from the pot
RemovePot()
{
	if (!g_configFreeplay && g_configPayout)
	{
		g_pot -= g_configPrice;
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
		Setup();
	}
	
	
	listen(integer channel, string name, key id, string msg)
	{
		if (channel == g_CHANNEL_ADMIN)
		{
			msg = llToLower(msg);		// convert to lowercase for easier comparison
			
			if (msg == "reset")
			{
				llMessageLinked(LINK_SET, g_LMNUM_GLOBAL, "reset", "");
				llResetScript();
			}
			
			else if (msg == "reload cfg")
			{
				Setup();
			}
		}
		
	}
	
	
	link_message(integer link_num, integer num, string msg, key id)
	{
		// config message
		if (num == g_LMNUM_CONFIG && msg == "core")
		{
			list parsed = llParseString2List(id, [";"], []);

			g_configFreeplay 	 = (integer)llList2String(parsed, 0);
			g_configPrice		 = (integer)llList2String(parsed, 1);
			g_configPayout 		 = (integer)llList2String(parsed, 2);
			g_configInitialPot 	 = (integer)llList2String(parsed, 3);
			g_configMaxFactories = (integer)llList2String(parsed, 4);
			g_configRefNum 		 = (integer)llList2String(parsed, 5);
			g_configRefAmount 	 = (integer)llList2String(parsed, 6);
			g_configRefInterval  = (float)llList2String(parsed, 7);
			g_configInitialMoney = (integer)llList2String(parsed, 8);
			g_configTimeoutJoin  = (float)llList2String(parsed, 9);
			
			llMessageLinked(LINK_THIS, g_LMNUM_DEBIT, "price", "show");
			llMessageLinked(LINK_ALL_OTHERS, g_LMNUM_JOIN, "join", "yes");
			
			llOwnerSay("[STATUS] - Configuration complete!");
										
		}	// end of config message
		
		
		// join message
		else if (num == g_LMNUM_JOIN)
		{
			// add to red team
			if (msg == "add_red")
			{
				AddPlayer(id, g_TEAM_RED);
			}
			
			// add to blue team
			else if (msg == "add_blue")
			{
				AddPlayer(id, g_TEAM_BLUE);
			}
			
		}	// end of join message
		
		
		// menu message
		else if (num == g_LMNUM_MENU)
		{
			if (msg == "admin")
			{
				if (id != g_OWNER)
				{
					return;
				}
				
				llDialog(g_OWNER, "Admin Menu", ["Reset", "Reload Cfg"], g_CHANNEL_ADMIN);
			}
			
			else if (msg == "gethud")
			{
				llMessageLinked(LINK_THIS, g_LMNUM_ITEMS, g_INV_HUD, id);
			}
			
			else if (msg == "classdata")
			{
				llMessageLinked(LINK_THIS, g_LMNUM_ITEMS, g_INV_CLASSDATA, id);
			}
			
			else if (msg == "help")
			{
				llMessageLinked(LINK_THIS, g_LMNUM_ITEMS, g_INV_HELP, id);
			}
			
			else if (msg == "quit")
			{
				RemovePlayer(id);
			}
		}
		
	}
	
	
	timer()
	{
		llSay(0, "Game session timed out. Please rejoin.");
		RemoveAllPlayers();
		llSetTimerEvent(0.0);
	}
	
	
	object_rez(key id)
	{
		// rez a Player object, get the UUID of a player on either team, relay to the Player object which UUID to associate it with
		key player;
		
		if (g_playerTeam == g_TEAM_RED)
		{
			player = llList2Key(g_redPlayers, g_playerCounter);
		}
		else
		{
			player = llList2Key(g_bluePlayers, g_playerCounter);
		}
		
		// the first part of the string is the Player object's UUID (in case it somehow goes out of order :S)
		string data = (string)id + ";" +
					  (string)player + ";" +
					  (string)g_playerTeam + ";" +
	  				  (string)g_configMaxFactories +
					  (string)g_configRefNum + ";" +
					  (string)g_configRefAmount + ";" +
					  (string)g_configRefInterval + ";" +
					  (string)g_configInitialMoney;
		
		llSay(g_CHANNEL_PLAYERS, data);
		
		g_playerCounter++;
		
		// check if there are no more players on a team
		if (g_playerTeam == g_TEAM_RED)
		{
			if (g_playerCounter == g_numOfRed-1)
			{
				g_playerCounter = 0;
				g_playerTeam = g_TEAM_BLUE;
			}
		}
		else
		{
			if (g_playerCounter == g_numOfBlue-1)
			{
				g_playerCounter = 0;
				
				llRegionSay(g_CHANNEL_HUD, "countdown " + (string)g_COUNTDOWN_SECONDS);
				llSleep(g_COUNTDOWN_SECONDS);
				llRegionSay(g_CHANNEL_PLAYERS, "start");
				
				return;		// exit event
			}
		}
		
		llRezObject(g_INV_PLAYER, g_playerPos, ZERO_VECTOR, ZERO_ROTATION, 1);
	}
	
}