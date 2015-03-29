pop_lock_and_drop_it() {
    llTargetOmega( < 0.0, 0.0, -1.0 > , 1.0, 1.0);
    llSetText(llGetObjectName(), < llFrand(1.0), llFrand(1.0), llFrand(1.0) > , 1);    
}

default {
    on_rez(integer start_param) {
        pop_lock_and_drop_it();
    }
    state_entry() {
        llSetTimerEvent(5);
        llSetMemoryLimit(6000);
        pop_lock_and_drop_it();
    }
    timer() {
        pop_lock_and_drop_it();
    }
}