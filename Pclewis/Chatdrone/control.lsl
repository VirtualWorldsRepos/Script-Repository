///////////////////////////////////////////////////////////
// Constants
///////////////////////////////////////////////////////////
// Full path for control connection
string  CONTROL_URL     = "http://nagisa.w-hat.com:54000/control?last=";

// channel to listen for chat on
integer CHAT_CHANNEL   = -12610671;

// Seconds until a request times out
integer REQUEST_TIMEOUT = 70;

// Minimum seconds between http requests
integer REQUEST_DELAY   = 1;

// Time to wait after a failed request. Doubles with each failure up to MAX.
integer REQUEST_RETRY_START = 10;
integer REQUEST_RETRY_MAX   = 80;

///////////////////////////////////////////////////////////
// Globals
///////////////////////////////////////////////////////////
// unixtime we can send the next request
integer next_request = 0;

// unixtime when the current request will timeout
integer timeout = 0;

integer retry = REQUEST_RETRY_START;

// last message we got from the server
integer last_message  = 0;

// whether a control connection is open
integer connection_open = FALSE;

// current control connection id
key     request_id = NULL_KEY;

// Set the timer based on when we can make a new request, or when the
// current request times out.
set_timer() {
    float t;
    if ( connection_open ) {
        t = timeout - llGetUnixTime();
    } else {
        t = next_request - llGetUnixTime();
    }
    if ( t < 0.1 ) t = 0.1;
    llSetTimerEvent(t);
}

// Try to open a control connection.
integer try_request() {
    if ( connection_open )
        return FALSE;
    if ( llGetUnixTime() < next_request ) {
        return FALSE;
    }
    next_request    = llGetUnixTime() + REQUEST_DELAY;
    timeout         = llGetUnixTime() + REQUEST_TIMEOUT;
    request_id      = llHTTPRequest( CONTROL_URL + (string)last_message, [], "" );
    connection_open = TRUE;
    return TRUE;
}

default {
    state_entry() {
        llOwnerSay("CONTROL KEY:" + (string)llGetKey());
        try_request();
        set_timer();
    }

    timer() {
        llSetTimerEvent(0.0); // don't queue more timer events
        if ( connection_open && llGetUnixTime() > timeout ) {
            connection_open = FALSE;
            request_id = NULL_KEY;
        }
        try_request();
        set_timer();
    }

    http_response(key reqid, integer status, list meta, string body) {
        if ( reqid != request_id )
        return;

        connection_open = FALSE;

        if ( status == 200 && body != "" ) {
        list data = llParseString2List(body, ["|"], []);
        last_message = (integer)llList2String(data,0);
        integer i = llGetListLength(data);
        while (--i) {
            list message = llParseString2List( llList2String(data, i), [">"], [] );
            llRegionSay(CHAT_CHANNEL, 
                llUnescapeURL(llList2String(message,0)) + "," +
                llUnescapeURL(llList2String(message,1)) + "," +
                llUnescapeURL(llList2String(message,2))
            );
        }
        retry = REQUEST_RETRY_START;
        } else if ( status != 200 ) {
        next_request = llGetUnixTime() + retry;
        if ( retry < REQUEST_RETRY_MAX )
            retry *= 2;
        }

        try_request();
        set_timer();
    }
}

