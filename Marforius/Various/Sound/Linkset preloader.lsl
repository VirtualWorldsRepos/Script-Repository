default {
    on_rez(integer unused) {
        llResetScript();
    }
    state_entry() {
        llStopSound();
        llSetMemoryLimit(6194);
    }
    link_message(integer s, integer n, string str, key id) {
        if (str == "PRELOAD") {
            llPreloadSound(id);
        }
    }
}