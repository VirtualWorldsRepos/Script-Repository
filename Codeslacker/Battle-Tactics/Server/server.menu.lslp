/*
	BATTLE TACTICS - SERVER MENU V0.0.1a
	Author: Code Slacker
	Description: Menu buttons script
	
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
integer g_LMNUM_MENU = 5;			// menu messages

integer g_PRIM_FACE = 3;			// the face the menu is on
integer g_NUM_OF_BUTTONS = 5;		// number of buttons on the prim face

// buttons
integer g_BUTTON_ADMIN = 0;
integer g_BUTTON_GET_HUD = 1;
integer g_BUTTON_CLASS_DATA = 2;
integer g_BUTTON_HELP = 3;
integer g_BUTTON_QUIT = 4;

float g_BUTTON_SIZE;			// the size of each button
vector g_SCALE;

// VARIABLES


// FUNCTIONS



default
{
	on_rez(integer param)
	{
		llResetScript();
	}
	
	state_entry()
	{
		g_SCALE = llGetScale();
		g_BUTTON_SIZE = g_SCALE.z / g_NUM_OF_BUTTONS;
	}
	
	touch_start(integer n)
	{
		// if wrong face was touched
		if (llDetectedTouchFace(0) != g_PRIM_FACE)
		{
			return;		// exit event
		}
		
		vector prim_pos = llGetPos();
		vector touch_pos = llDetectedTouchPos(0);
		float top = prim_pos.z + (g_SCALE.z / 2);		// get the top position of the prim
		
		integer button_touched = llFloor((top - touch_pos.z) / g_BUTTON_SIZE);
		
		key id = llDetectedKey(0);
		
		if (button_touched == g_BUTTON_ADMIN)
		{
			llMessageLinked(LINK_ROOT, g_LMNUM_MENU, "admin", id);
		}
		
		else if (button_touched == g_BUTTON_GET_HUD)
		{
			llMessageLinked(LINK_ROOT, g_LMNUM_MENU, "gethud", id);			
		}
		
		else if (button_touched == g_BUTTON_CLASS_DATA)
		{
			llMessageLinked(LINK_ROOT, g_LMNUM_MENU, "classdata", id);
		}
		
		else if (button_touched == g_BUTTON_HELP)
		{
			llMessageLinked(LINK_ROOT, g_LMNUM_MENU, "help", id);
		}
		
		else if (button_touched == g_BUTTON_QUIT)
		{
			llMessageLinked(LINK_ROOT, g_LMNUM_MENU, "quit", id);
		}
	}
	
}