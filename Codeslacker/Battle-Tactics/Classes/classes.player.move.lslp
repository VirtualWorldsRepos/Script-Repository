/*
	BATTLE TACTICS - PLAYER CLASS MOVEMENT v0.0.1a
	Author: Code Slacker
	Description: Moves the Player class to the position of a player
	
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

float g_MOVE_INTERVAL = 0.4;			// timer interval for following the player


// VARIABLES
float g_playerHeight;					// the height of the player
key g_player;							// the key of the player to follow



// Follows the player
Follow()
{
	list obj_details = llGetObjectDetails(g_player, [OBJECT_POS]);
	vector pos = llList2Vector(obj_details, 0);
	
	// not in sim
	if (pos == ZERO_VECTOR)
	{
		llSay(0, "Player " + llKey2Name(g_player) + " has left the game.");
		llDie();
		return;
	}
	
	// they are in the sim
	pos.z = pos.z + (g_playerHeight / 2);
	
	llSetLinkPrimitiveParamsFast(LINK_SET, [PRIM_POSITION, pos]);
}


default
{
	on_rez(integer param)
	{
		llResetScript();
	}
	
	
	link_message(integer link_num, integer num, string msg, key id)
	{
		if (link_num == g_LMNUM_PLAYER)
		{
			if (msg == "player_key")
			{
				g_player = id;
				llSetTimerEvent(g_MOVE_INTERVAL);
			}
		}
		
	}
	
	
	timer()
	{
		Follow();
	}
	
}