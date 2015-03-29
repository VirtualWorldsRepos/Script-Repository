integer random_integer(integer min, integer max) {
    return min + (integer)(llFrand(max - min + 1));
}

integer number_of_sounds;
next_loop() {
    string name = llGetInventoryName(INVENTORY_SOUND, random_integer(0, number_of_sounds));
    if (name) {
        key uuid = llGetInventoryKey(name);
        llLoopSound(uuid, 1);
        llSay(0, "Looping: " + name );
    }
}

default {
    on_rez(integer startup) {
        llResetScript();
    }
    state_entry() {
        number_of_sounds = llGetInventoryNumber(INVENTORY_SOUND);
        next_loop();
        llSetMemoryLimit(8000 + (32 * number_of_sounds));
    }

    touch_start(integer total_number) {
        next_loop();
    }
    changed(integer change) {
        if (change & CHANGED_INVENTORY) {
            llResetScript();
        }
    }
}