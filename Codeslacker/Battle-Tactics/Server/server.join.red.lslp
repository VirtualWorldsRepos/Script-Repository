/*
	BATTLE TACTICS - JOIN RED V0.0.1a
	Author: Code Slacker
	Description: Script used for allowing people to join the game
	
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
integer g_LMNUM_GLOBAL = 0;					// global server messages
integer g_LMNUM_CONFIG = 1;					// configuration message
integer g_LMNUM_JOIN = 2;					// join messages
integer g_LMNUM_DEBIT = 3;					// debit messages
integer g_LMNUM_IM = 6;						// instant message messages

vector g_TEXT_COLOR = <1.0, 0.0, 0.0>;


// VARIABLES
integer g_debitPerms = FALSE;			// if the debit script has permissions
integer g_canJoin = FALSE;				// determines whether a player can join or not

// <configuration settings>
integer g_configFreeplay = TRUE;		// freeplay option
integer g_configPrice = 1;				// the price to join (need this to check if the corerct amount was paid)
// </configuration settings>



// FUNCTIONS



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
		else if (num == g_LMNUM_CONFIG)
		{
			// message aimed towards the debit script and this script
			if (msg == "debit_join")
			{
				list parsed = llParseString2List(id, [";"], []);
				g_configFreeplay = (integer)llList2String(parsed, 0);
				g_configPrice = (integer)llList2String(parsed, 1);
			}
		}
		
		// message to this script
		else if (num == g_LMNUM_JOIN)
		{
			// debit script doesn't have permission
			if (msg == "noperms")
			{
				g_debitPerms = FALSE;
			}
			
			// debit script has permission
			else if (msg == "perms")
			{
				g_debitPerms = TRUE;
			}
			
			// join enabled/disabled message
			else if (msg == "join")
			{
				// join enabled
				if (id == "yes")
				{
					// freeplay
					if (g_configFreeplay)
					{
						g_canJoin = TRUE;
					}
					
					// not freeplay, and debit has permissions
					else if (!g_configFreeplay && g_debitPerms)
					{
						g_canJoin = TRUE;
					}
					
					// not freeplay, no debit permissions
					else
					{
						g_canJoin = FALSE;
					}
				}
				
				// join disabled
				else
				{
					g_canJoin = FALSE;
				}
				
			}
			
			// update text message
			else if (msg == "red_text")
			{
				llSetText(id, g_TEXT_COLOR, 1.0);
			}
			
			// clear text
			else if (msg == "clear_text")
			{
				llSetText("", g_TEXT_COLOR, 1.0);
			}
			
		}	// end messages to this script
		
		
	}
	
	
	
	money(key id, integer amount)
	{
		// someone is being a dirty griefer
		if (amount < 1)
		{
			llMessageLinked(LINK_ROOT, g_LMNUM_IM, "You cannot pay less than 1L!", id);
			return;		// exit event
		}
		
		// if freeplay is enabled, refund
		if (g_configFreeplay)
		{
			llMessageLinked(LINK_ROOT, g_LMNUM_IM, "Freeplay is enabled, refunding money...", id);
			llMessageLinked(LINK_ROOT, g_LMNUM_DEBIT, (string)amount, id);
			return;		// exit event
		}
		
		// correct price wasn't paid
		if (amount != g_configPrice)
		{
			llMessageLinked(LINK_ROOT, g_LMNUM_IM, "You paid the wrong amount. The price to join is " + (string)g_configPrice + "L. Refunding money...", id);
			llMessageLinked(LINK_ROOT, g_LMNUM_DEBIT, (string)amount, id);
			return;		// exit event
		}
		
		// joining is not allowed
		if (!g_canJoin)
		{
			llMessageLinked(LINK_ROOT, g_LMNUM_IM, "Joining is not allowed at the moment.", id);
			llMessageLinked(LINK_ROOT, g_LMNUM_DEBIT, (string)amount, id);
			return;
		}
		
		
		// everything is fine
		llMessageLinked(LINK_ROOT, g_LMNUM_JOIN, "add_red", id);
	}
	
	
	
	touch_start(integer n)
	{
		key id = llDetectedKey(0);
		
		// joining is not allowed
		if (!g_canJoin)
		{
			llMessageLinked(LINK_ROOT, g_LMNUM_IM, "Joining is not allowed at the moment.", id);
			return;
		}
		
		// freeplay is on
		if (g_configFreeplay)
		{
			llMessageLinked(LINK_ROOT, g_LMNUM_JOIN, "add_red", id);
		}
		
	}
}