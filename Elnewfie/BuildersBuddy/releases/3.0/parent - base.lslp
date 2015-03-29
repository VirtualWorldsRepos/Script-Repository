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


//==============================================================================
//General Constants
//==============================================================================
string ALL_CHILDREN = "all";
string ALL_MODULES = "all";
string BASE = "base";
integer BB_API = -11235813;
integer BB_API_REPLY = -11235814;
string BB_VERSION = "3.0"; 
string MANAGER = "manager";
string MODULE = "module";
string TYPE_CHILD = "C";
string TYPE_PARENT = "P";

//==============================================================================
//Storage Variables
//==============================================================================
list values = [];
list vars = [];

//==============================================================================
//Storage Functions
//==============================================================================

////////////////////
string get(string name, string default_value)
{
    integer iFound = llListFindList(vars, [ name ]);
    if(iFound != -1)
        return llList2String(values, iFound);
    
    return default_value;
}

////////////////////
list get_list(string varName, list default_list)
{
    integer iFound = llListFindList(vars, [ varName ]);
    if(iFound != -1) {
        return llParseStringKeepNulls(llList2String(values, iFound), ["|"],  [""]);
    }
    
    return default_list;
}

////////////////////
integer is_yes(string var, string default_value) {
	return (llToUpper(get(var, default_value)) == "Y");
}

////////////////////
set(string name, string value)
{
    //Make the var lowercase
    name = llToLower(name);
    
    //See if we have a var by this name already
    integer iFound = llListFindList(vars, [name]);
    if(iFound != -1) {
        //Replace the existing entry
        values = llListReplaceList(values, [value], iFound, iFound);
    } else {
        //Add it
        vars += name;
        values += value;
    }
}

////////////////////
set_list(string name, list values)
{
	set(name, llDumpList2String(values, "|"));
}


//==============================================================================
//Communication variables
//==============================================================================
string msg_command;
list msg_details;
string msg_module;

//==============================================================================
//Communication functions
//==============================================================================

// message: <source>|<target>|<command>
// id: <details...>
////////////////////
integer parse(list targets, integer number, string message, string id) {
		if(number != BB_API) return FALSE;
		
		list parts = llParseStringKeepNulls((string)id, ["|"], []);
		if(llGetListLength(parts) != 3) return FALSE;
		
		//Check the list of targets and see if it's for one of the ones we're listening for
		integer num_targets = llGetListLength(targets);
		integer i;
		string target = llList2String(parts, 1);
		for(i = 0; i < num_targets; i++) {
			if(llList2String(targets, i) == target) {
				//It's good
				msg_module = llList2String(parts, 0);
				msg_command = llList2String(parts, 2);
				msg_details = llParseStringKeepNulls(message, ["|"], []);
				
				return TRUE;
			}
		}
		
		return FALSE;
}

////////////////////
send(string source, string dest, string command, list details)
{
	
    llMessageLinked(
    	LINK_THIS,
    	BB_API, 
    	llDumpList2String(details, "|"),
    	llDumpList2String([source, dest, command], "|")
    );
}

//==============================================================================
//Group Rezzer Constants
//==============================================================================
string VAR_REMOVE_TAG = "group_remove_tag";
string VAR_PREFIX = "group_prefix";
string VAR_POSTFIX = "group_postfix";

//==============================================================================
//Group Rezzer Core Functions
//==============================================================================

////////////////////
list get_group_names(string text, string prefix, string postfix)
{
	integer end = 0;
	integer start = 1;
	
	//Do we have the prefix at the beginning?
	if(llGetSubString(text, 0, 0) == prefix) {
		//Do we have a subsequent postfix?
		end = llSubStringIndex(text, postfix);
		if(end == -1) return [];	//No match
	
	} else {
		return [];		//No group name
	}
	
	//Group name must be the text in between
	list groups = llParseStringKeepNulls(llGetSubString(text, start, end - 1), [","], []);
	return groups;
}

////////////////////
integer is_group_match(string prefix, string group, string postfix, string name)
{
	
	list group_names = get_group_names(name, prefix, postfix);
	integer i;
	integer group_count = llGetListLength(group_names);
	for(i = 0; i < group_count; i++) {
		if(group == llList2String(group_names, i)) return TRUE;
	}
	
	//If we got here, no match
	return FALSE;
}

