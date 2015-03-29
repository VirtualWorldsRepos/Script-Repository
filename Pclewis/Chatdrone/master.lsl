integer CHANNEL         = -12610672; // channel that scanners announce scanned agents on
integer CHAT_CHANNEL    = -12610671; // channel to send chat on
integer DRONE_CHANNEL   = -12610670; // channel to init drones on

string  CHAT_DRONE      = "chat drone"; // name of chat drones

float   PING_CHECK      = 30.0;

list    tracked_agents  = [];
list    tracked_objects = [];

list    rez_queue       = [];
key     rez_waiting     = NULL_KEY;

integer
is_key(key in)
{
    if (in) return TRUE;
    return FALSE;
}

rez(key id)
{
    if ( id == NULL_KEY ) {
        rez_waiting = NULL_KEY;
        if ( rez_queue == [] ) {
            return;
        } else {
            id = llList2Key(rez_queue, 0);
            if ( rez_queue == [1] )
                rez_queue = [];
            else
                rez_queue = llList2List(rez_queue, 1, -1);
        }
    }

    if ( rez_waiting == NULL_KEY ) {
        rez_waiting = id;
        llOwnerSay("rez " + (string)id);
        llRezObject(CHAT_DRONE, llGetPos(), ZERO_VECTOR, ZERO_ROTATION, DRONE_CHANNEL);
        return;
    }
    rez_queue += id;
}

default {
    state_entry() {
        llOwnerSay("masterkey: " + (string)llGetKey() );
        llListen(CHANNEL, "", NULL_KEY, "");
        llSetTimerEvent(PING_CHECK);
        llRegionSay( CHAT_CHANNEL, "killall" );
    }

    timer() {
        integer i = llGetListLength(tracked_objects);
        while (i--) {
            key k = llList2Key(tracked_objects, i);
            if ( k != NULL_KEY ) {
                if ( llKey2Name(k) == "" ) {
                    llOwnerSay( llList2String(tracked_agents,i) + " gone" );
                    llRegionSay( CHAT_CHANNEL, "kill" + llList2String(tracked_agents,i) );
                    tracked_agents = llDeleteSubList(tracked_agents, i, i);
                    tracked_objects = llDeleteSubList(tracked_objects, i, i);
                }
            }
        }
    }

    listen(integer channel, string name, key id, string msg) {
        if ( llGetOwnerKey(id) != llGetOwner() )
            return;

        if ( msg == "GET" ) {
            integer i = llListFindList(tracked_agents, (list)rez_waiting);
            if (i == -1) {
                llInstantMessage(llGetOwner(), "agent not in list?? [" + (string)rez_waiting + "] [" +
                                 llDumpList2String(tracked_agents, ",") + "]");
                llSetScriptState(llGetScriptName(), 0);
            }
            tracked_objects = llListReplaceList(tracked_objects, (list)id, i, i);
            llSay(DRONE_CHANNEL, (string)rez_waiting);
            rez(NULL_KEY);
            return;
        }

        list keys = llCSV2List(msg);
        integer i = llGetListLength(keys);
        while ( i-- ) {
            key k = llList2Key(keys, i);
            if ( is_key(k) ) {
                if ( llListFindList(tracked_agents, [k]) == -1 ) {
                    tracked_agents += k;
                    tracked_objects += NULL_KEY;
                    rez(k);
                }
            }
        }
    }
}
