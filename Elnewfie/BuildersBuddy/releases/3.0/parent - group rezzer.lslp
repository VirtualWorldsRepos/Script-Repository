//==============================================================================
// Builders' Buddy 3.0 (Parent Script - Group Rezzer Module)
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
// group_prefix:
//   Text that is always included at the beginning of the group name.
//==============================================================================
// group_postfix:
//   Text that is always included at the beginning of the group name.
//==============================================================================
initialize() {        //DO NOT TOUCH THIS LINE!
	//Basic module information
	set(VAR_MOD_TYPE, TYPE_PARENT);
	set(VAR_MOD_NAME, "Group Rezzer");
	
	//Menu button configuration
	set(VAR_MOD_MENU_TYPE, MENU_TYPE_NONE);
	set(VAR_MOD_MENU_DESC, "Rez a group of objects");
	
	//Events this module is interested in
	set_list(VAR_MOD_EVENTS, ["build", "clean"]);
	
	//Add module-specific variables here
	set(VAR_PREFIX, "[");
	set(VAR_POSTFIX, "]");
	set(VAR_CLEAN_BEFORE_REZ, "Y");
}                    //DO NOT TOUCH THIS LINE!

//==============================================================================
// DO NOT EDIT ANYTHING BELOW THIS LINE!!!
//==============================================================================

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
// Utility Functions
//==============================================================================

////////////////////
string get_short_name(string longName)
{
	longName = llSHA1String(longName);
    string shortName;
    integer ptr = 0;
    integer strLength = llStringLength(longName);
    string char;
    for(ptr = 0; ptr < strLength; ptr += 2) {
        //Convert the 2-character hex code to a UTF-8 value
        //Thanks to http://wiki.secondlife.com/wiki/Chr for the concept for this code here
        integer ord = (integer)("0x" + llGetSubString(longName, ptr, ptr + 1));
        if (ord <= 0) {
        	char = "";
        	
        } else if (ord < 0x80) {
        	char = llUnescapeURL(get_url_code(ord));
        	
        } else if (ord < 0x800) {
			char = llUnescapeURL(get_url_code((ord >> 6) & 0x1F | 0xC0) + get_url_code(ord & 0x3F | 0x80));
			
        } else if (ord < 0x10000) {
        	char = llUnescapeURL(get_url_code((ord >> 12) & 0x0F | 0xE0) + get_url_code((ord >> 6) & 0x3F | 0x80) + get_url_code(ord & 0x3F | 0x80));
        	
        } else {
        	char = llUnescapeURL(get_url_code((ord >> 18) & 0x0F | 0xF0)
                        + get_url_code((ord >> 12) & 0x3F | 0x80)
                        + get_url_code((ord >> 6) & 0x3F | 0x80)
                        + get_url_code(ord & 0x3F | 0x80));
        }

		shortName += char;
    }

    return shortName;
}

////////////////////
string get_url_code(integer b)
{
    string hexd = "0123456789ABCDEF";
    return "%" + llGetSubString(hexd, b>>4, b>>4) + llGetSubString(hexd, b&15, b&15);
}

//menuFormat Created by Huns Valens
////////////////////
list menuFormat(list theButtons) {
    list btnOut;
    integer nButtons = llGetListLength(theButtons);
    integer nLastRow = nButtons % 3;
    integer lastRow = nButtons - nLastRow;
    integer row;

    // Reverse the array in chunks of 3, since an llDialog() row is 3 buttons.
    // We do not handle the first line of buttons, since they may not be a multiple of 3.
    for(row = nButtons; row >= nLastRow; row -= 3) {
        btnOut += llList2List(theButtons, row, row + 2);
    }

    // Now handle the first line of buttons, which can be 1, 2, or 3 buttons long.
    for(row = 0; row < nLastRow; row++) {
        btnOut += llList2String(theButtons, row);
    }

    return btnOut;
}

//==============================================================================
//Module Core Variables
//==============================================================================
string module = "";

//==============================================================================
//Manager Core Functions
//==============================================================================

////////////////////
check_name()
{
	module = get_short_name(llGetScriptName());
	
	//Remove any pipe symbols that may appear
    module = llDumpList2String(llParseStringKeepNulls(module, ["|"], []), "");
    
}

