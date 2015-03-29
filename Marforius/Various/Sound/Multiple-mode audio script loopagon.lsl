// new in 1.1, fixed an oops that was an && instead of an ||
// fixed mode switching
// gave stuff some values by default
// also changed the unique function to just use channel 10, easier on the fingers
// 1.2 added some shortcuts, including the "dakka uuid" command
// 1.3  || m == "smoothwalker"
//Kiki was here and added amps from another script (soundslaves)
// kiki, name is a string, current_playing_uuid is the uuid the user selects / types in
// run scripts by me before you release them ~
// (also compile in mono)
// ~ new in 1.4 - we sync, use less memory(less than half as much), smoothwalker deincrements volume correctly instead of just turning off
// there was some discussion on how to sync properly, by storing the uuid in memory, preloading it and then waiting for the next major change in time to play it
// playing via linked messages is sufficent to sync with one message being fired off to preload from one prim before the actual message goes out
// this puts a lot of trust in the logic behind lsl, but if all goes well that one prim reads the message, preloads it, and then all the prims start looping at the same/correct time
// ! if you use this test version of this, please flip upside down.
// this script has had it's memory fine tuned, increase it if you add things, or if you really have problems remove the limit
// ~ new in 1.5 - cleaned up code, hope you didn't plan on letting others access your loopagon 8) // fixed some oops // added volume changing (which really does nothing) 8)
// 1.6 - I should actually use Mode_Change()
integer querytype;

integer QTYPE_FILTER = 0;
integer QTYPE_PAGENUM = 1;

integer loopindex;
integer loopindex_filter;

// change what mode you want the script to startup in the description of the main prim (1 walker) (2 smoothwalker) (3 bumper) (4 boombox)
integer mode;


float volume;
string displayfilter = "";
string currently_playing_uuid = "9f6ed5df-d1b8-e265-5324-15d0960e7d8a";
key global_owner;

Mode_Change(integer incoming_mode) {
    mode = incoming_mode;
    llSetObjectDesc((string) incoming_mode);
    if (!(incoming_mode == 3 || incoming_mode == 4))
    {
        llSetTimerEvent(0.5);
    }
    else
    {
        llSetTimerEvent(0.0);
    }
}

Change_Volume(float new_volume)
{
    volume = new_volume;
    llAdjustSoundVolume(new_volume);
    llMessageLinked(LINK_SET, 0, "VOLUME " + (string)new_volume, global_owner);
    llMessageLinked(LINK_SET, 0, "AMPTHIS", currently_playing_uuid);
    llOwnerSay("Changed volume to " + (string)new_volume);
}

//returns max index for song menu offset
integer max() {
    return llFloor((float) llGetInventoryNumber(INVENTORY_SOUND) / 9.0);
}

integer filtermax() {
    integer x;
    float valid;
    for (x = 0; x < llGetInventoryNumber(INVENTORY_SOUND); x++) {
        if (~llSubStringIndex(llToLower(llGetInventoryName(INVENTORY_SOUND, x)), displayfilter))
            valid += 1.0;
    }
    return llFloor(valid / 9.0);
}

showloops(integer index, string filter) {
    list out = ["< PREV <", "CANCEL", "> NEXT >"];
    list defuck;
    string name;
    integer x = index * 9;
    integer w = 0;
    integer t = 0;
    while ((t < 9) && ((x + w) < llGetInventoryNumber(INVENTORY_SOUND))) {
        name = llGetInventoryName(INVENTORY_SOUND, x + w);
        if ((filter == "") || ((filter != "") && (~llSubStringIndex(llToLower(name), displayfilter)))) {
            defuck += chop(name);
            t++;
        }
        w++;
    }

    out += roflcopter(defuck);
    out = removenulls(out);
    llDialog(global_owner, "Loops:\n(Page " + (string) index + ")", out, mlisten);
}

string chop(string in ) {
    if (llStringLength( in ) > 24)
        return llGetSubString( in , 0, 23);
    return in;
}

list removenulls(list in ) {
    integer x = llGetListLength( in );
    while (~--x) {
        if (llList2String( in , x) == "") in = llDeleteSubList( in , x, x);
    }
    return in;
}

list roflcopter(list in ) {
    if (llGetListLength( in ) > 6)
        return llList2List( in , 6, 8) + llList2List( in , 3, 5) + llList2List( in , 0, 2);

    else if (llGetListLength( in ) > 3)
        return llList2List( in , 3, 5) + llList2List( in , 0, 2);

    else return in;
}

