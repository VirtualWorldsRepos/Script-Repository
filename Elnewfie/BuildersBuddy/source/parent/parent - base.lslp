//==============================================================================
// Builders' Buddy 3.0 (Parent Script - Base)
// by Newfie Pendragon, 2006-2013
//==============================================================================
// This script is copyrighted material, and has a few (minor) restrictions.
// Please see https://github.com/elnewfie/builders-buddy/blob/master/LICENSE.md
//
// Builders' Buddy is available at https://github.com/elnewfie/builders-buddy
//==============================================================================

//==============================================================================
// CONFIGURABLE SETTINGS
//==============================================================================
// VAR_BASE_ID:
//   Used to identify this base object to child objects.  Child objects will
//   only respond to base objects that match the name set in their child script.
//==============================================================================
// VAR_BEACON_DELAY:
//   How often, in seconds, to announce to the region that this base object
//   exists.
//==============================================================================
// VAR_BULK_BUILD:
//   Rez all prims before attempting to move into position.  Must be set to "Y"
//   or "N".
//==============================================================================
// VAR_CHANNEL
//   General-use channel to listen on.  Newly-created child objects will attempt
//   to find the base object on this channel.  If changing this value, make
//   sure it is a negative number.
//==============================================================================
// VAR_CLEAN_BEFORE_REZ:
//   If set to "Y", will automatically issue a clean command before rezzing new
//   child objects.  Must be set to "Y" or "N".
//==============================================================================
// VAR_DIE_ON_CLEAN:
//   If set to "Y", will make the base object also delete when choosing "clean"
//   from the menu.  Must be set to "Y" or "N".
//==============================================================================
// VAR_RANDOMIZE_CHANNEL:
//   Calculate a random channel number to use when communicating with child
//   objects.  The channel number is randomized when the base object is rezzed
//   or whenever the Base script is reset. Set to one of:
//     "Y" - Randomize channel
//     "N" - Use main channel as defined in VAR_CHANNEL
//==============================================================================
// VAR_REZ_TIMEOUT:
//   How long to wait, in seconds, before assuming rezzing of a child object
//   failed.  If child object has not locked on by this time, the Base object
//   will attempt to rez it again.
//==============================================================================
// VAR_TIMER_DELAY:
//   Amount of time, in floating seconds, between ticks of the timer.  Lower
//   numbers will make things more responsive, but causes higher region lag.
//==============================================================================
initialize() {        //DO NOT TOUCH THIS LINE!
    set(VAR_BASE_ID, "bb3_base");
    set(VAR_BEACON_DELAY, "30");
    set(VAR_BULK_BUILD, "Y");
	set(VAR_CHANNEL, "-192567");
    set(VAR_CLEAN_BEFORE_REZ, "Y");
	set(VAR_DIE_ON_CLEAN, "N");
	set(VAR_RANDOMIZE_CHANNEL, "Y");
    set(VAR_REZ_TIMEOUT, "10");
    set(VAR_TIMER_DELAY, "0.25");
}                    //DO NOT TOUCH THIS LINE!

//==============================================================================
// DO NOT EDIT ANYTHING BELOW THIS LINE!!!
//==============================================================================

//==============================================================================
//Base variables
//==============================================================================
integer beacon_timeout = 0;
integer is_rezzing = FALSE;
vector last_pos;
rotation last_rot;
integer rez_index = 0;
string rez_match = "";
string rez_name = "";
string rez_prefix = "";
string rez_postfix = "";
integer rez_single = FALSE;
integer rez_timeout = 0;
key rez_user = NULL_KEY;

$import common.constants.lslm;
$import storage.core.lslm;
$import common.comm.core.lslm;
$import module.group.core.lslm;
$import base.constants.lslm;
$import base.core.lslm;

//==============================================================================
// Base Functions
//==============================================================================

////////////////////
announce_config(string child, integer channel) {
	send_child_channel(child, channel, "base_prim", [child_channel, llGetPos(), llGetRot()]);
}

////////////////////
clean_all(key user)
{
	clean_some(user, "", "");
	
	//Self-destruct?
	if(is_yes(VAR_DIE_ON_CLEAN, "N")) {
		//Only if non-full-user (we presume they want to keep us)
		request_event("die_on_clean", [user]);
	}
}

