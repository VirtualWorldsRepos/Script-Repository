//==============================================================================
// Builders' Buddy 3.0 (Child Script - Base)
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
// VAR_CHANNEL
//   General-use channel to listen on.  Newly-created child objects will attempt
//   to find the base object on this channel.  If changing this value, make
//   sure it is a negative number.
//==============================================================================
// VAR_GLOW_ON_IDENTIFY:
//   Will make ths object glow if the user selects "Identify" in the Creator's
//   menu.  Set to "Y" or "N". (Note: as a safety precaution, linked objects 
//   that already have a glow will not be changed.)
//==============================================================================
// VAR_GLOW_TIMEOUT:
//   How long, in seconds, to active the glow, if VAR_GLOW_ON_IDENTIFY is set
//   to "Y".
//==============================================================================
// VAR_MAX_X:
//   The maximum X position that this object will be permitted to move to.
//==============================================================================
// VAR_MAX_Y:
//   The maximum Y position that this object will be permitted to move to.
//==============================================================================
// VAR_MAX_Z:
//   The maximum Z position that this object will be permitted to move to.
//==============================================================================
// VAR_MOVE_ON_REZ:
//   Will attempt to move into position as soon as the child object is rezzed,
//   without waiting for link to parent to complete.  This assumes that the
//   on-rezzed position and rotation match those of the parent object.  Must be
//   set to "Y" or "N".
//==============================================================================
// VAR_MOVE_SAFE:
//   If set to "Y", child object will attempt to move using the safe method,
//   which tries to detect if the object gets stuck on the ground.  This method
//   is more reliable, but slower.  If set to "N", will use the faster method
//   to set the position, but does not perform the check.
//==============================================================================
// VAR_REPARENT_DELAY:
//   How long to wait, in seconds, before assuming the parent object no longer
//   exists if it is not heard.  Child object will attempt to find a new parent
//   to relink to after this time.
//==============================================================================
// VAR_SAY_ON_IDENTIFY:
//   Will make ths object announce its name and positio if the user selects 
//   "Identify" in the Creator's menu.  Set to "Y" or "N".
//==============================================================================
// VAR_TIMER_DELAY:
//   Amount of time, in floating seconds, between ticks of the timer.  Lower
//   numbers will make things more responsive, but causes higher region lag.
//==============================================================================
// VAR_YELL_DELAY:
//   How frequently, in seconds, to announce to the region that this child
//   object is looking for a parent to link to.
//==============================================================================
// VAR_YELL_TIMEOUT:
//   Amount of time, in seconds, before child script assumes no parent is going
//   to respond.  If the child has been rezzed as a part of a "Build" process,
//   will self-delete at this time.  If a non-rezzed objected, child will fall
//   back to the channel in VAR_CHANNEL and seek out a parent there.
//==============================================================================
initialize() {        //DO NOT TOUCH THIS LINE!
    set(VAR_BASE_ID, "bb3_base");
    set(VAR_CHANNEL, "-192567");
    set(VAR_GLOW_ON_IDENTIFY, "Y");
    set(VAR_GLOW_TIMEOUT, "10");
    set(VAR_MAX_X, "256.0");
    set(VAR_MAX_Y, "256.0");
    set(VAR_MAX_Z, "4096.0");
    set(VAR_MOVE_ON_REZ, "Y");
    set(VAR_MOVE_SAFE, "N");
    set(VAR_REPARENT_DELAY, "15.0");
    set(VAR_SAY_ON_IDENTIFY, "N");
    set(VAR_TIMER_DELAY, "0.25");
    set(VAR_YELL_DELAY, "3.0");
	set(VAR_YELL_TIMEOUT, "30.0");
}                    //DO NOT TOUCH THIS LINE!

//==============================================================================
// DO NOT EDIT ANYTHING BELOW THIS LINE!!!
//==============================================================================

$import common.constants.lslm;
$import storage.core.lslm;
$import common.log.lslm;
$import child.constants.lslm;
$import child.core.lslm;

