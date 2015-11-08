//////////////////////////////////////////////////////////////////////////

// Filename:    TradeMogul Take Item From Crate (Menu)
// Version:     0.2
// Date:        09.23.2010

// Creator:     DaveDorm Gaffer

// Description: 

//////////////////////////////////////////////////////////////////////////

// A distibution crate that stores differnt items and creates a menu on the fly. This is to represent a mixed lot of goods in one crate. Hovertext is set in the Object Name, recipient must be within 2m of the crate to take an item. This is to cut down on "shopliftng," as this is not a vendor. The crate has no expiration, however items inside may be timed. When clicked, one object is given to the recipient. Once they are gone, the crate is empty and will IM the owner to be restocked.

//////////////////////////////////////////////////////////////////////////

integer CHANNEL;
integer handle;
key touched;

list CONTENTS;

RebuildContents() {
    CONTENTS = [];

    integer count = llGetInventoryNumber(INVENTORY_OBJECT);
    integer i;

    for (i = 0; i < count; ++i) {
        string name = llGetInventoryName(INVENTORY_OBJECT, i);
        name = llGetSubString(name, 0, 24);
        CONTENTS = (CONTENTS=[]) + CONTENTS + [ name ];
        }
    }

DisplayMenu(integer page) {
    integer length = llGetListLength(CONTENTS);
    integer start = page * 9;
    integer end = start + 9;
    list menu = [];

    page += 1;

        if (start > 0) {
            menu = [ "Page " + (string)(page - 1) ];
            }
    
        else {
            menu = [ " " ];
            }

    menu = (menu=[]) + menu + llList2List(CONTENTS, start, start);

    if (end < length) {
        menu = (menu=[]) + menu + [ "Page " + (string) (page + 1) ];
        }
        
    else {
        menu = (menu=[]) + menu + [ " " ];
        }

    menu = (menu=[]) + menu + llList2List(CONTENTS, start + 1, end);

    llDialog(touched, "\nContents: ", menu , CHANNEL);
}

default {
    state_entry() {
        llSetText(llGetObjectName() + "\n \n \n", <1.0,0.5,0.0>, 1);

    RebuildContents();

    llListenRemove(handle);
    CHANNEL = (integer)llFrand(2000000000.0);
    llListen(CHANNEL, "", NULL_KEY, "");
    }

on_rez(integer start) {
    llResetScript();
    }

changed(integer change) {
    if (change == CHANGED_INVENTORY) {
        llOwnerSay("Rebuilding contents");
        RebuildContents();
        llOwnerSay("Done.");
        }
    }

touch_start(integer total_number) {
    touched = llDetectedKey(0);
    if (touched) {
        DisplayMenu(0);
    }
}

listen(integer channel, string name, key id, string message) {
    if (llSubStringIndex(message, "Page ") != -1) {
        string page = llGetSubString(message, 5, -1);
        DisplayMenu(((integer) page) - 1);
    } else {
        integer item = llListFindList(CONTENTS, [ message ]);
        if (item != -1) {
            llGiveInventory(id, llGetInventoryName(INVENTORY_OBJECT, item));
            }
        }
    }
}

//////////////////////////////////////////////////////////////////////////

// For More information, see the TradeMogul website
/// at http://trademogul.org

//////////////////////////////////////////////////////////////////////////