check_song(string m, string id) {
    integer x;
    string name;
    if (llStringLength(m) < 24) {
        for (x = 0; x < llGetInventoryNumber(INVENTORY_SOUND); x++) {
            name = llGetInventoryName(INVENTORY_SOUND, x);
            if (name == m) {
                currently_playing_uuid = (string) llGetInventoryKey(llGetInventoryName(INVENTORY_SOUND, x));
                llMessageLinked(LINK_SET, 0, "PRELOAD", currently_playing_uuid);
                llMessageLinked(LINK_SET, 0, "AMPTHIS", currently_playing_uuid);
                llOwnerSay("Looping: " + m);
                if (displayfilter == "")
                    showloops(loopindex, "");
                else
                    showloops(loopindex_filter, displayfilter);
                return;
            }
        }
    }
    else {
        for (x = 0; x < llGetInventoryNumber(INVENTORY_SOUND); x++) {
            name = llGetInventoryName(INVENTORY_SOUND, x);
            if (llSubStringIndex(name, m) == 0) {
                currently_playing_uuid = (string) llGetInventoryKey(llGetInventoryName(INVENTORY_SOUND, x));
                llMessageLinked(LINK_SET, 0, "PRELOAD", currently_playing_uuid);
                llMessageLinked(LINK_SET, 0, "AMPTHIS", currently_playing_uuid);
                llOwnerSay("Looping: " + name);
                if (displayfilter == "")
                    showloops(loopindex, "");
                else
                    showloops(loopindex_filter, displayfilter);
                return;
            }
        }
    }
}

integer menulisten;
integer filterlisten;
integer mlisten;
integer flisten;
newlisten() {
    mlisten = 10;
    flisten = 11;

    llListenRemove(menulisten);
    llListenRemove(filterlisten);

    menulisten = llListen(mlisten, "", "", "");
    filterlisten = llListen(flisten, "", "", "");
}