//==============================================================================
//Base variables
//==============================================================================
integer absolute = FALSE;
integer recorded = FALSE;
vector current_offset;
rotation current_rotation;
rotation dest_rotation;
vector dest_position;
string glowables = "";
integer glow_snapshot_count = 0;
integer glow_timeout = 0;
integer is_child = FALSE;
integer need_initial_move = FALSE;
integer need_glow = FALSE;
integer need_move = FALSE;
integer next_yell = 0;
integer need_yell_parent = FALSE;
key parent_key = NULL_KEY;
integer reparent_time = 0;
integer rez_timeout = 0;
integer timer_active = FALSE;
integer moving_single = FALSE;

//==============================================================================
//Base Functions
//==============================================================================

////////////////////
build_glow_snapshot()
{
	debug(DEBUG, "Building glow snapshot");
	
	glowables = "";
	integer num_links = llGetObjectPrimCount(llGetKey());
	integer link = 0;
	
	//Single prim, or linkset?
	if(num_links == 1) {
		//Single prim
		if(!has_glow(0)) glowables = "00";
			
	} else {
		//Do for every link
		for(link = 1; link <= num_links; link++) {
			if(!has_glow(link)) {
				glowables += int_to_hex(link);
			}
		}
	}
	
	need_glow = FALSE;
	check_timer();
	
	debug(TRACE, "Glowables: " + glowables);
}

////////////////////
check_parent() {
	if(parent_key == NULL_KEY) return;

	integer lost_parent = FALSE;	
	//Listen timeout?
	if(llGetUnixTime() > reparent_time) {
		lost_parent = TRUE;
		
	} else {
		//Is it still in the region?
		//We see if we can get the object details, if it fails, parent does not exist
		if(llGetListLength(llGetObjectDetails(parent_key, [OBJECT_OWNER])) == 0) lost_parent = TRUE;
	}
	
	if(lost_parent) {
		debug(TRACE, "Parent link lost");
		send_module(ALL_MODULES, "lost_parent", [parent_key], FALSE);
		parent_key = NULL_KEY;
		parent_channel = (integer)get(VAR_CHANNEL, VAR_CHANNEL_DEFAULT);
		set_yell_parent();
		check_timer();
	} 
}

////////////////////
check_timer() {
	//Determine if we need the timer on
	integer need_timer = FALSE;
	if(need_glow) need_timer = TRUE;
	if(glow_timeout != 0) need_timer = TRUE;
	if(need_move) need_timer = TRUE;
	if(need_yell_parent) need_timer = TRUE;
	if(next_yell != 0) need_timer = TRUE;
	
	//Is it off?
	if(!timer_active) {
		//Turn it on?
		if(need_timer) {
	        llSetTimerEvent((float)get(VAR_TIMER_DELAY, VAR_TIMER_DELAY_DEFAULT));
	        timer_active = TRUE;
		}
		
	} else {
		//Turn it off?
		if(!need_timer) {
			llSetTimerEvent(0.0);
			timer_active = FALSE;
		}
	}
}

