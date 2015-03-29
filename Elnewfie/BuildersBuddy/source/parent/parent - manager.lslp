//==============================================================================
// Builders' Buddy 3.0 (Parent Script - Manager)
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
// VAR_ALLOW_CLEAN:
//   Is the user permitted to use the "Clean" menu option.  Must be set to "Y"
//   or "N".  If set to "N", will not display "Clean" in the menu.
//==============================================================================
// VAR_ALLOW_FORGET:
//   Is the user permitted to request child objects to delete/forget their
//   recorded position information.  Must be set to "Y" or "N".  Leave this as
//   "Y" for most cases.
//==============================================================================
//  VAR_ALLOW_GROUP:
//   Allow users that are in the same group (if set) as the parent object to
//   access the menu.  Must be set to "Y" or "N".
//==============================================================================
// VAR_ALLOW_RECORD:
//   Is the user permitted to request child objects to record their
//   recorded position information.  Must be set to "Y" or "N".  Leave this as
//   "Y" for most cases.
//==============================================================================
// VAR_CONFIRM_CLEAN:
//   When the user selects "Clean" from the menu, displays a "Are you sure?"
//   confirmation dialog.  Must be set to "Y" or "N".  Text to be displayed
//   can be changed in VAR_CLEAN_WARNING.
//==============================================================================
// VAR_CONFIRM_FINISH:
//   When the user selects "Finish" from the menu, displays a "Are you sure?"
//   confirmation dialog.  Must be set to "Y" or "N".  Text to be displayed
//   can be changed in VAR_FINISH_WARNING.
//==============================================================================
// VAR_CREATORS:
//   A List of UUIDs of users that this script will treat as object owner.
//==============================================================================
// VAR_EVENT_TIMEOUT:
//   How long to wait, in seconds, for registered modules to accept/reject
//   cancellable events.
//==============================================================================
// VAR_MENU_LISTEN_TIME:
//   How long the script will listen to a response, in seconds, when a menu
//   dialog is shown to the user.
//==============================================================================
// VAR_MENU_ON_TOUCH:
//   If set to "Y", will display a menu to eligible users when they touch the
//   object.  If set to "N", menu can only be activated by request of other
//   modules.
//==============================================================================
initialize() {        //DO NOT TOUCH THIS LINE!
	set(VAR_ALLOW_CLEAN, "Y");
	set(VAR_ALLOW_FORGET, "Y");
    set(VAR_ALLOW_GROUP, "Y");
	set(VAR_ALLOW_RECORD, "Y");
	set(VAR_CONFIRM_CLEAN, "Y");
	set(VAR_CONFIRM_FINISH, "Y");
	set_list(VAR_CREATORS, []);
	set(VAR_EVENT_TIMEOUT, "5");
	set(VAR_MENU_LISTEN_TIME, "30.0");
	set(VAR_MENU_ON_TOUCH, "Y");
}                    //DO NOT TOUCH THIS LINE!

//==============================================================================
// DO NOT EDIT ANYTHING BELOW THIS LINE!!!
//==============================================================================
$import manager.core.lslm; 
$import common.constants.lslm;
$import common.comm.core.lslm;
$import storage.core.lslm;

////////////////////
////////////////////
////////////////////
default
{
	state_entry() {
		initialize();
		base_type = TYPE_PARENT;
		manager_event_state_entry();
	}
	
	link_message(integer sender_num, integer number, string message, key id) {
		if(parse([MANAGER, ALL_MODULES], number, message, id)) {
			//Let the core handler have a stab at it first
			if(manager_core_handle_message()) return;
			
			//Now the menu handler
			if(manager_menu_handle_message()) return;
			
			//Done
			return;
		}
	}
	
	listen(integer channel, string name, key id, string message) {
		if(menu_listen(channel, name, id, message)) return;
	}
	
	touch_start(integer num_detected) {
		if(menu_touch_start(num_detected)) return;
	}
	
}