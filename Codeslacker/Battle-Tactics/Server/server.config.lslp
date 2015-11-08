/*
	BATTLE TACTICS - SERVER CONFIG V0.0.1a
	Author: Code Slacker
	Description: Loads data from the configuration notecard and relays it to other scripts
	
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

string g_NOTECARD_CONFIG = "bt.nc.config";			// name of the configuration notecard


// VARIABLES
// <configuration section>
integer g_configFreeplay 	= TRUE;					// freeplay option
integer g_configPrice 		= 1;					// price setting

// payout options
integer g_configPayout 		= FALSE;				// pay out to winners
integer g_configPayoutAll 	= TRUE;					// pay out to ALL winners (if the pot can't be divided evenly)
integer g_configInitialPot 	= 0;					// initial pot to start each game with

// refinery options
integer g_configRefNum 		= 2;					// number of refineries per team
integer g_configRefAmount	= 4;					// amount of money to give each person per refinery on an interval
float g_configRefInterval	= 1.0;					// interval to give money
integer g_configInitialMoney = 150;					// initial amount of money each player starts off with

integer g_configMaxFactories = 3;					// maximum number of factories per player

// time options (represented in minutes)
float g_configTimeLimit 	= 10.0;					// time limit per game
float g_configTimeCapture	= 2.5;					// amount of time to hold the point in order to win
float g_configTimeoutJoin	= 4.0;					// join time out
// </configuration section>


integer g_currentLine;			// current line being read on the notecard
key g_reqID;					// request ID for dataserver


// FUNCTIONS
// Relays the settings to other scripts
RelaySettings()
{
	// stuff to be relayed to the core
	string core = (string)g_configFreeplay + ";" +
				  (string)g_configPrice + ";" +
				  (string)g_configPayout + ";" +
				  (string)g_configInitialPot + ";" +
				  (string)g_configMaxFactories + ";" +
				  (string)g_configRefNum + ";" +
				  (string)g_configRefAmount + ";" +
				  (string)g_configRefInterval + ";" +
				  (string)g_configInitialMoney + ";" +
				  (string)g_configTimeoutJoin;
				  
	// stuff to be relayed to the board
	string board = (string)g_configTimeLimit + ";" +
				   (string)g_configTimeCapture;
		
	// stuff to be relayed to the debit/join scripts (join needs the price in order to determine if the right amount was paid)
	string debit_join = (string)g_configFreeplay + ";" +
						(string)g_configPrice;
	
	// the linked messages
	llMessageLinked(LINK_THIS, g_LMNUM_CONFIG, "core", core);
	llMessageLinked(LINK_THIS, g_LMNUM_CONFIG, "board", board);
	llMessageLinked(LINK_THIS, g_LMNUM_CONFIG, "debit_join", debit_join);
}


// Reads input and determines whether it's true or false
integer TrueOrFalse(string data)
{
	if (data == "on" || data == "yes" || data == "true" || data == "1")
	{
		return TRUE;
	}
	
	else
	{
		return FALSE;
	}
	
}



default
{
	on_rez(integer param)
	{
		llResetScript();
	}
	
	link_message(integer link_num, integer num, string msg, key id)
	{
		// global server message
		if (num == g_LMNUM_GLOBAL)
		{
			if (msg == "reset")
			{
				llResetScript();
			}
		}
		
		// configuration message
		else if (num == g_LMNUM_CONFIG && msg == "request")
		{
			if (llGetInventoryType(g_NOTECARD_CONFIG) == -1)
			{
				llOwnerSay("[ERROR] - Configuration notecard (" + g_NOTECARD_CONFIG + ") not found.");
				return;
			}
			
			llOwnerSay("Reading configuration notecard...");
			g_reqID = llGetNotecardLine(g_NOTECARD_CONFIG, g_currentLine);
		}
		
	}
	
	dataserver(key req_id, string data)
	{
		// if request ids don't match
		if (req_id != g_reqID)
		{
			return;
		}
		
		// at end of file
		if (data == EOF)
		{
			RelaySettings();
			return;		// exit event
		}
		
		// the line is blank or a comment
		if (data == "" || llGetSubString(data, 0, 0) == "#")
		{
			// read next line
			g_currentLine++;
			g_reqID = llGetNotecardLine(g_NOTECARD_CONFIG, g_currentLine);
			return;		// exit event
		}

		
		integer index = llSubStringIndex(data, "=");
		string setting = llGetSubString(data, 0, index-1);
		string value = llGetSubString(data, index+1, -1);
		
		// trim the strings and convert to lowercase for easier comparison
		setting = llToLower(llStringTrim(setting, STRING_TRIM));
		value = llToLower(llStringTrim(value, STRING_TRIM));
		
		if (setting == "config_freeplay")
		{
			g_configFreeplay = TrueOrFalse(value);
		}
		
		else if (setting == "config_price")
		{
			g_configPrice = (integer)value;
			
			// price setting can't be less than 1
			if (g_configPrice < 1)
			{
				g_configPrice = 1;
				llOwnerSay("[WARNING] - Price cannot be set to a value less than 1, defaulting to 1.");
			}
			
		}
		
		else if (setting == "config_payout")
		{
			g_configPayout = TrueOrFalse(value);			
		}
		
		else if (setting == "config_initial_pot")
		{
			g_configInitialPot = (integer)value;
			
			// don't accept negative values
			if (g_configInitialPot < 0)
			{
				g_configInitialPot = 0;
				llOwnerSay("[WARNING] - Initial Pot setting cannot be less than 0, defaulting to 0.");
			}
			
		}
		
		else if (setting == "config_ref_num")
		{
			g_configRefNum = (integer)value;
			
			// can't be less than one
			if (g_configRefNum < 1)
			{
				g_configRefNum = 1;
				llOwnerSay("[WARNING] - Number of refineries setting cannot be less than 1, defaulting to 1.");
			}
			
		}
		
		else if (setting == "config_ref_amount")
		{
			g_configRefAmount = (integer)value;
			
			// can't be less than 1
			if (g_configRefAmount < 1)
			{
				g_configRefAmount = 1;
				llOwnerSay("[WARNING] - Amount of money per refinery setting cannot be less than 1, defaulting to 1.");
			}
			
		}
		
		else if (setting == "config_ref_interval")
		{
			g_configRefInterval = (float)value;
			
			// can't be less than 0.005
			if (g_configRefInterval < 0.005)
			{
				g_configRefInterval = 0.005;
				llOwnerSay("[WARNING] - Refinery interval cannot be less than 0.005, defaulting to 0.005.");
			}
			
		}
		
		else if (setting == "config_initial_money")
		{
			g_configInitialMoney = (integer)value;	
		}
		
		else if (setting == "config_max_factories")
		{
			g_configMaxFactories = (integer)value;
			
			// can't be less than 1
			if (g_configMaxFactories < 1)
			{
				g_configMaxFactories = 1;
				llOwnerSay("[WARNING] - Max number of factories setting cannot be less than 1, defaulting to 1.");
			}
			
		}
		
		else if (setting == "config_time_limit")
		{
			g_configTimeLimit = (float)value;
			
			// can't be less than 1 minute
			if (g_configTimeLimit < 1.0)
			{
				g_configTimeLimit = 1.0;
				llOwnerSay("[WARNING] - Time limit cannot be set to less than 1 minute, defaulting to 1 minute.");
			}
			
		}
		
		else if (setting == "config_time_capture")
		{
			g_configTimeCapture = (float)value;
			
			// can't be 0.0 or less than 0.00005
			if (g_configTimeCapture == 0.00005)
			{
				g_configTimeCapture = 0.00005;
				llOwnerSay("[WARNING] - Capture time cannot be set to less than 0.00005 minutes, default to 0.00005 minutes.");
			}
			
		}
		
		else if (setting == "config_timeout_join")
		{
			g_configTimeoutJoin = (float)value;
			
			// can't be less than 0
			if (g_configTimeoutJoin < 0.0)
			{
				g_configTimeoutJoin = 0.0;
				llOwnerSay("[WARNING] - Join timeout cannot be set to less than 0 seconds, defaulting to no timeout.");
			}
			
		}
		
		
		// get next line
		g_currentLine++;
		g_reqID = llGetNotecardLine(g_NOTECARD_CONFIG, g_currentLine);
		
	}	// end of dataserver event
	
}