////////////////////
integer from_parent(key source_id, string source_base_id, string child_id, integer password)
{
	//Update our timeout?
	if(parent_key != NULL_KEY) {
		if(parent_key == source_id) 
			reparent_time = llGetUnixTime() + (integer)get(VAR_REPARENT_DELAY, VAR_REPARENT_DELAY_DEFAULT);
	}
	
	//Check if we lost our parent link
	check_parent();
	
	//Do we have a parent link?
	if(parent_key == NULL_KEY) {
		//Can we use this one?
		
		//Check the base (must exist and must match ours)
		string base_id = get(VAR_BASE_ID, "");
		if(base_id == "") {
			debug(TRACE, "Potential parent rejected, no base ID in child script");
			return FALSE;
		}
		if(source_base_id != base_id) {
			debugl(TRACE, ["Potential parent rejected, base ID mismatch", "child base id: " + base_id, "source base: " + source_base_id]);
			return FALSE;
		}
		
		//Must have same owner
		if(llGetOwnerKey(source_id) != llGetOwner()) {
			debug(TRACE, "Potential parent rejected, owner mismatch");
			return FALSE;
		}
		
		//Lock on
		parent_key = source_id;
		
		//Set how long to wait before assuming the parent is no longer there
		reparent_time = llGetUnixTime() + (integer)get(VAR_REPARENT_DELAY, VAR_REPARENT_DELAY_DEFAULT);
		
		send_module(ALL_MODULES, "have_parent", [parent_key], FALSE);
		debug(INFO, "Base object " + (string)source_id + " found and locked on.");
	}
	
	//Now make sure it's from our parent
	if(source_id == parent_key) {
		//update our delay (to minimize lag)
		reparent_time = llGetUnixTime() + (integer)get(VAR_REPARENT_DELAY, VAR_REPARENT_DELAY_DEFAULT);
	
		//Passed the parent tests; is it talking to everyone?
		if(child_id == ALL_CHILDREN) return TRUE;
	
		//How about us then?
		if((key)child_id == llGetKey()) return TRUE;
	}
	
	//Not for us
	return FALSE;
}

////////////////////
got_parent_message()
{
	debugl(TRACE, ["child_base.got_parent_message()", "listen_command: " + listen_command]);
	
    if(listen_command == "ping") {
    	send_parent("pong", []);
    	return;
    }    	
	
	if(listen_command == "record") {
		//Record position relative to base prim
		vector base_pos = (vector)llList2String(listen_details, 0);
        rotation base_rotation = (rotation)llList2String(listen_details, 1);
        absolute = (integer)llList2Integer(listen_details, 2);

		if(absolute) {
			//Sim-exact position
	        current_rotation = llGetRot();
	        current_offset = llGetPos();
	        
		} else {
			//Position relative to base
        	current_offset = (llGetPos() - base_pos) / base_rotation;
        	current_rotation = llGetRot() / base_rotation;
		}
            
        recorded = TRUE;

		//Notify modules
		//record offset|rotation|absolute_position|from_base
		send_module(ALL_MODULES, "record", [current_offset, current_rotation, absolute, TRUE], FALSE);
		             
        llOwnerSay("Recorded position.");
        return;
	}
	
	if(listen_command == "record_using") {
		current_offset = (vector)llList2String(listen_details, 0);
		current_rotation = (rotation)llList2String(listen_details, 1);
		absolute = llList2Integer(listen_details, 2);
		recorded = TRUE;
		
        //Notify modules
        send_module(ALL_MODULES, "record", [current_offset, current_rotation, absolute], FALSE);
		return;
	}

	if(listen_command == "clear") {
		//Notify modules
		send_module(ALL_MODULES, "clear", [], FALSE);
		recorded = FALSE;
		return;
	}
    	
	if(listen_command == "clear_scripts") {
		//Notify modules
		send_module(ALL_MODULES, "clear_scripts", [], FALSE);
		llRemoveInventory(llGetScriptName());
		return;
	}

    if( listen_command == "movesingle" )
    {
        //If we haven't gotten this before, position ourselves
	    if(!moving_single) {
            //Record that we are a single-prim move
            moving_single = TRUE;

            //Now move it
    		pre_move_relative(
    			(vector)llList2String(listen_details, 0),
    			(rotation)llList2String(listen_details, 1)
			);
			move();
			
			//Notify modules
			send_module(ALL_MODULES, "move", [dest_position, dest_rotation, TRUE], FALSE);
        }
        return;
    }

	if(listen_command == "move") {
		moving_single = FALSE;
		pre_move_relative(
			(vector)llList2String(listen_details, 0),
			(rotation)llList2String(listen_details, 1)
		);
		return;
	}
	
	if(listen_command == "move_absolute") {
		pre_move(
			(vector)llList2String(listen_details, 0),
			(rotation)llList2String(listen_details, 1)
		);
		return;
	}

	if(listen_command == "clean") {
		send_module(ALL_MODULES, "clean", [], FALSE);
		llDie();
	}
	
	if(listen_command == "mod_say") {
		//Message received from the parent object, meant to be forwarded to modules
		send_module(ALL_MODULES, "mod_say", listen_details, FALSE);
		return;
	}
	
	if(listen_command == "identify") {
		if(is_yes(VAR_SAY_ON_IDENTIFY, "Y")) {
			llOwnerSay("Builder's Buddy, child: \"" + llGetScriptName() + "\" at location: " + (string)llGetPos());
		}
		
		if(is_yes(VAR_GLOW_ON_IDENTIFY, "N")) {
			if(need_glow) build_glow_snapshot();
			set_glow(1.0);
			glow_timeout = llGetUnixTime() + (integer)get(VAR_GLOW_TIMEOUT, VAR_GLOW_TIMEOUT_DEFAULT);
			
			check_timer();
		}
		return;
	}
	
	if(listen_command == "base_prim") {
		debug(INFO, "Parent configuration received");
		
		//Parent prim letting us know its configuration info
		string channel = llList2String(listen_details, 0);
		if((channel != "") && (channel != "")) {
			debug(DEBUG, "Listening to parent object on channel " + channel);
			stop_listening();
			parent_channel = (integer)channel;
			start_listening();
		}
		
		//If we're recorded, also move into position
		if(recorded && need_initial_move) {
			pre_move_relative(
				(vector)llList2String(listen_details, 1),
				(rotation)llList2String(listen_details, 2)
			);
			need_initial_move = FALSE;
		}
		
		need_yell_parent = FALSE;
		next_yell = 0;
		check_timer();
	}
}

