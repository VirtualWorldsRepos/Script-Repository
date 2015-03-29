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


//==============================================================================
//Communication variables
//==============================================================================
string msg_command;
list msg_details;
string msg_module;

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
//Menu Constants
//==============================================================================
string MENU_TYPE_ADMIN = "A";
string MENU_TYPE_EVERYONE = "E";
string MENU_TYPE_NONE = "X";
string VAR_MOD_EVENTS = "mod_events";
string VAR_MOD_MENU_DESC = "mod_menu_desc";
string VAR_MOD_MENU_TYPE = "mod_menu_type";
string VAR_MOD_NAME = "mod_name";
string VAR_MOD_TYPE = "mod_type";

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
	
	// BUILDER'S BUDDY - Add your code here
	if(msg_command == "clean_group") {
		//clean_group|<group_name>|<user key>|<user name>
		string group_name = llList2String(msg_details, 0);	// matching text
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