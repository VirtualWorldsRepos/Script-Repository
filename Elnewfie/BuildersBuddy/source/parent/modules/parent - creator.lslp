//==============================================================================
// Builders' Buddy 3.0 (Parent Script - Creator Module)
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
// VAR_MOD_TYPE:
//   Indicates if this module should link to the parent or component scripts.  
//   Set to one of:
//     TYPE_PARENT - Module intended for use in the parent prim
//     TYPE_CHILD - Module intended for use in the child prims;
//==============================================================================
// VAR_MOD_MENU_TYPE:
//   The type of button to be added to the menu.  Set to one of:
//   MENU_TYPE_ADMIN - Button is seen only by administrators/creators
//   MENU_TYPE_EVERYONE - Button is seen by everyone
//   MENU_TYPE_NONE - No button will be shown.     
//==============================================================================
// VAR_MOD_NAME:
//   The name of the module.  If menu_type is set to MOD_MENU_TYPE_ADMIN
//   or MOD_MENU_TYPE_EVERYONE, this will be used as the label on the button.    
//==============================================================================
// VAR_MOD_MENU_DESC:
//   Description of the module. Will be included in the text of the menu when
//   the module's button is display.    
//==============================================================================
// VAR_MOD_EVENTS:
//   Events that this module wishes to review and possibly cancel.  These can
//   only be events that are explicitly available as cancellable in the base or
//   component script.  This should be set as a list using setList();
//==============================================================================
initialize() {        //DO NOT TOUCH THIS LINE!
	//Basic module information
	set(VAR_MOD_TYPE, TYPE_PARENT);
	set(VAR_MOD_NAME, "Creator");
	
	//Menu button configuration
	set(VAR_MOD_MENU_TYPE, MENU_TYPE_ADMIN);
	set(VAR_MOD_MENU_DESC, "Creator-specific commands");
	
	//Events this module is interested in
	set_list(VAR_MOD_EVENTS, ["record", "forget"]);

	//Other module-specific settings
}                    //DO NOT TOUCH THIS LINE!

//==============================================================================
// DO NOT EDIT ANYTHING BELOW THIS LINE!!!
//==============================================================================
$import common.constants.lslm;
$import common.log.lslm;
$import common.comm.core.lslm;
$import storage.core.lslm;
$import common.util.lslm;
$import module.constants.lslm;
$import module.core.lslm;

//==============================================================================
//Creator Variables
//==============================================================================
string menu_action = "";

//==============================================================================
//Creator Functions
//==============================================================================

////////////////////
got_menu_reply() {
	debugl(TRACE, ["parent_creator.got_menu_reply()", "msg_command: " + msg_command, "msg_details: " + llDumpList2String(msg_details, "|")]);

	if(msg_command == "Record") {
	    llOwnerSay("Recording positions...");
	    send_manager("record",  [llGetPos(), llGetRot(), FALSE]);
        return;
	}
	
	if(msg_command == "SimRecord") {
        //Location in sim
		send_manager("record", [ZERO_VECTOR, ZERO_ROTATION, TRUE]);
        return;
	}
	
	if(msg_command == "Clear") {
        llOwnerSay("Forgetting positions...");
		send_manager("clear", []);
		return;
	}
	
	if(msg_command == "Sell") {
		if(menu_action == "sell") {
			//User confirmed sell option, do the deed
			unregister();
			llOwnerSay("Creator script has been removed.");
			llRemoveInventory(llGetScriptName());
			
		} else {
			//Ask the user to confirm
			show_sell_menu((key)llList2String(msg_details, 1));
		}
		return;
	}
	
	if(msg_command == "Cancel") {
		//User cancelled a menu
		menu_action = "";
	}
	
	if(msg_command == "Identify") {
		send_manager("send_child", ["identify"]);
		return;
	}
	
	if(msg_command == "BACK") {
		string user_key = (key)llList2Key(msg_details, 1);
		send_manager("top_menu", [user_key]);
	}
}

//==============================================================================
// BUILDER'S BUDDY MODULE CODE - DO NOT REMOVE
// This is called when the module has received any standard event.
//==============================================================================
got_message()
{
	debugl(TRACE, ["creator.got_message()", "msg_command: " + msg_command, "msg_details: " + llDumpList2String(msg_details, "|")]);

	// BUILDER'S BUDDY - Add your code here
	//It was a request then
	if(msg_command == "reset") {
		llResetScript();
		return;
	}
    		
	if(msg_command == "request_menu") {
		string name = llList2String(msg_details, 0);
		key user = (key)llList2String(msg_details, 1);
		integer is_full_rights  = llList2Integer(msg_details, 2);
		show_menu(user, is_full_rights);
		return;
	}
    		
	if(msg_command == "menu_reply") {
		msg_command = llList2String(msg_details, 0);
		msg_details = llList2List(msg_details, 1, -1);
		got_menu_reply();
		return;
	}
	
    return;
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
	
	//Add your code here.	
	
	
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
show_menu(key user, integer is_full_rights)
{
	debug(DEBUG, "Showing menu");
	
    string text = "";
    list buttons = [];
    menu_action = "";
    
    //Start building the menus
    buttons += ["Record", "SimRecord", "Clear", "Sell", "Identify"];
    text += 
    	"Record: Record the position of all parts"
    	+ "\nSimRecord: Record region-exact position of parts"
    	+ "\nClear: Forgets the position of all parts"
    	+ "\nSell: Mark object as ready to sell, allow no more changes"
    	+ "\nIdentify: Ask child objects to announce themselves";

	send_manager("menu", [user, text] + buttons + ["BACK"]);
}

////////////////////
show_sell_menu(key user)
{
	debug(DEBUG, "Showing Sell menu");
	
    string text = "";
    list buttons = [];
    
    menu_action = "sell";
    
    //Start building the menus
    buttons += ["Sell", "Cancel"];
    text +=
    	"WARNING: Pressing \"Sell\" will mark this object for sale, lock existing settings and delete the Creator commands from the menu."
    	+ "\n\nTHIS CANNOT BE UNDONE!"
    	+ "\n\nAre you sure you want to sell this item?"; 

	send_manager("menu", [user, text] + buttons);
	
}

////////////////////
unregister(){
	send_manager("unregister", []);
}


////////////////////
////////////////////
////////////////////
default
{
	state_entry()
	{
		//========================================
		//BUILDER'S BUDDY - DO NOT REMOVE
		initialize();
		mod_state_entry();
		//========================================
		
		//Add your code here.
	}
	
	changed(integer change) {
		mod_changed(change);
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
		
		//Add your code here.
	}
}