////////////////////
integer has_glow(integer link) {
	integer num_faces = llGetLinkNumberOfSides(link);
	
	//Build a request for the glow settings for all sides
	integer face = 0;
	list params = [];
	for(face = 0; face < num_faces; face++) {
		params += [PRIM_GLOW, face];
	}
	
	//Get the glow settings for each side
	list glows = llGetLinkPrimitiveParams(link, params);
	
	//See if any of the sides has glow set
	//Scan the list, and record the non-zero faces
	integer num_glows = llGetListLength(glows);
	for(face = 0; face < num_faces; face++) {
		float glow_value = llList2Float(glows, face);
		if(glow_value != 0.0) {
			return TRUE;
		}
	}
	
	return FALSE;
}

////////////////////
string int_to_hex(integer int_value) {
    string  hex;
    do{
        hex = llGetSubString("0123456789ABCDEF", int_value & 0x0000000F, int_value & 0x0000000F ) + hex;
    } while (int_value = int_value >> 4 & 0x0FFFFFFF);
    
    if(llStringLength(hex) == 1) hex = "0" + hex;
    return hex;
}


////////////////////
hop(vector destination, rotation rot)
{
    integer hops = llAbs(llCeil(llVecDist(llGetPos(), destination) / 10.0));
    integer x;
    while(hops > 0) {
	    list params = [];
    	integer hopBlock = hops;
    	if(hopBlock > 50) hopBlock = 50;
	    for( x = 0; x < hopBlock; x++ ) {
	        params += [ PRIM_POSITION, destination ];
	    }
	    params += [ PRIM_ROTATION, rot ];
	    llSetPrimitiveParams(params);
	    hops -= hopBlock;
    }
}

////////////////////
move()
{
	if(is_yes(VAR_MOVE_SAFE, "N")) {
		//Use the older, more reliable/compatible version
		move_safe();
		
	} else {
		//Use the really fast call
		llSetRegionPos(dest_position);
		llSetRot(dest_rotation);
	}

	//Notify our modules	
	send_module(ALL_MODULES, "at_destination", [dest_position, dest_rotation], FALSE);

    need_move = FALSE;
    check_timer();
}

