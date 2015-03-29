integer MASTER_CHANNEL = -12610672; // channel to communicate with master on
integer CHAT_CHANNEL   = -12610671; // channel to listen for chat on
integer IM_CHANNEL     = -12610699; // channel to request IMs on

string  BEACON_NAME         = "/chat/beacon";
integer BEACON_DISTANCE     = 32;
integer BEACON_INTERVAL     = 5;
string  MYSTERY_LOCATION    = "???";
float   TIMEOUT             = 30.0;
float   TIMER_INTERVAL      = 0.25;
vector  _ZERO_VECTOR        = ZERO_VECTOR;

key     target              = NULL_KEY;

list    recent_msgs         = [1, 2, 3, 4, 5]; // length will be kept constant

string  location            = "???";
integer target_present      = FALSE;
integer lid = -1;

key     master_key          = NULL_KEY;

warp( vector destpos ) {
    // Compute the number of jumps necessary
    integer jumps = (integer)(llVecDist(destpos, llGetPos()) / 10.0) + 1;
    // Try and avoid stack/heap collisions
    if (jumps > 100)
        jumps = 100;    //  1km should be plenty
    list rules = [ PRIM_POSITION, destpos ];  //The start for the rules list
    integer count = 1;
    while ( ( count = count << 1 ) < jumps)
        rules = (rules=[]) + rules + rules;   //should tighten memory use.
    llSetPrimitiveParams( rules + llList2List( rules, (count - jumps) << 1, count) );
}

chat(string name, string msg) {
    string loc = location;
    if(location==MYSTERY_LOCATION) {
        loc = llGetSubString(llGetRegionName(), 0, 3);
        vector p = llGetPos();
        if(p.x < 128) {
            if(p.y<128) loc += "SW"; else loc += "NW";
        } else {
            if(p.y<128) loc += "SE"; else loc += "NE";
        }
        loc += "@" + (string)((integer)p.z);
    }
    llRegionSay(CHAT_CHANNEL, loc + "," + name + "," + msg);
}

send_target(string msg) {
    llRegionSay(IM_CHANNEL, target + ":" + msg);
}

default {
    state_entry() {
        llSetStatus(STATUS_PHYSICS|STATUS_ROTATE_X|STATUS_ROTATE_Y|STATUS_ROTATE_Z, FALSE);
        llSetObjectName("chat drone");
    }

    on_rez(integer id) {
        llListenRemove(lid);
        if(id!=0) {
            lid = llListen( id, "", NULL_KEY, "" );
            llOwnerSay("init: " + (string)id);
            llSay( MASTER_CHANNEL, "GET");
        }
    }

    listen(integer channel, string name, key id, string msg) {
        if ( llGetOwnerKey(id) != llGetOwner() )
            return;

        master_key = id;
        target = msg;
        state active;
    }
}

state active {
    state_entry() {
        llOwnerSay("target: " + "<" + (string)target + ">");

        llSetTimerEvent(TIMER_INTERVAL);

        // Listen on 0 MUST come first.
        llListen( 0, "", NULL_KEY, "" );
        llListen( CHAT_CHANNEL, "", NULL_KEY, "" );

        llSensorRepeat( BEACON_NAME, NULL_KEY, PASSIVE, BEACON_DISTANCE, PI, BEACON_INTERVAL );
    }

    timer() {
        vector pos = _ZERO_VECTOR;

        list d = llGetObjectDetails(target, [OBJECT_POS]);
        if ( d != [] ) {
            pos = llList2Vector(d,0);
            // sanity check
            if ( pos.x < 0 || pos.x > 256 || pos.y < 0 || pos.y > 256 )
                pos = _ZERO_VECTOR;
        }

        if ( pos == _ZERO_VECTOR ) {
            target_present = FALSE;
            if ( llGetTime() > TIMEOUT ) {
                llOwnerSay("dying");
                while (1) llDie();
            }
        } else {
            target_present = TRUE;
            llResetTime();
            if ( pos.z > 768.0 ) pos.z = 768.0;
            warp(pos);
        }
    }

    listen(integer channel, string name, key id, string msg) {
        if ( channel == 0 ) {
            // ignore objects
            if ( llGetOwnerKey(id) != id )
                return;
            if ( llGetAgentSize(id) == _ZERO_VECTOR )
                return;
            recent_msgs = (recent_msgs = []) + llList2List(recent_msgs, 1, -1) + (list)(name + ": " + msg);
            if ( id == target )
                chat(name, msg);
        } else {
            if ( id == master_key ) {
                if ( msg == "killall" ) llDie();
                if ( msg == "kill" + (string)target ) llDie();
                return;
            }

            if ( !target_present )
                return;

            list   d = llParseStringKeepNulls(msg, [","], []);
            string l = llList2String(d,0);
            string n = llList2String(d,1);
            string m = llDumpList2String(llList2List(d, 2, -1), ",");
            if ( llListFindList(recent_msgs, [n + ": " + m]) != -1 )
                return;
            send_target("[" + l + "] " + n + ": " + m);
        }
    }

    sensor(integer num) {
        llSensorRepeat( BEACON_NAME, NULL_KEY, PASSIVE, BEACON_DISTANCE, PI, BEACON_INTERVAL );
        location = llList2String(llGetObjectDetails(llDetectedKey(0), [OBJECT_DESC]), 0);
        // strip : and | cause they'll break stuff.
        location = llDumpList2String(llParseString2List(location, [":","|"], []), "");
        // max length
        if(llStringLength(location)>8)
            location = llDeleteSubString(location, 8, -1);
    }

    no_sensor() {
        location = MYSTERY_LOCATION;
    }
}
