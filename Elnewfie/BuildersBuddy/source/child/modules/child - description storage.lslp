$import common.constants.lslm;
$import common.log.lslm;
$import storage.core.lslm;
$import module.constants.lslm;
$import module.core.lslm;

//==============================================================================
// CONFIGURABLE SETTINGS
//==============================================================================
// mod_type:
//   Indicates if this module should link to the parent or component scripts.  
//   Set to one of:
//     CORE_TYPE_PARENT - Module intended for use in the parent prim
//     CORE_TYPE_CHILD - Module intended for use in the child prims;
//==============================================================================
// menu_type:
//   The type of button to be added to the menu.  Set to one of:
//   MOD_MENU_TYPE_ADMIN - Button is seen only by administrators/creators
//   MOD_MENU_TYPE_EVERYONE - Button is seen by everyone
//   MOD_MENU_TYPE_NONE - No button will be shown.     
//==============================================================================
// mod_name:
//   The name of the module.  If menu_type is set to MOD_MENU_TYPE_ADMIN
//   or MOD_MENU_TYPE_EVERYONE, this will be used as the label on the button.    
//==============================================================================
// mod_menu_desc:
//   Description of the module. Will be included in the text of the menu when
//   the module's button is display.    
//==============================================================================
// mod_events:
//   Events that this module wishes to review and possibly cancel.  These can
//   only be events that are explicitly available as cancellable in the base or
//   component script.  This should be set as a list using setList();
//==============================================================================
initialize() {        //DO NOT TOUCH THIS LINE!
	//Basic module information
	set("mod_type", TYPE_CHILD);
	set("mod_name", "Description Storage");
	
	//Menu button configuration
	set("mod_menu_type", MENU_TYPE_NONE);
	set("mod_menu_desc", "Store object's location in Description");
	
	//Events this module is interested in
	set_list("mod_events", ["record", "forget"]);

	//Add module-specific variables here	
	
	
}                    //DO NOT TOUCH THIS LINE!

clean_description() {
	string desc = llGetObjectDesc();
	
	//Find the start of our data block
	integer start = llSubStringIndex(desc, "BB3");
	if(start != -1) {
		string block = llGetSubString(desc, start + 3, -1);
		integer iEnd = llSubStringIndex(block, "3BB");
		if(iEnd != -1) {
			string new_desc = "";
			
			if(start >= 3) new_desc = llGetSubString(desc, 0, start - 1);
				
			string tail = llGetSubString(block, iEnd, -1);
			if(tail != "3BB") new_desc += llGetSubString(tail, 3, -1);
			
			llSetObjectDesc(new_desc);
		}
	}
}

//floatToString and stringToFloat (suif and fuis) courtesy of Strife Onizuka
//float union to base64ed integer
string floatToString(float a){
    if(a) {
        integer b = (a < 0) << 31;
        if((a = llFabs(a)) < 2.3509887016445750159374730744445e-38) {
            b = b | (integer)(a / 1.4012984643248170709237295832899e-45);
            
        } else {
            integer c = llFloor(llLog(a) / 0.69314718055994530941723212145818);
            b = (0x7FFFFF & (integer)(a * (0x1000000 >> b))) | (((c + 126 + (b = ((integer)a - (3 <= (a /= (float)("0x1p"+(string)(c -= (c == 128)))))))) << 23 ) | b);
        }
        return llGetSubString(llIntegerToBase64(b),0,5);
    }
    
    if((string)a == (string)(0.0))
        return "AAAAAA";
    return "gAAAAA";
}

got_message()
{
	debugl(TRACE, ["creator.got_message()", "msg_command: " + msg_command, "msg_details: " + llDumpList2String(msg_details, "|")]);

	// BUILDER'S BUDDY - Add your code here
	if(msg_command == "record") {
		//Make sure it was the parent object that requested this
		vector vOffset = (vector)llList2String(msg_details, 0);
		rotation rRotation = (rotation)llList2String(msg_details, 1);
		integer bAbsolute = llList2Integer(msg_details, 2);
		integer from_base = llList2Integer(msg_details, 3);
		if(from_base) {
			debugl(DEBUG, ["Recording to object description:", "offset: " + (string)vOffset, "rotation: " + (string)rRotation, "absolute: " + (string)bAbsolute]);
			saveToDescription(vOffset, rRotation, bAbsolute);
		}
		return;
	}
	
	if(msg_command == "clear") {
		//Remove the location from the object description
		clean_description();
		return;
	}
	
	if(msg_command == "clear_scripts") {
		//Locking down object, remove the location data
		clean_description();
		llRemoveInventory(llGetScriptName());
		return;
	}
	
	if(msg_command == "register") {
		//We are registered, attempt to load the saved position
		load_description();
		return;
	}
	
}