////////////////////
move_safe()
{
    integer i = 0;
    integer atDestination = FALSE;
    
    vector vLastPos = ZERO_VECTOR;
    do {

        //We may be stuck on the ground...
        //Did we move at all compared to last loop?
        if( llGetPos() == vLastPos ) {
            //Yep, stuck...move straight up 500m (attempt to dislodge)
            hop(llGetPos() + <0.0, 0.0, 500.0>, dest_rotation);
        }

        //Try to move to destination
        hop(dest_position, dest_rotation);
        vLastPos = llGetPos();
        i++;
    
    } while((i < 5) && (llGetPos() != dest_position));
	llSetRot(dest_rotation);
}

////////////////////
pre_move(vector new_position, rotation new_rotation)
{
    //Make sure our calculated position is within the sim
    float max_x = (float)get(VAR_MAX_X, VAR_MAX_X_DEFAULT);
    if(new_position.x < 0.0) new_position.x = 0.0;
    if(new_position.x >= max_x) new_position.x = max_x;
    
    float max_y = (float)get(VAR_MAX_Y, VAR_MAX_Y_DEFAULT);
    if(new_position.y < 0.0) new_position.y = 0.0;
    if(new_position.y > max_y) new_position.y = max_y;
    
    float max_z = (float)get(VAR_MAX_Z, VAR_MAX_Z_DEFAULT);
    if(new_position.z > max_z) new_position.z = max_z;
    
    dest_position = new_position;
    dest_rotation = new_rotation;

	//Notify modules
	send_module(ALL_MODULES, "move", [dest_position, dest_rotation], FALSE);
    
    //Turn on our timer to perform the move?
    if(!need_move)
    {
    	llResetTime();
        need_move = TRUE;
        check_timer();
    }
    return;
}

////////////////////
pre_move_relative(vector new_position, rotation new_rotation)
{
    //Don't move if we've not yet recorded a position
    if( !recorded ) return;

	vector new_dest_position;
	rotation new_dest_rotation;
	    
    //Calculate our destination position relative to base?
    if(!absolute) {
        //Relative position
        
        //Calculate our destination position
        new_dest_position = (current_offset * new_rotation) + new_position;
        new_dest_rotation = current_rotation * new_rotation;
    } else {
        //Sim position
        new_dest_position = current_offset;
        new_dest_rotation = current_rotation;
    }

	pre_move(new_dest_position, new_dest_rotation);
}

////////////////////
send_parent(string command, list options)
{
	if(parent_key == NULL_KEY) {
		debugl(DEBUG, ["child - base.send_parent()", "channel: " + get(VAR_CHANNEL, VAR_CHANNEL_DEFAULT)]);
		
		//No parent, send on the generic channel
		llRegionSay(
			base_channel,
			llDumpList2String([BASE, command] + options, "|")
		);
	} else {
		//Send straight to parent
		debugl(DEBUG, ["child - base.send_parent()", "channel: " + (string)parent_key]);
		llRegionSayTo(
			parent_key,
			parent_channel,
			llDumpList2String([parent_key, command] + options, "|")
		);
	} 
}

////////////////////
set_glow(float glow)
{
	debug(DEBUG, "Setting glow to " + (string)glow);
	
	//Turn off the glow
	integer glowables_length = llStringLength(glowables);
	integer link;
	for(link = 0; link < glowables_length; link += 2) {
		string link_hex = "0x" + llGetSubString(glowables, link, link + 1);
		integer the_link = (integer)link_hex;
		llSetLinkPrimitiveParamsFast(the_link, [PRIM_GLOW, ALL_SIDES, glow]);
	}
	
	glow_timeout = 0;
	
}

////////////////////
yell_parent()
{
	debug(DEBUG, "Yelling for a parent");
	next_yell = llGetUnixTime() + (integer)get(VAR_YELL_DELAY, VAR_YELL_DELAY_DEFAULT);
	send_module(ALL_MODULES, "ready_to_pos", [], FALSE);
	send_parent("ready_to_pos", []);
}

////////////////////
set_yell_parent()
{
	need_yell_parent = TRUE;
	next_yell = llGetUnixTime() + (integer)get(VAR_YELL_DELAY, VAR_YELL_DELAY_DEFAULT);
	check_timer();
}

