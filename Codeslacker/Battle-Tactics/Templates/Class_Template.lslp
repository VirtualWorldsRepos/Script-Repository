/*
	BATTLE TACTICS - <name> <version>
	Author: Code Slacker
	Description: <description>
	
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
// channels
integer g_CHANNEL_GLOBAL = -9454200;		// global messages (such as "kill")

// stats
integer g_MAX_HEALTH = 100;					// maximum health the class has
integer g_DEF_POINTS = 5;					// defense points the class has

// sounds
string g_SND_EXPLODE = "a9c991e5-68ca-e577-3357-082dc26e5da8";

// textures (for particles)
string g_TEXTURE_EXPLODE = "b597e1ce-51ce-d3ee-37fc-07eb0f1016ec";

// particle systems
list g_PSYS_EXPLOSION = [PSYS_PART_START_ALPHA, 1.0,
						 PSYS_PART_END_ALPHA, 0.0,
						 PSYS_PART_START_SCALE, <1.0, 1.0, 0.0>,
						 PSYS_PART_END_SCALE, <0.6, 0.6, 0.0>,
						 PSYS_PART_START_COLOR, <0.8, 0.0, 0.0>,
						 PSYS_PART_END_COLOR, <0.5, 0.0, 0.0>,
						 PSYS_PART_MAX_AGE, 4.0,
						 PSYS_SRC_MAX_AGE, 10.0,
						 PSYS_SRC_BURST_PART_COUNT, 1,
						 PSYS_SRC_BURST_RADIUS, 0.0,
						 PSYS_SRC_BURST_RATE, 2.0,
						 PSYS_SRC_TEXTURE, g_TEXTURE_EXPLODE,
						 PSYS_PART_FLAGS, PSYS_PART_INTERP_COLOR_MASK
						];
						
key g_OWNER;								// the owner's key
key g_UUID;									// the UUID of this object



// VARIABLES
integer g_health;							// amount of health the class has

// listen handles
integer g_lhGlobal;							// the global messages handle




// FUNCTIONS
// Initialization
Init()
{
	g_OWNER = llGetOwner();
	g_UUID = llGetKey();
	
	llSetStatus(STATUS_PHANTOM, TRUE);
	
	llParticleSystem([]);		// clear any particles
	
	g_health = g_MAX_HEALTH;
	UpdateHealthBar();
	
	g_lhGlobal = llListen(g_CHANNEL_GLOBAL, "Battle Tactics Game v1", NULL_KEY, "");
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
	
	UpdateHealthBar();
}


// Updates the health bar above the class
UpdateHealthBar()
{
	string text = "(" + (string)g_health + "%) ";
	
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
	llParticleSystem(g_PSYS_EXPLOSION);
	
	integer i;
	for (i=0; i<3; i++)		// lol <3
	{
		llTriggerSound(g_SND_EXPLODE, 1.0);
		llSleep(1.5);
	}
	
	llParticleSystem([]);		// clear particles
	
	llListenRemove(g_lhGlobal);
	
	llDie();		// kill the object
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
		// if message isn't from an object owned by the owner
		if (llGetOwnerKey(id) != g_OWNER)
		{
			return;		// exit event
		}
		
		if (channel == g_CHANNEL_GLOBAL)
		{
			if (msg == "kill")
			{
				Destroy();
			}
		}
		
	}
	
}