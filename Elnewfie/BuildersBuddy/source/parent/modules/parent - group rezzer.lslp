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
$import common.constants.lslm;
$import common.log.lslm;
$import storage.core.lslm;
$import module.constants.lslm;
$import module.core.lslm;
$import module.group.core.lslm;

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
	debug(TRACE, "grouprezzer.buildGroups()");
	
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
					debug(DEBUG, "Adding rez group: " + test_group);
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
	debugl(TRACE, ["parent - group rezzer.got_menu_reply()", "msg_command: " + msg_command, "msg_details: " + llDumpList2String(msg_details, "|")]);
	
	//Which menu are we handling?
	if(action == "build") {
		string user_name = llList2String(msg_details, 0);
		string user_key = (key)llList2Key(msg_details, 1);
		if(msg_command == "<ALL>") {
			debug(DEBUG, "Rezzing all objects");
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
			debug(DEBUG, "Cleaning all objects");
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
	debugl(TRACE, ["creator.got_message()", "msg_command: " + msg_command, "msg_details: " + llDumpList2String(msg_details, "|")]);

	//A standard event broadcast
	if(msg_command == "reset") llResetScript();
	
	if(msg_command == "base_reset") {
		llResetScript();
		return;
	}
	
	if(msg_command == "menu_requested") {
		debug(DEBUG, "Requested to show menu!");
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
	debugl(TRACE, ["creator.got_request()", "msg_command: " + msg_command, "msg_details: " + llDumpList2String(msg_details, "|")]);
	
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
	debugl(TRACE, ["creator.mod_parse_message()", "msg_command: " + msg_command, "msg_details: " + llDumpList2String(msg_details, "|")]);

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
	
	debug(DEBUG, "Max: " + (string)max);
	debug(DEBUG, "Count: " + (string)count);
	 
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