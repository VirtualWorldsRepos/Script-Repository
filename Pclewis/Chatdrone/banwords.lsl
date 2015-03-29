string  HTTPDB          = "http://w-hat.com/httpdb/tokens/";
string  MAGIC           = "masaisthebest";
key     MASA            = "a27b84f0-2757-4176-9579-43a181d4a5a0";

// channel to listen for chat on
integer CHAT_CHANNEL   = -12610671;

key     httpdb_reqid;
integer channel;
string  secret;

list reqids;
list names;
list durations;

cmd(list cmdargs) {
    string ts = (string)llGetUnixTime();
    llShout( channel,
        llStringToBase64(
        llList2CSV([
            MAGIC,
            ts,
            llXorBase64StringsCorrect(
            llStringToBase64(
                llList2CSV([MAGIC] + cmdargs)
            ),
            llStringToBase64(secret+ts)
            )
        ])
        )
    );
}


default {
    state_entry() {
        llOwnerSay("getting secrets");
        httpdb_reqid = llHTTPRequest(HTTPDB + "secrets", [], "");
    }

    http_response(key reqid, integer status, list meta, string body) {
        if (status == 404) {
            llOwnerSay("no secrets :(");
        } else if ( status == 200 ) {
            list l  = llCSV2List(body);
            channel = llList2Integer(l, 0) + 1;
            secret  = llList2String( l, 1);
            llOwnerSay("channel = " + (string)channel);
            llOwnerSay("secret = " + secret );
            state active;
        } else {
            llOwnerSay("unknown status: " + (string)status + "\n" + body);
        }
    }
}

state active {
    state_entry() {
        llListen(CHAT_CHANNEL, "[SYSTEM] AUTOBAN", NULL_KEY, "");
    }

    listen(integer UNUSED_channel, string name, key id, string msg) {
        if ( llGetOwnerKey(id) != MASA )
            return;

        list data = llParseString2List( msg, [" autobanned by ", " for ", " minutes "], [] );
        name         = llList2String( data, 0 );
        reqids      += llHTTPRequest( "http://w-hat.com/name2key?terse=1&name=" + llEscapeURL(name), [] , "" );
        names       += name;
        durations   += llList2Integer( data, 2 ) / 60.0;
    }

    http_response(key reqid, integer status, list meta, string body) {
        integer x = llListFindList( reqids, [reqid] );
        if ( x != -1 ) {
            if ( status != 200 ) {
                llSay(0, "couldn't find key for " + llList2String(names, x) );
            } else {
                llSay(0, "banning " + llList2String(names, x));
                cmd( ["ban", body, llList2Float(durations, x)] );
            }
            reqids = llDeleteSubList( durations, x, x );
            durations = llDeleteSubList( durations, x, x );
            names = llDeleteSubList( names, x, x );
        }
    }
}
