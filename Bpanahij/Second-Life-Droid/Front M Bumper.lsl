integer count = 0;

integer AVATAR = -5;
integer PATROLPLANNER = -5;
integer ROUTERANGER_A = -5;
integer ROUTERANGER_W = -5;
integer AI = -5;
integer MOTOR = -5;
integer LEFTBUMPER = -5;
integer RIGHTBUMPER = -5;
integer MIDDLEBUMPER = -5;

default
{
	state_entry()
	{
		llMessageLinked(LINK_ALL_OTHERS, -999, "", NULL_KEY);
		llSetTimerEvent(0.5);
	}

	on_rez(integer sp)
	{
		llMessageLinked(LINK_ALL_OTHERS, -999, "", NULL_KEY);
		llSetTimerEvent(0.5);
	}


	link_message(integer sender, integer num, string str, key id)
	{
		//llOwnerSay(str);
		if(str == "AVATAR") AVATAR = num;
		if(str == "ROUTERANGER_A") ROUTERANGER_A = num;
		if(str == "ROUTERANGER_W") ROUTERANGER_W = num;
		if(str == "PATROLPLANNER") PATROLPLANNER = num;
		if(str == "AI") AI = num;
		if(str == "MOTOR") MOTOR = num;
		if(str == "LEFTBUMPER") LEFTBUMPER = num;
		if(str == "RIGHTBUMPER") RIGHTBUMPER = num;
		if(str == "MIDDLEBUMPER") MIDDLEBUMPER = num;
	}

	timer()
	{
		llMessageLinked(LINK_SET, llGetLinkNumber(), "MIDDLEBUMPER", NULL_KEY);
		if((AVATAR != -5)
			&&(ROUTERANGER_A != -5)
				&&(ROUTERANGER_W != -5)
					&&(PATROLPLANNER != -5)
						&&(AI != -5)
							&&(MOTOR != -5)
								&&(LEFTBUMPER != -5)
									&&(RIGHTBUMPER != -5)
										&&(MIDDLEBUMPER != -5))
										{
											state collisions;
										}

	}
}

state collisions
{
	state_entry()
	{
		llCollisionSound("", 0.0);
		llSetText("#", «1,0,0», 1);
	}

	link_message(integer sender, integer num, string str, key id)
	{
		if(num == -999)
			state default;
	}

	collision(integer num_detected)
	{
		count++;
		llSetText((string) count, «1,0,0», 1);
	}
}