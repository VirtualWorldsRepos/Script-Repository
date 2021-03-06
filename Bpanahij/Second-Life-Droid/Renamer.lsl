integer handle = 0;

default
{
	state_entry()
	{
		integer sp = llGetStartParameter();
		if(!sp)
		{
			llOwnerSay("Using last known HUD channel: " + llGetObjectDesc() + ".");
			llSetObjectName("DROID" + llGetObjectDesc());
		}
		llListenRemove(handle);
		handle = llListen((integer)llGetObjectDesc()+99,"",NULL_KEY,"RESET");
	}

	on_rez(integer start_param)
	{
		integer sp = llGetStartParameter();
		if(sp)
		{
			llSetObjectName("DROID" + (string) start_param);
			llSetObjectDesc((string) start_param);
		}
		else
		{
			llOwnerSay("Using last known HUD channel: " + llGetObjectDesc() + ".");
			llSetObjectName("DROID" + llGetObjectDesc());
		}
		llListenRemove(handle);
		handle = llListen((integer)llGetObjectDesc()+99, "", NULL_KEY, "RESET");
	}

	changed(integer change)
	{
		if((change & CHANGED_OWNER) || (change & CHANGED_SCALE) || (change & CHANGED_LINK))
		{
			llMessageLinked(LINK_SET, -999, "", NULL_KEY);
		}
	}

	listen(integer chan, string name, key id, string msg)
	{
		if(msg=="RESET")
		{
			llMessageLinked(LINK_SET, -999, "", NULL_KEY);
		}

	}
}