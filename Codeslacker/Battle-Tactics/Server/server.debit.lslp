/*
	BATTLE TACTICS - SERVER DEBIT V0.0.1a
	Author: Code Slacker
	Description: Handles setting the pay price, refunds and paying out to winners
	NOTES: This script MUST be in the root prim!
	
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
integer g_LMNUM_GLOBAL = 0;				// global server messages
integer g_LMNUM_CONFIG = 1;				// configuration messages
integer g_LMNUM_JOIN = 2;				// join messages
integer g_LMNUM_DEBIT = 3;				// debit messages
integer g_LMNUM_IM = 6;					// instant message messages

key g_OWNER;							// the owner's key


// VARIABLES
// <configuration settings>
integer g_configFreeplay = TRUE;			// freeplay option
integer g_configPrice = 1;					// price setting
// </configuration settings>

integer g_havePerms = FALSE;				// have debit permissions or not


// FUNCTIONS



default
{
	on_rez(integer param)
	{
		llResetScript();
	}
	
	state_entry()
	{
		g_OWNER = llGetOwner();
	}
	
	
	run_time_permissions(integer perms_granted)
	{
		// perms granted
		if (perms_granted & PERMISSION_DEBIT)
		{
			g_havePerms = TRUE;
			llMessageLinked(LINK_THIS, g_LMNUM_JOIN, "perms", "");
		}
		
		// perms not granted
		else
		{
			g_havePerms = FALSE;
			llOwnerSay("[ERROR] - Debit permissions must be granted. If you do not wish to grant them please set Freeplay to ON.");
			llMessageLinked(LINK_THIS, g_LMNUM_JOIN, "noperms", "");		// tell the core script that this script doesn't have debit permissions
			llRequestPermissions(g_OWNER, PERMISSION_DEBIT);
		}
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
			if (msg == "debit_join")
			{
				list parsed = llParseString2List(id, [";"], []);
				g_configFreeplay = (integer)llList2String(parsed, 0);
				g_configPrice = (integer)llList2String(parsed, 1);
								
				// if freeplay is off, request permissions
				if (!g_configFreeplay)
				{
					llRequestPermissions(g_OWNER, PERMISSION_DEBIT);
				}
				
			}
			
		}	// end of config message
		
		
		// debit message
		else if (num == g_LMNUM_DEBIT)
		{
			// price message from the core
			if (msg == "price")
			{
				if (id == "show")
				{
					// if freeplay is on
					if (g_configFreeplay)
					{
						return;			// exit event
					}
					
					llSetPayPrice(g_configPrice, [g_configPrice, g_configPrice, g_configPrice, g_configPrice]);
				}
				
				else if (id == "hide")
				{
					llSetPayPrice(PAY_HIDE, [PAY_HIDE, PAY_HIDE, PAY_HIDE, PAY_HIDE]);
				}
			}
			
			// refund the join price
			else if (msg == "refund")
			{
				// if freeplay is on
				if (g_configFreeplay)
				{
					return;		// exit event
				}
				
				// no permissions
				if (!g_havePerms)
				{
					llMessageLinked(LINK_THIS, g_LMNUM_IM, "The server doesn't have permission to give refunds. Please contact the owner!", id);
					return;
				}
				
				llGiveMoney(id, g_configPrice);
				
			}
			
			// message to give refunds that aren't the price to join, or to pay out (join or core)
			else
			{
				// have permission to give money
				if (g_havePerms)
				{
					integer amount = (integer)msg;
					llGiveMoney(id, amount);
				}
				
				// don't have permission to give money
				else
				{
					llMessageLinked(LINK_THIS, g_LMNUM_IM, "The server doesn't have permission to give refunds. Please contact the owner!", id);
				}
			}
			
		}	// end of debit message
		
	}	// end of link_message event
	
}