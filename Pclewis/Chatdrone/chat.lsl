///////////////////////////////////////////////////////////
// Constants
///////////////////////////////////////////////////////////
// Full path for chat connection
string  CHAT_URL        = "http://nagisa.w-hat.com:54000/chat";

// channel to listen for chat on
integer CHAT_CHANNEL    = -12610671;

float   TIMER_INTERVAL  = 1.2;

key     CONTROL_KEY     = "56d3876e-19d4-aa4d-8690-a455bc68930c";
key     MASTER_KEY      = "325b498f-2308-0482-2c63-95a59a5c01a9";

///////////////////////////////////////////////////////////
// Globals
///////////////////////////////////////////////////////////
list    queue        = [];

string escape(string msg) {
    string result = "";
    while ( llStringLength(msg) > 64 ) {
        result += llEscapeURL( llDeleteSubString(msg, 64, -1) );
        msg = llDeleteSubString(msg, 0, 63);
    }
    result += llEscapeURL(msg);
    return result;
}

default {
    state_entry() {
        llListen(CHAT_CHANNEL, "", NULL_KEY, "");
        llSetTimerEvent(TIMER_INTERVAL);
    }

    listen(integer channel, string name, key id, string msg) {
        if ( id == CONTROL_KEY || id == MASTER_KEY ) return;
        list d = llParseStringKeepNulls(msg, [","], []);
        string location = llList2String(d,0);
        string fname    = llList2String(d,1);
        string message  = llDumpList2String(llList2List(d, 2, -1), ",");
        queue += [llEscapeURL(location) + ">" + llEscapeURL(fname) + ">" + escape(message)];
    }

    timer() {
        if ( queue != [] ) {
            llHTTPRequest( CHAT_URL, [HTTP_METHOD, "POST"], llDumpList2String(queue, "|") );
            queue = [];
        }
    }

}