////////////////////
clean_some(key user, string type, string match)
{
	send_child(ALL_CHILDREN, "clean", [type, match]);
}

////////////////////
do_event(string event_name, key event_user, integer event_permitted, list event_details)
{
	//We are only interested in the events that were approved
	if(!event_permitted) return;
	
	if(event_name == "die_on_clean") {
		llDie();
		return;
	}
	
	if(event_name == "build") {
		debug(DEBUG, "Rezzing all objects");
		rez_all(event_user);
		return;		
	}
	
	if(event_name == "clean") {
		clean_all(event_user);
		return;
	}
}

////////////////////
move(integer single)
{
	move_child(ALL_CHILDREN, child_channel, single);
	return;
}

////////////////////
move_child(key id, integer channel, integer single) {
	string command = "move";
	if(single) command = "movesingle";
	
    last_pos = llGetPos();
    last_rot = llGetRot();
    send_child_channel(id, channel, command, [last_pos, last_rot]);
    return;
}

////////////////////
rez_all(key user)
{
	if(is_yes(VAR_CLEAN_BEFORE_REZ, "N")) clean_all(user);
	rez_some(user, FALSE, "", "", "");
}

////////////////////
rez_done()
{
	//One last nudge, just to make sure
	move(rez_single);
	
	//We are done building
    send(BASE, ALL_MODULES, "rez_done", []);
    rez_timeout = 0;
	rez_index = 0;
	is_rezzing = FALSE;
}

////////////////////
rez_object(integer is_rerez)
{
	debugl(DEBUG, ["parent_base.rez_object()", "is_rerez: " + (string)is_rerez, "user: " + (string)rez_user, "rez_single: " + (string)rez_single, "rez_prefix: " + rez_prefix, "rez_match: " + rez_match, "rez_postfix: " + rez_postfix, "rez_name: " + rez_name]);

	//Rezzing multiple items?
	if(!rez_single) {
    	//Rez the object indicated by rez_index
    	rez_name = "";
    	integer retry = TRUE;
			
    	while(retry) {
			if(rez_match != "") {
				string test = llGetInventoryName(INVENTORY_OBJECT, rez_index);
				debug(DEBUG, "Test object: " + test);
				if(is_group_match(rez_prefix, rez_match, rez_postfix, test)) {
					debug(DEBUG, "Matched group name");
					rez_name = test;
					retry = FALSE;
				} else {
					--rez_index;
					if(rez_index < 0) retry = FALSE;
				}
			} else {
				rez_name = llGetInventoryName(INVENTORY_OBJECT, rez_index);
				retry = FALSE;
			}
    	}
	}
	
	if(rez_name != "") {
		debug(DEBUG, "Rezzing " + rez_name + ", retry: " + (string)is_rerez);
		send_manager("rezzing", [rez_name, is_rerez]);
    	llRezObject(
    		rez_name, 
    		llGetPos(), 
    		ZERO_VECTOR, 
    		llGetRot(), 
    		(integer)get(VAR_CHANNEL, "-1")
    	);
    	
    	rez_timeout = llGetUnixTime() + (integer)get(VAR_REZ_TIMEOUT, "5");
        is_rezzing = TRUE;
        
	} else {
		//No more matches, so consider ourselves done
		rez_done();
	}
}

////////////////////
rez_some(key user, integer single, string prefix, string name, string postfix)
{
	debugl(DEBUG, ["parent_base.rez_some()", "single: " + (string)single, "prefix: " + prefix, "name: " + name, "postfix: " + postfix]);
	rez_user = user;
	rez_single = single;
	rez_prefix = "";
	rez_match = "";
	rez_postfix = "";
	rez_name = "";
	
	//Are we performing a fast (bulk) build?
	if(!is_yes(VAR_BULK_BUILD, "N")) {
		start_listening_child();
	}
	
	if(single) {
		rez_name = name;
		rez_index = 0;
		 
	} else {
		rez_prefix = prefix;
		rez_match = name;
		rez_postfix = postfix;
		rez_index = llGetInventoryNumber(INVENTORY_OBJECT) - 1;
	}
	
	rez_object(FALSE);
}