//==============================================================================
//BUILDER'S BUDDY MODULE CODE - DO NOT REMOVE
// This is called when the module has received a cancellable request.  This
// must return TRUE to cancel the event, or FALSE to allow it to continue.
// Unless your module has a specific need to stop the event from happening, this
// should normally return FALSE.
//
//Only cancellable events listed in mod_events will be seen here.
//==============================================================================
integer got_request()
{
	debugl(TRACE, ["creator.got_request()", "msg_command: " + msg_command, "msg_details: " + llDumpList2String(msg_details, "|")]);
	
	//Default action is to allow
	return FALSE;
}

load_description() {
	string desc = llGetObjectDesc();
	vector vOffset;
	rotation rRotation;
	integer bAbsolute = FALSE;
	
	//Find the start of our data block
	integer start = llSubStringIndex(desc, "BB3");
	if(start != -1) {
		string block = llGetSubString(desc, start + 3, -1);
		integer iEnd = llSubStringIndex(block, "3BB");
		if(iEnd != -1) {
			debug(DEBUG, "Retrieving recorded position from description");
			string data = llGetSubString(block, 0, iEnd - 1);
			
			//Now parse it into our pieces
			list lData = llParseStringKeepNulls(data, [","], []);
			
			rRotation = <
				stringToFloat(llList2String(lData, 0)),
				stringToFloat(llList2String(lData, 1)),
				stringToFloat(llList2String(lData, 2)),
				stringToFloat(llList2String(lData, 3))
			>;
			
			vOffset = <
				stringToFloat(llList2String(lData, 4)),
				stringToFloat(llList2String(lData, 5)),
				stringToFloat(llList2String(lData, 6))
			>;
			
			bAbsolute = llList2Integer(lData, 7);
			
			debugl(TRACE, ["Location Info:", "Position: " + (string)vOffset,  "Rotation: " + (string)rRotation, "Absolute: " + (string)bAbsolute]);
			send_manager("record_using", [vOffset, rRotation, bAbsolute]);
			
			return;
		}
	}
	
	debug(DEBUG, "No description data found.");
}

//==============================================================================
//BUILDER'S BUDDY MODULE CODE - DO NOT REMOVE
//==============================================================================
parse_message() {
	debugl(TRACE, ["parse_message()", "msg_command: " + msg_command, "msg_details: " + llDumpList2String(msg_details, "|")]);

	//A message, or an event?
	if(msg_command == "request_event") {
		msg_command = llList2String(msg_details, 0);
		msg_details = llList2List(msg_details, 1, -1);
		integer cancelled = got_request();
		send_manager("request_ack", [msg_command, cancelled]);
		
	} else {
		//Is a message, we cannot cancel
		got_message();
	}
}


saveToDescription(vector vOffset, rotation rRotation, integer bAbsolute) {
	clean_description();		//Remove any existing entry
		
	string text = llDumpList2String([
			floatToString(rRotation.x),
			floatToString(rRotation.y),
			floatToString(rRotation.z),
			floatToString(rRotation.s),
			floatToString(vOffset.x),
			floatToString(vOffset.y),
			floatToString(vOffset.z),
			bAbsolute
		],
		",");
		
		string oldDesc = llGetObjectDesc();
		string newDesc = oldDesc + "BB3" + text + "3BB";
		llSetObjectDesc(newDesc);
		
		//Now re-retrieve the description to see if it was truncated
		if(llGetObjectDesc() != newDesc) {
			llOwnerSay("Could not save recording in description, was truncated!");
			llSetObjectDesc(oldDesc);
		}
}

float stringToFloat(string b)
{
    integer a = llBase64ToInteger(b);
    return ((float)("0x1p"+(string)((a | !a) - 150))) * ((!!(a = (0xff & (a >> 23))) << 23) | ((a & 0x7fffff))) * (1 | (a >> 31));
}


default {
	state_entry() {
		//========================================
		//BUILDER'S BUDDY - DO NOT REMOVE
		initialize();
		mod_state_entry();
		//========================================
		
		//Add your code here.	
	}
	
	changed(integer change) {
		//========================================
		//BUILDER'S BUDDY - DO NOT REMOVE
		mod_changed(change);
		//========================================
		
		//Add your code here.	
		
	}

	link_message(integer sender_num, integer number, string message, key id) {
		//========================================
		//BUILDER'S BUDDY - DO NOT REMOVE
		//Message for us?
		if(parse([module, ALL_MODULES], number, message, id)) {
			//Can the general method interface handle it?
			if(handle_message()) return;

			//Process it ourselves
			parse_message();
		}
		//========================================
		
		//Add your code here.
	}	
}