////////////////////
string get_base_name(string prefix, string postfix, string name) {
	integer end = 0;
	integer start = 1;
	
	//Do we have the prefix at the beginning?
	if(llGetSubString(name, 0, 0) == prefix) {
		//Do we have a subsequent postfix?
		end = llSubStringIndex(name, postfix);
		if(end == -1) return name;	//No match
	
	} else {
		return name;		//Use full name
	}
	
	//Base name is everything past the postfix
	return llGetSubString(name, end + 1, -1);
}

//==============================================================================
//Constants - Base Functionality
//==============================================================================
string VAR_ALLOW_GROUP = "allow_group";
string VAR_BASE_ID = "base_id";
string VAR_BEACON_DELAY = "beacon_delay";
string VAR_BULK_BUILD = "bulk_build";
string VAR_CHANNEL = "channel";
string VAR_CLEAN_BEFORE_REZ = "clean_before_rez";
string VAR_DIE_ON_CLEAN = "die_on_clean";
string VAR_RANDOMIZE_CHANNEL = "randomize_channel";
string VAR_REZ_TIMEOUT = "rez_timeout";
string VAR_TIMER_DELAY = "timer_delay";
string VAR_USE_BEACON = "use_beacon";

//==============================================================================
//Base core variables
//==============================================================================
integer base_channel;
integer base_handle;
integer child_channel;
integer child_handle;
string listen_base;
integer listen_channel;
key listen_source = NULL_KEY;

//==============================================================================
//Base core functions
//==============================================================================

////////////////////
string generate_base_id()
{
	//Nothing complex here, just make a unique id
	// by combining out UUID, timestamp and MD5'ing it
	string seed = (string)llGetKey() + (string)llGetUnixTime();
	return llMD5String(seed, 100);
}

////////////////////
integer parse_listen(integer channel, string name, key id, string message)
{
	
	listen_channel = channel;
	list parts = llParseStringKeepNulls(message, ["|"], []);
	
	//See if for us
	if(llGetListLength(parts) < 2) return FALSE;
	string target_base = llList2String(parts, 0);
	if((target_base != BASE) && (target_base != (string)llGetKey())) return FALSE;
	
	listen_base = target_base;
	msg_command = llList2String(parts, 1);
	
	msg_details = [];
	if(llGetListLength(parts) > 2)
		msg_details = llList2List(parts, 2, -1);
		
	return TRUE;
}

////////////////////
request_event(string event_name, list details) {
	send_manager("request_event", [event_name] + details);
}

////////////////////
send_child(string child, string command, list details)
{
	integer channel;
	if(child_channel != 0) {
		channel = child_channel;
	} else {
		channel = base_channel;
	}
	
	if(channel == 0) {
		return;
	}

	send_child_channel(child, channel, command, details);	
}

////////////////////
send_child_channel(string child, integer channel, string command, list details) {
	string text = llDumpList2String(
		[get(VAR_BASE_ID, ""), child, command] + details, 
		"|"
	);
	
	if(child == ALL_CHILDREN) {
		//Use general broadcast
		llRegionSay(
			channel, 
			text
		);
	} else {
		//Send to just the child object
		llRegionSayTo(
			(key)child, 
			channel, 
			text
		);
	}
} 

////////////////////
send_manager(string command, list details)
{
	send(BASE, MANAGER, command, details);
}

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

	//Rezzing multiple items?
	if(!rez_single) {
    	//Rez the object indicated by rez_index
    	rez_name = "";
    	integer retry = TRUE;
			
    	while(retry) {
			if(rez_match != "") {
				string test = llGetInventoryName(INVENTORY_OBJECT, rez_index);
				if(is_group_match(rez_prefix, rez_match, rez_postfix, test)) {
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
	
	child_channel = 0;
    if(is_yes(VAR_RANDOMIZE_CHANNEL, "N")) {
    	integer INT_MAX = 2147483647;
    	child_channel = llFloor(llFrand(INT_MAX)) * -1;	//Make it a negative channel
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
    	//Was it for us?
    	if(!parse([BASE], number, message, id)) return;
    	
    	//We only listen to our manager module
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
    		if(msg_command == "ready_to_pos") {
    			//A child object looking for a parent, tell them of our settings
    			announce_config(ALL_CHILDREN, channel);
    		}
    	}
    }

    //////////
    object_rez(key id) {
		//Object has rezzed
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