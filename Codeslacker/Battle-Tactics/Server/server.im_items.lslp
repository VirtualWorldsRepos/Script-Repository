/*
	BATTLE TACTICS - SERVER ITEM/IM V0.0.1a
	Author: Code Slacker
	Description: Instant message scripts (separate because it sleeps the script for 2 seconds)
	
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
integer g_LMNUM_GLOBAL = 0;			// global server messages
integer g_LMNUM_IM = 6;				// instant messages
integer g_LMNUM_ITEMS = 7;			// item messages



// VARIABLES



// FUNCTIONS



default
{
	on_rez(integer param)
	{
		llResetScript();
	}
	
	link_message(integer link_num, integer num, string msg, key id)
	{
		// global message
		if (num == g_LMNUM_GLOBAL)
		{
			if (msg == "reset")
			{
				llResetScript();
			}
		}
		
		else if (num == g_LMNUM_IM)
		{
			llInstantMessage(id, msg);
		}
		
		else if (num == g_LMNUM_ITEMS)
		{
			if (llGetInventoryType(msg) == -1)
			{
				llInstantMessage(id, "This item doesn't exist in the server's inventory. Please contact the owner!");
				return;		// exit event
			}
			
			llGiveInventory(id, msg);
		}
		
	}
	
}