////////////////////
set_channel()
{
	base_channel = (integer)get(VAR_CHANNEL, "-1000001");	//Set it as configured
	debug(DEBUG, "Using configured channel " + (string)child_channel);
	
	child_channel = 0;
    if(is_yes(VAR_RANDOMIZE_CHANNEL, "N")) {
    	integer INT_MAX = 2147483647;
    	child_channel = llFloor(llFrand(INT_MAX)) * -1;	//Make it a negative channel
    	debug(DEBUG, "Using randomized channel " + (string)child_channel);
    }
}

////////////////////
start_listening_child()
{
	if(base_handle == 0) {
		base_handle = llListen(base_channel, "", NULL_KEY, "");
	}
	
	if(child_handle == 0) {
    	child_handle = llListen(child_channel, "", NULL_KEY, "");
	}
    
    send(BASE, ALL_MODULES, "listening_child", [base_channel, child_channel]);
}

////////////////////
stop_listening_child()
{
	if(base_handle != 0) llListenRemove(base_handle);
	if(child_handle != 0) llListenRemove(child_handle);

	base_handle = 0;
	child_handle = 0;
	
	send(BASE, ALL_MODULES, "not_listening_child", []);
	return;
}

////////////////////
////////////////////
////////////////////
default
{
	////////////////////
	state_entry()
	{
		initialize();
		
		//Prep our listening channel
	    set_channel();
	    
	    //Generate an ID?
	    if(get(VAR_BASE_ID, "") == "") {
	    	string baseID = generate_base_id();
	    	set(VAR_BASE_ID, baseID);
	    }
	    
		
		send_manager("base_reset", []);
		
		//Start up beacon broadcast?
	    if(is_yes(VAR_USE_BEACON, "N")) {
	    	beacon_timeout = 1;	//Will cause immediate shout
	    }
	    
		last_pos = llGetPos();
	    last_rot = llGetRot();
	    llSetTimerEvent((float)get(VAR_TIMER_DELAY, "0.5"));
	    start_listening_child();
	    
	    announce_config(ALL_CHILDREN, base_channel);
	    
	    llOwnerSay("Builder's Buddy " + BB_VERSION + " by Newfie Pendragon - ready!");
	    llOwnerSay("Memory free: " + (string)llGetFreeMemory());
	}

	////////////////////
    link_message(integer sender, integer number, string message, key id)
    {
    	debugl(TRACE, ["base.link_message()", "message: " + message, "id: " + (string)id]);
    	//Was it for us?
    	if(!parse([BASE], number, message, id)) return;
    	
    	//We only listen to our manager module
    	debugl(TRACE, ["base.link_message()", "msg_module: " + msg_module]);
    	if(msg_module != MANAGER) return;

		if(msg_command == "do_event") {
			//Our manager's response to an event request.
			//Details: event_name|true_false|details...
			string event_name = llList2String(msg_details, 0);
			key event_user = (key)llList2String(msg_details, 1);
			integer permitted = llList2Integer(msg_details, 2);
			list event_detail = llList2List(msg_details, 3, -1);
			do_event(event_name, event_user, permitted, event_detail);
			
			return;
		}
		
	    if(msg_command == "send_child")
	    {
	    	string child_command = llList2String(msg_details, 0);
	    	list child_details = llList2List(msg_details, 1, -1);
	    	send_child(ALL_CHILDREN, child_command, child_details);
	    	return;
	    }
	    
	    if(msg_command == "mod_say")
	    {
	    	send_child(ALL_CHILDREN, "mod_say", msg_details);
	    	return;
	    }
	    	
	    if(msg_command == "rez") {
	    	//Were we passed criteria to match?
	    	if(llGetListLength(msg_details) == 1) {
	    		//Rez everything
	    		rez_all(llList2Key(msg_details, 0));
	    	
	    	} else if(llGetListLength(msg_details) == 2) {
	    		//Rezzing single item by name
	    		rez_some(
	    			llList2Key(msg_details, 0),			//User
	    			TRUE,								//Single item
	    			"",
	    			llList2String(msg_details, 1),		//Object Name
	    			""
	    		);
	    		
	    	} else if(llGetListLength(msg_details) == 4) {
	    		rez_some(
	    			llList2Key(msg_details, 0),			//User
	    			FALSE,								//Multiple items
	    			llList2String(msg_details, 1),		//Prefix
	    			llList2String(msg_details, 2),		//Group
	    			llList2String(msg_details, 3)		//Postfix
	    		);
	    	}
	    	return;
	    }
	
	    if(msg_command == "clean") {
	    	//Were we passed criteria to match?
	    	key user = (key)llList2String(msg_details, 0);
	    	if(llGetListLength(msg_details) == 1) {
	    		//Clean everything
	    		clean_all(user);
	    		
	    	} else {
	    		//Cleaning based on object name
	    		clean_some(
	    			user,
	    			llList2String(msg_details, 1),
	    			llList2String(msg_details, 2)
	    		);
	    	}
	    	return;
	    }
	    
	    if(msg_command == "move_base") {
	    	move(FALSE);
	    	return;
	    }
	    
		if(msg_command == "reset") {
	        //Are we allowing resets?
	        llResetScript();
	        return;
	    }
	    
	    if(msg_command == "record") {
	    	//Ask the child script to record the supplied position
	    	send_child(ALL_CHILDREN, "record", msg_details);
	    	return;
	    }
	    
	    if(msg_command == "clear") {
	    	//Ask the child objects to forget their positions
	    	send_child(ALL_CHILDREN, "clear", []);
	    	return;
	    }
	    
	    if(msg_command == "manager_ready") {
	    	llOwnerSay("Manager module active, memory: " + llList2String(msg_details, 0));
	    	return;
	    }
	    
    }

    //////////    
    listen(integer channel, string name, key id, string message) {
    	//A message for us?
    	if(parse_listen(channel, name, id, message)) {
    		debug(DEBUG, "Message for base");
    		if(msg_command == "ready_to_pos") {
    			//A child object looking for a parent, tell them of our settings
    			debug(DEBUG, "Child object looking for parent, responding...");
    			announce_config(ALL_CHILDREN, channel);
    		}
    	}
    }

    //////////
    object_rez(key id) {
		//Object has rezzed
		debugl(DEBUG, ["Object rezzed", "id: " + (string)id, "name: " + rez_name]);
		send(BASE, ALL_MODULES, "rezzed", [id, rez_name]);
	
	    //Rezzing it all before moving?
	    if(is_yes(VAR_BULK_BUILD, "N")) {
	        //Move on to the next object
	        //Loop through backwards (safety precaution in case of inventory change)
	        --rez_index;
	        if(rez_index >= 0) {
	            //Attempt to rez it
	            rez_object(FALSE);
	
	        } else {
	            //Rezzing complete, now positioning
	            move(FALSE);
	            move_child(ALL_CHILDREN, base_channel, FALSE);
	            send(BASE, ALL_MODULES, "rez_done", []);
	            rez_timeout = 0;
	            is_rezzing = FALSE;
	            rez_single = FALSE;
	            rez_name = "";
	        }
		}
	}
	
	////////////////////
	on_rez(integer start_param) {
		//Check the channel #
		set_channel();
		
		//Refresh our listener?
		if(child_handle != 0) {
			stop_listening_child();
			start_listening_child();
		}
	}
		
	////////////////////
	timer()
	{
		integer the_time = llGetUnixTime();
		
		if(beacon_timeout != 0) {
			if(the_time >= beacon_timeout) {
				beacon_timeout = the_time + (integer)get(VAR_BEACON_DELAY, "30.0");
				send_child(ALL_CHILDREN, "ping", []);
			}
		}
		
		if(rez_timeout != 0) {
			if(the_time >= rez_timeout) {
				//Try to rez the object again
				rez_object(TRUE);
			}
		}
		
		if(llGetTime() > (float)get(VAR_TIMER_DELAY, "0.5")) {
			//Check our position
			if((last_pos != llGetPos()) || (last_rot != llGetRot())) {
				move(FALSE);
				llResetTime();
			}
		}
		
	}
}