////////////////////
integer handle_message()
{
	
	if(msg_module == MANAGER) {
		if(msg_command == "reset") {
			llResetScript();
			return TRUE;
		}
		
		if(msg_command == "register") {
			return TRUE;
		}
	}
	
	return FALSE;
}

////////////////////
register(string module_type, string menu_type, list events, string label, string desc)
{
	menu_type = llToUpper(menu_type);
	
	if((menu_type != MENU_TYPE_ADMIN) && (menu_type != MENU_TYPE_EVERYONE) && (menu_type != MENU_TYPE_NONE)) {
		llOwnerSay("mod_register: Invalid menu type specified, please check script.");
		return;
	}
	
	//P = Parent, C = Component
	if((module_type != TYPE_PARENT) && (module_type != TYPE_CHILD)) {
		llOwnerSay("mod_register: Invalid module type specified, please check script.");
		return;
	}
		
	list details = [
		llGetScriptName(),
		module_type,
		menu_type,
		llDumpList2String(events, ","),
		label,
		desc
	];
	send_manager("register", details);
}

////////////////////
register_quick() {
	string modType = get(VAR_MOD_TYPE, TYPE_CHILD);
	string modName = get(VAR_MOD_NAME, "SET_MOD_NAME");
	string menuDesc = get(VAR_MOD_MENU_DESC, "(No description)");
	string menuType = get(VAR_MOD_MENU_TYPE, MENU_TYPE_NONE);
	list modEvents = get_list(VAR_MOD_EVENTS, []);
	
	register(modType, menuType, modEvents, modName, menuDesc);
}

////////////////////
send_manager(string command, list details) {
	send(module, MANAGER, command, details);
}


////////////////////
mod_changed(integer change) {
	if(change & CHANGED_INVENTORY) check_name();
}


////////////////////
integer mod_link_message(integer sender_number, integer number, string message, key id)
{
	return parse([module, ALL_MODULES], number, message, id);
}