////////////////////
////////////////////
////////////////////
default
{
	////////////////////
	state_entry() {
    	debug(DEBUG, "====================");
    	debug(DEBUG, "   SCRIPT STARTED");
    	debug(DEBUG, "====================");
    	initialize();
    	need_move = FALSE;
    	
    	//Open a listener automatically
    	start_listening();
    	
    	send_module(ALL_MODULES, "reset", [], TRUE);
    	
    	need_glow = TRUE;
    	set_yell_parent();
    	check_timer();
	    llOwnerSay("Memory free: " + (string)llGetFreeMemory());    	
	}

	////////////////////
	link_message(integer sender_num, integer number, string message, key id) {
		if(parse([MANAGER, ALL_MODULES], number, message, id)) {
			//Let the core handler have a stab at it first
//			if(manager_core_handle_message()) return;
			
			//Done
			return;
		}
	}

	////////////////////
	listen(integer channel, string name, key id, string message) {
		debugl(TRACE, ["Heard:", "channel: " + (string)channel, "name: " + name, "id: " + (string)id, "message: " + message]);
		
		//Try to parse what we heard
		if(parse_listen(channel, name, id, message)) {
			//Is it for us?
			if(from_parent(id, listen_base, listen_target, listen_password)) {
		    	got_parent_message();
		    	return;
			}
		}
    }
	
	////////////////////
	on_rez(integer start_param) {
    	stop_listening();
    	
    	//Were we rezzed as a child object?
    	if(start_param != 0) {
    		//The parameter is a channel that we are to listen to
    		parent_channel = start_param;
    		
    		is_child = TRUE;
    		need_initial_move = TRUE;
			rez_timeout = llGetUnixTime() + (integer)get(VAR_YELL_TIMEOUT, VAR_YELL_TIMEOUT_DEFAULT);
			
    		send_module(ALL_MODULES, "rezzed", [start_param], FALSE);
    		
 			//Can we move immediately into position?
 			if(is_yes(VAR_MOVE_ON_REZ, "N")) {
				moving_single = FALSE;
				pre_move_relative(
					llGetPos(),
					llGetRot()
				);
 			}
 			   		
    	} else {
    		is_child = FALSE;
    	}
    	
		//Yell for momma
		parent_key = NULL_KEY;
		set_yell_parent();
		check_timer();
		
		start_listening();
    }
    
    ////////////////////
	timer()
    {
    	integer now = llGetUnixTime();
    	
    	if(need_yell_parent) {
    		//Give up and die?
    		if(rez_timeout != 0) {
	    		if(now > rez_timeout) {
	    			send_module(ALL_MODULES, "no_parent", [], FALSE);
	    			if(is_child) llDie();
	    			
	    			//Fall back to the generic channel
	    			integer default_channel = (integer)get(VAR_CHANNEL, VAR_CHANNEL_DEFAULT);
	    			if(default_channel != parent_channel) {
	    				debug(DEBUG, "Reverting to default channel");
	    				stop_listening();
	    				parent_channel = default_channel;
	    				start_listening();
	    			}
	    		}
    		}
    			
			//Try again?
			if(now > next_yell) {
				yell_parent();
			}
    	}
    	
        //Do we need to move?
        if(need_move) {
            //Perform the move and clean up
            move();

            //If single-prim move, announce to base we're done
            if(moving_single) {
            	send_parent("at_destination", []);
            }
        }
        
        //Do we need to rebuild our glow settings?
        if(need_glow) build_glow_snapshot();
        
        //Turn off an existing glow?
        if(glow_timeout != 0) {
        	if(now > glow_timeout) {
        		set_glow(0.0);
        		glow_timeout = 0;
        	}
        }
        
        //See if we need to continue
        check_timer();
        
        return;
    }
    
    ////////////////////
    changed(integer change) {
    	if(glow_timeout == 0) {
    		need_glow = TRUE;
    		check_timer();
    	}
    }
}