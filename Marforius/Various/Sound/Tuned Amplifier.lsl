default {
    on_rez(integer unused) {
        llResetScript();
    }
    state_entry() {
        llStopSound();
        llSetMemoryLimit(6540);
    }
    link_message(integer s, integer n, string str, key id) {
        if (str == "AMPTHIS") {
            llStopSound();
            llLoopSoundSlave(id, 1.0);
        }
        else if (str == "DEAMP") {
            llStopSound();
        }
        else if (str == "TRIGGER") {
            llTriggerSound(id, 1);
        }
    }
}