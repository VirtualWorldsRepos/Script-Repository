list people_to_whisper = [
    "a91bbf72-260c-4cd0-9106-af37e057cb63"
];

string wwGetSLUrl() {
    string globe = "http://maps.secondlife.com/secondlife";
    string region = llGetRegionName();
    vector pos = llGetPos();
    string posx = (string) llRound(pos.x);
    string posy = (string) llRound(pos.y);
    string posz = (string) llRound(pos.z);
    return (globe + "/" + llEscapeURL(region) + "/" + posx + "/" + posy + "/" + posz);
}

blow_the_horn() {
    integer legnth = llGetListLength(people_to_whisper);
    while (~--legnth) {
        llInstantMessage(llList2Key(people_to_whisper, legnth), "[" + wwGetSLUrl() + " " + llGetRegionName() + "] was restarted at " + fStrGMTwOffset(-8) + " SLT, and is now back online");
    }
}



string last_restart;
string since;
integer amount_of_restarts = 0;

integer gIntMinute = 60; //-- 1 minute in seconds
integer gIntHour = 3600; //-- 1 hour in seconds
integer gInt12Hr = 43200; //-- 12hrs in seconds
integer gIntDay = 86400; //-- 1 day in seconds

string fStrGMTwOffset(integer vIntLocalOffset) {
    //-- get the correct time in seconds for the given offset
    integer vIntBaseTime = ((integer) llGetGMTclock() + gIntDay + vIntLocalOffset * gIntHour) % gIntDay;
    string vStrReturn;

    //-- store morning or night and reduce to 12hour format if needed
    if (vIntBaseTime < gInt12Hr) {
        vStrReturn = " AM";
    } else {
        vStrReturn = " PM";
        vIntBaseTime = vIntBaseTime % gInt12Hr;
    }

    //-- get and format minutes
    integer vIntMinutes = (vIntBaseTime % gIntHour) / gIntMinute;
    vStrReturn = (string) vIntMinutes + vStrReturn;
    if (10 > vIntMinutes) {
        vStrReturn = "0" + vStrReturn;
    }

    //-- add in the correct hour, force 0 to 12
    if (vIntBaseTime < gIntHour) {
        vStrReturn = "12:" + vStrReturn;
    } else {
        vStrReturn = (string)(vIntBaseTime / gIntHour) + ":" + vStrReturn;
    }
    return vStrReturn + " " + llGetDate();
}

rest_in_peace() {

    llSetText(
        "Started watch at: " + since + " SLT \n" + "Times restarted: " + (string) amount_of_restarts + "\n" +
        "Last restart was at: " + last_restart, < 1.0, 1.0, 1.0 > , 1);
    blow_the_horn();
}

clean_sweep() {
    llSetText("Started watch at: " + since + " SLT \n" + "Sim has not crashed yet", < 1.0, 1.0, 1.0 > , 1);
}

default {
    on_rez(integer start_param) {
        llResetScript();
    }

    state_entry() {
        since = fStrGMTwOffset(-8);
        clean_sweep();
    }


    changed(integer change) {
        if (change & CHANGED_REGION_START) {
            last_restart = fStrGMTwOffset(-8);
            rest_in_peace();
        }
    }
}