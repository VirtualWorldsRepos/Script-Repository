integer my_num;
default {
    state_entry() {
        my_num = (integer)llGetSubString(llGetScriptName(), -2, -1);
        llOwnerSay((string)my_num);
    }

    link_message(integer sender, integer num, string msg, key id) {
        if ( num == my_num )
            llInstantMessage(id, msg);
    }
}
