//==============================================================================
// Builders' Buddy 3.0 (Parent Script - Base)
// by Newfie Pendragon, 2006-2013
//==============================================================================
// This script is copyrighted material, and has a few (minor) restrictions.
// For complete details, including a revision history, please see
//  http://wiki.secondlife.com/wiki/Builders_Buddy
//
// The License for this script has changed relative to prior versions; please
//  check the website noted above for details.
//==============================================================================

//==============================================================================
// CONFIGURABLE SETTINGS
//==============================================================================
initialize() {        //DO NOT TOUCH THIS LINE!
	//Add module-specific variables here
	set(VAR_REMOVE_TAG, "N");
	set(VAR_PREFIX, "[");
	set(VAR_POSTFIX, "]");
}                    //DO NOT TOUCH THIS LINE!

//==============================================================================
// DO NOT EDIT ANYTHING BELOW THIS LINE!!!
//==============================================================================
$import common.comm.core.lslm;
$import common.constants.lslm;
$import common.log.lslm;
$import storage.core.lslm;
$import module.constants.lslm;
$import module.group.core.lslm;

//==============================================================================
//Group Rezzer Functions
//==============================================================================

////////////////////
clean_name()
{
	string new_name = get_base_name(get(VAR_PREFIX, ""), get(VAR_POSTFIX, ""), llGetObjectName());
	llSetObjectName(new_name);
}

////////////////////
got_message()
{
	debugl(TRACE, ["creator.got_message()", "msg_command: " + msg_command, "msg_details: " + llDumpList2String(msg_details, "|")]);

	// BUILDER'S BUDDY - Add your code here
	if(msg_command == "clear_scripts") {
		//Remove ourselves?
		if(is_yes(VAR_REMOVE_TAG, "N")) clean_name();
		llRemoveInventory(llGetScriptName());
		return;
	}
	
	if(msg_command == "mod_say") {
		msg_command =  llList2String(msg_details, 0);
		msg_details = llList2List(msg_details, 1, -1);
		
		got_parent_module_message();
		return;
	}	
	
}

//==============================================================================
// BUILDER'S BUDDY MODULE CODE - DO NOT REMOVE
// This is called when the module has received a message meant only for modules
// to handle directly
//==============================================================================
got_parent_module_message()
{
	debugl(TRACE, ["got_parent_module_message", "msg_command: " + msg_command, "msg_details: " + llDumpList2String(msg_details, "|")]);
	
	// BUILDER'S BUDDY - Add your code here
	if(msg_command == "clean_group") {
		//clean_group|<group_name>|<user key>|<user name>
		string group_name = llList2String(msg_details, 0);	// matching text
		debug(DEBUG, "Cleaning group name: " + group_name);
		if(is_group_match(get(VAR_PREFIX, ""), group_name, get(VAR_POSTFIX, ""), llGetObjectName())) {
			llDie();
		}
	}	
}

////////////////////
////////////////////
////////////////////
default {
	state_entry() {
		//========================================
		//BUILDER'S BUDDY - DO NOT REMOVE
		//Message for us?
		initialize();
		//========================================
	}
	
	link_message(integer sender_num, integer number, string message, key id) {
		initialize();
		
		//========================================
		//BUILDER'S BUDDY - DO NOT REMOVE
		//Message for us?
		if(parse([ALL_MODULES], number, message, id)) {
			got_message();
		}
		//========================================
		
		//Add your code here.
	}	
}