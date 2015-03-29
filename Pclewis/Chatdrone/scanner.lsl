// channel that scanners announce scanned agents on
integer CHANNEL = -12610672;

default {
    state_entry() {
        llSensorRepeat("", NULL_KEY, AGENT, 96, PI, 10.0);
    }

    sensor(integer num) {
        string str;
        while ( num-- )
            str += (string)llDetectedKey(num) + ",";
        llRegionSay(CHANNEL, str);
    }
}