default {
    on_rez(integer r) {
        llResetScript();
    }
    state_entry() {
        llSetMemoryLimit(28300 + (max() * 38));
        llOwnerSay("/me Type \"/10\" Loops\" to access the menu for selecting sounds. You can also use the commands \"STFU\", \"Search\", \"ClearFilter\", \"Modes\" \n
You can also use \/10 dakka and then an uuid to skip the entire search menu, or \/10 boombox, walker, smoothwalker, or bumper\n
New command: volume - accepts float input but doesn't do anything because of the soundslaves.");
        llMessageLinked(LINK_SET, 0, "DEAMP", NULL_KEY);
        llStopSound();
        newlisten();
        string desc = llGetObjectDesc();
        if ((string)((integer) desc) == desc) {
            Mode_Change((integer) desc);
        }
        else {
            Mode_Change(4);
        }
        global_owner = llGetOwner();
        llDialog(global_owner, "Options:", ["Loops", "L: Start", "L: End", "STFU", "Search", "ClearFilter", "Modes"], mlisten);
    }
    touch_start(integer total_number) {
        if (llDetectedKey(0) != global_owner) {
            return;
        }
        llDialog(global_owner, "Options:", ["Loops", "L: Start", "L: End", "STFU", "Search", "ClearFilter", "Modes"], mlisten);
    }

    timer() {
        if (mode == 1) { // walker - walkers do not need preloads as they are constantly playing the sound and will resync by design
            string anim = llGetAnimation(global_owner);
            if ((llGetAgentInfo(global_owner) & 128) || anim == "Turning Left" || anim == "Turning Right") { // if walking/turning
                volume = 1.0;
            }
            else {
                volume = 0.0;
                llMessageLinked(LINK_SET, 0, "DEAMP", NULL_KEY);
            }
            llAdjustSoundVolume(volume);
        }

        if (mode == 2) { // smooth walker
            string anim = llGetAnimation(global_owner);
            if ((llGetAgentInfo(global_owner) & 128) || anim == "Turning Left" || anim == "Turning Right") { // if walking/turning
                // volume increase
                volume += 0.100;
                llAdjustSoundVolume(volume);
                if (volume > 1.0) { // cap volume
                    volume = 1.0;
                }
            }
            else {
                // volume decrease
                volume -= 0.100;
                llAdjustSoundVolume(volume);
                if (volume < 0.1) { // cap volume
                    volume = 0;
                    llMessageLinked(LINK_SET, 0, "DEAMP", NULL_KEY);
                }
            }
        }

        // bumper mode (3) handled in the colission state
        // boombox mode (4) handled as soon as the input comes in
    }

    listen(integer c, string n, key id, string m) {
        if (id != global_owner) {
            return;
        }

        if (c == mlisten) {
            if (m == "STFU" || m == "stfu") {
                llMessageLinked(LINK_SET, 0, "DEAMP", NULL_KEY);
                llStopSound();
            }
            else if (m == "Loops" || m == "loops") {
                if (displayfilter == "")
                    showloops(loopindex, "");
                else
                    showloops(loopindex_filter, displayfilter);
            }
            else if (m == "L: Start") {
                if (displayfilter == "")
                    showloops(loopindex = 0, "");
                else
                    showloops(loopindex_filter = 0, displayfilter);
            }
            else if (m == "L: End") {
                if (displayfilter == "")
                    showloops(loopindex = max(), "");
                else
                    showloops(loopindex_filter = filtermax(), displayfilter);
            }
            else if (m == "Search" || m == "search")
                llDialog(global_owner, "Search Options:", ["Filter", "Page#"], mlisten);

            else if (m == "Filter") {
                llTextBox(global_owner, "Enter search criteria:", flisten);
                querytype = QTYPE_FILTER;
            }
            else if (m == "ClearFilter") {
                displayfilter = "";
                llOwnerSay("Cleared Search Filter");
            }
            else if (m == "Page#") {
                llTextBox(global_owner, "Enter page number:", flisten);
                querytype = QTYPE_PAGENUM;
            }
            else if (m == "< PREV <") {
                if (displayfilter != "") {
                    if (loopindex_filter > 0)
                        loopindex_filter--;
                    showloops(loopindex_filter, displayfilter);
                }
                else {
                    if (loopindex > 0)
                        loopindex--;
                    showloops(loopindex, "");
                }
            }
            else if (m == "> NEXT >") {
                if (displayfilter != "") {
                    if (loopindex_filter < filtermax())
                        loopindex_filter++;
                    showloops(loopindex_filter, displayfilter);
                }
                else {
                    if (loopindex < max())
                        loopindex++;
                    showloops(loopindex, "");
                }
            }
            else if (m == "CANCEL" || m == "cancel") {
                llDialog(global_owner, "Options:", ["Loops", "L: Start", "L: End", "STFU", "Search", "ClearFilter", "Modes"], mlisten);
            }
            else if (m == "Modes" || m == "modes") {
                llDialog(global_owner, "Modes:", ["Walker", "Smooth Walker", "Bumper", "Boombox", "CANCEL"], mlisten);
            }
            else if (m == "Walker" || m == "walker") {
                Mode_Change(1);
            }
            else if (m == "Smooth Walker" || m == "smooth walker" || m == "smoothwalker") {
                Mode_Change(2);
            }
            else if (m == "Bumper" || m == "bumper") {
                Mode_Change(3);
                llStopSound();
                llMessageLinked(LINK_SET, 0, "DEAMP", NULL_KEY);
            }
            else if (m == "Boombox" || m == "boombox") {
                Mode_Change(4);
                llMessageLinked(LINK_SET, 0, "PRELOAD", currently_playing_uuid);
                llMessageLinked(LINK_SET, 0, "AMPTHIS", currently_playing_uuid);
            }
            else if (llSubStringIndex(m, "dakka") == 0) {
                currently_playing_uuid = llGetSubString(m, llSubStringIndex(m, " ") + 1, -1);
                if (currently_playing_uuid == "dakka") {
                    currently_playing_uuid = "9043e854-d7f6-b210-25d1-ab32c40b5d2f";
                    llOwnerSay("put a soundloop in next time retart");
                    llOwnerSay((string) currently_playing_uuid);
                }

                llMessageLinked(LINK_SET, 0, "PRELOAD", currently_playing_uuid);
                llMessageLinked(LINK_SET, 0, "AMPTHIS", currently_playing_uuid);
            }
            else if (llSubStringIndex(m, "volume") == 0) {
            string new_volume = llGetSubString(m, llSubStringIndex(m, " ") + 1, -1);
            Change_Volume((float)new_volume);
        }
            else check_song(m, id);
        }
        else if (c == flisten) {
            if (querytype == QTYPE_FILTER) {
                displayfilter = llToLower(m);
                loopindex_filter = 0;
                showloops(loopindex_filter, displayfilter);
                llOwnerSay("Now displaying loops containing '" + displayfilter + "'");
            }
            else if (querytype == QTYPE_PAGENUM) {
                if (m == "NaN" || m == "Infinity") {
                    llOwnerSay("Nice try.");
                    return;
                }

                if (displayfilter == "") {
                    loopindex = (integer) m;
                    showloops(loopindex, "");
                }
                else {
                    loopindex_filter = (integer) m;
                    showloops(loopindex_filter, displayfilter);
                }
                llOwnerSay("Jumping to page " + m + ".");
            }
        }
    }
    collision_start(integer detected) {
        if ((llDetectedType(0) & AGENT) && mode == 3) {
            llMessageLinked(LINK_SET, 0, "PRELOAD", currently_playing_uuid);
            llMessageLinked(LINK_SET, 0, "TRIGGER", currently_playing_uuid);
        }
    }
    link_message(integer s, integer n, string str, key id2) {
        if (str == "AMPTHIS") {
            llStopSound();
            llLoopSoundMaster(id2, volume);
        }
        else if (str == "TRIGGER") {
            llTriggerSound(id2, volume);
        }
    }
}

// eof