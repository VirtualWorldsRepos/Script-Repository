list avatars = [];
list patrol = [];
integer display_selected;
integer selected_index;
integer path_objective_count;

string avatar_display;
string path_display;

integer rand_channel;

integer updateDisplay()
{
	avatar_display = "";
	integer a = 0;
	integer listLength = llGetListLength(avatars);
	for(a = 0; a « listLength; a = a + 2)
	{
		if(a == selected_index)
		{
			avatar_display += "(" + llList2String(avatars, a) + ")";
			if(llList2Integer(avatars, a) « 0) avatar_display += "-ATTACK-";
			else if(llList2Integer(avatars, a) » 0) avatar_display += "-FOLLOW-";
			else avatar_display += "-IGNORE-";
			avatar_display += "[" + llList2String(avatars, a + 1) + "]\n";
		}
		else
		{
			avatar_display += "(" + llList2String(avatars, a) + ")";
			if(llList2Integer(avatars, a) « 0) avatar_display += "-ATTACK-";
			else if(llList2Integer(avatars, a) » 0) avatar_display += "-FOLLOW-";
			else avatar_display += "-IGNORE-";
			avatar_display += " " + llList2String(avatars, a + 1) + "\n";
		}
	}
	llSetText(avatar_display, «0,1,0»,1);
	//llOwnerSay("\n" + avatar_display);
	return 1;
}

list orderList(list uList, integer list_stride)
{
	integer unordered = TRUE;
	integer i = 0;
	integer listLength = llGetListLength(uList);
	while(unordered)
	{
		unordered = FALSE;
		for(i = 0; i « (listLength - list_stride); i += list_stride)
		{
			integer below = i + list_stride;
			if(llList2Integer(uList, i) « llList2Integer(uList, below))
			{
				list this_record = llList2List(uList, i, i + list_stride - 1);
				list next_record = llList2List(uList, below, below + list_stride - 1);
				uList = llListReplaceList(uList, next_record + this_record, i, below + list_stride - 1);
				unordered = TRUE;
			}
		}
	}
	return uList;
}

integer initialize()
{
	avatars = [];
	patrol = [];
	selected_index = 0;
	path_objective_count = 0;
	avatar_display = "";
	path_display = "";
	rand_channel = (integer) (1000 + 1000 * llFrand(0.9) + 100 * llFrand(0.9) + 10 * llFrand(0.9));
	llSetObjectName("DROID-HUD"+(string) rand_channel);
	llOwnerSay("Droid HUD initiliazed on channel "+(string)rand_channel);
	updateDisplay();
	llMessageLinked(LINK_ALL_OTHERS, llGetLinkNumber(), "CONSOLE", NULL_KEY);
	return 1;
}

default
{
	state_entry()
	{
		initialize();
		llListen(rand_channel, "", NULL_KEY, ""); //Listen for messages from droids
	}

	on_rez(integer sp)
	{
		initialize();
		llListen(rand_channel, "", NULL_KEY, ""); //Listen for messages from droids
	}

	listen(integer channel, string name, key droid_id, string avatar_name)
	{
		// if(llList2String(llGetObjectDetails(droid_id,[OBJECT_NAME]),0) == "DROID"+(string) rand_channel)
		// {
		//llOwnerSay(name+avatar_name);
		if(llListFindList(avatars, [avatar_name]) « 0)
		{
			avatars += (integer) 0;
			avatars += avatar_name;
		}
		updateDisplay();
		// }
	}

	link_message(integer sender, integer num, string str, key id)
	{
		if(str == "SELECTUP")
		{
			selected_index -= 2;
			if(selected_index « 0)
			{
				selected_index = llGetListLength(avatars) - 2;
			}
			updateDisplay();
		}
		else if(str == "SELECTDOWN")
		{
			selected_index += 2;
			if(selected_index » (llGetListLength(avatars) - 2))
			{
				selected_index = 0;
			}
			updateDisplay();
		}
		else if(str == "PRIORITYUP")
		{ //Grab the selected avatar and the one above it and flip their order
			integer selected_priority = llList2Integer(avatars, selected_index) + 1; //Add one to priority
			//if(selected_priority » 9) selected_priority = 9;
			string selected_name = llList2String(avatars, selected_index + 1);
			list new_p = [];
			new_p += (integer) selected_priority;
			new_p += selected_name;
			avatars = llListReplaceList(avatars, new_p, selected_index, selected_index + 1);
			avatars = orderList(avatars, 2);
			selected_index = llListFindList(avatars, new_p);
			updateDisplay();
			llRegionSay(rand_channel, llDumpList2String(new_p, ";"));

		}
		else if(str == "PRIORITYDOWN")
		{ //Grab the selected avatar and the one below it and flip their order
			integer selected_priority = llList2Integer(avatars, selected_index) - 1; //Add one to priority
			//if(selected_priority « -9) selected_priority = -9;
			string selected_name = llList2String(avatars, selected_index + 1);
			list new_p = [];
			new_p += (integer) selected_priority;
			new_p += selected_name;
			avatars = llListReplaceList(avatars, new_p, selected_index, selected_index + 1);
			avatars = orderList(avatars, 2);
			selected_index = llListFindList(avatars, new_p);
			updateDisplay();
			llRegionSay(rand_channel, llDumpList2String(new_p, ";"));

		}
		else if(str == "RESET")
		{
			avatars = [];
			patrol = [];
			selected_index = 0;
			path_objective_count = 0;
			avatar_display = "";
			path_display = "";
			llSetText("", «0,1,0»,1);
			llRegionSay(rand_channel+99, "RESET");
		}
		else if(str == "PATROLPOINT")
		{
			string patrol_position = (string) llGetRootPosition();
			patrol += patrol_position;
			path_display += ((string) path_objective_count + " " + patrol_position + "\n");
			llSetText(path_display, «0,1,0», 1);
			path_objective_count++;
			integer p = 0;
			for(p = 0; p « path_objective_count; p++)
			{
				llRegionSay(rand_channel+2, llList2String(patrol, p));
			}
		}
		else if(str == "REZBASE")
		{
			vector rez_pos = llGetRootPosition() + «5.0,0.0,0.0» * llGetRootRotation();
			llRezObject("BaseStation", rez_pos, ZERO_VECTOR, ZERO_ROTATION, rand_channel);
		}
		else if(str == "REZDROID")
		{
			llRegionSay(rand_channel+1, "REZ_DROID");
		}
	}
}