////////////////////
mod_state_entry() {
	check_name();
	register_quick();	
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
// Group Rezzer Constants
//==============================================================================
string VAR_CLEAN_BEFORE_REZ = "clean_before_rez";
integer ITEMS_PER_PAGE = 8;

//==============================================================================
// Group Rezzer Variables
//==============================================================================
integer need_rebuild = TRUE;
list groups;
string action = "";
integer page = 0;

//==============================================================================
// Group Rezzer Functions
//==============================================================================

////////////////////
build_groups()
{
	
	//Skip if not needed (rebuild is *slow*)
	if(!need_rebuild) return;
	
	string prefix = get(VAR_PREFIX, "");
	string postfix = get(VAR_POSTFIX, "");
	
	groups = [];
	integer count = llGetInventoryNumber(INVENTORY_OBJECT);
	integer i;
	for(i = 0; i < count; i++) {
		string name = llGetInventoryName(INVENTORY_OBJECT, i);
		
		list test_groups = get_group_names(name, prefix, postfix);
		integer group_count = llGetListLength(test_groups);
		if(group_count > 0) {
			integer j;
			for(j = 0; j < group_count; j++) {
				string test_group = llList2String(test_groups, j);
				if(llListFindList(groups, [test_group]) == -1) {
					//Add it
					groups += [test_group];
				}
			}
		}
	}
	
	//Sort the list
	groups = llListSort(groups, 1, TRUE);
	
	need_rebuild = FALSE;
}

////////////////////
got_menu_reply() {
	
	//Which menu are we handling?
	if(action == "build") {
		string user_name = llList2String(msg_details, 0);
		string user_key = (key)llList2Key(msg_details, 1);
		if(msg_command == "<ALL>") {
			send_manager("rez", [user_key]);
			
		} else if(msg_command == "<NEXT>") {
			//Send the next page of items
			page++;
			show_build_menu(user_key);
			return;
			
		} else if(msg_command == "<PREV>") {
			page--;
			if(page < 0) page = 0;
			show_build_menu(user_key);
			return;
			
		} else if(msg_command == "<BACK>") {
			send_manager("top_menu", [user_key]);
			
		} else {
			//See if it matches one of our groups
			build_groups();
			integer found = llListFindList(groups, [msg_command]);
			if(found != -1) {
				//To prevent duplicates, delete the existing copies?
				if(is_yes("clean_before_rez", "N")) {
					send_manager("mod_say", ["clean_group", msg_command, user_key, user_name]);
				}
				
				send_manager(
					"rez", 
					[user_key,  get("group_prefix", ""), msg_command, get("group_postfix", "") ]
				);
			}
		}
		
	} else if(action == "clean") {
		string user_name = llList2String(msg_details, 0);
		string user_key = (key)llList2Key(msg_details, 1);
		if(msg_command == "<ALL>") {
			send_manager("clean", [user_key, user_name]);
			return;

		} else if(msg_command == "<BACK>") {
			send_manager("top_menu", [user_key]);
			
		} else if(msg_command == "<NEXT>") {
			//Send the next page of items
			page++;
			show_clean_menu(user_key);
			return;
			
		} else if(msg_command == "<PREV>") {
			page--;
			if(page < 0) page = 0;
			show_clean_menu(user_key);
			return;
			
		} else {
			//See if it matches one of our groups
			build_groups();
			integer found = llListFindList(groups, [msg_command]);
			if(found != -1) {
				send_manager("mod_say", ["clean_group", msg_command, user_key, user_name]);
			}
		}
	}
	action = "";
}

////////////////////
got_message()
{

	//A standard event broadcast
	if(msg_command == "reset") llResetScript();
	
	if(msg_command == "base_reset") {
		llResetScript();
		return;
	}
	
	if(msg_command == "menu_requested") {
		page = 0;
		show_build_menu(llList2Key(msg_details, 1));
		return;
	}

	if(msg_command == "menu_reply") {
		msg_command = llList2String(msg_details, 0);
		msg_details = llList2List(msg_details, 1, -1);
		got_menu_reply();
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
	
	if(msg_command == "build") {
		//Now send our own build menu request
		action = "build";
		page = 0;
		show_build_menu(llList2Key(msg_details, 0));
		
		//Cancel the request (we'll provide our own)
		return TRUE;
	}
	
	if(msg_command == "clean") {
		//Now send our own build menu request
		action = "clean";
		page = 0;
		show_clean_menu(llList2Key(msg_details, 0));
		
		//Cancel the request (we'll provide our own)
		return TRUE;
	}
	
	//Default action is to allow
	return FALSE;
}

//==============================================================================
//BUILDER'S BUDDY MODULE CODE - DO NOT REMOVE
//==============================================================================
parse_message() {

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

////////////////////
show_build_menu(key user)
{
	build_groups();
	
	//Start building the menus
	string text = "Select which group of objects to build:";
		
    send_manager("menu", [user, text] + get_group_buttons() + ["<BACK>"]);
}

////////////////////
show_clean_menu(key user)
{
	build_groups();
	
	//Start building the menus
	string text = "Select which group of objects to remove:";
		
    send_manager("menu", [user, text] + get_group_buttons() + ["<BACK>"]);
}

////////////////////
list get_group_buttons() {
	list buttons = [];
	
	if(page == 0) buttons = ["<ALL>"];
	
	integer i;
	integer count = llGetListLength(groups);
	
	integer last_page = FALSE;
	integer max = ((page + 1) * ITEMS_PER_PAGE) + 1;
	if(max >= count) {
		last_page = TRUE;
		max = count;
	}
	
	 
	for(i = (page * ITEMS_PER_PAGE); i < max; i++) {
		buttons += [llList2String(groups, i)];
	}
	
	//Add a "Prev" button?
	if(page > 0) buttons += ["<PREV>"];
	
	//Add a "Next" button?
	if(!last_page) buttons += ["<NEXT>"];
	
	return buttons;
}


///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
default
{
	state_entry() {
		//========================================
		//BUILDER'S BUDDY - DO NOT REMOVE
		initialize();
		mod_state_entry();
		//========================================
		
		//Add your code here.	
    	build_groups();
	}
	
	changed(integer change) {
		//========================================
		//BUILDER'S BUDDY - DO NOT REMOVE
		mod_changed(change);
		//========================================
		
		//Add your code here.
		if(change & CHANGED_INVENTORY) 
			need_rebuild = TRUE;	
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