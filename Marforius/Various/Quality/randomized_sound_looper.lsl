integer random_integer(integer min, integer max) {
    return min + (integer)(llFrand(max - min));
}

integer number_of_sounds;
next_loop() {
    if (number_of_sounds < 1) return;
    string name = llGetInventoryName(INVENTORY_SOUND, random_integer(0, number_of_sounds));
    if (name) {
        key uuid = llGetInventoryKey(name);
        llLoopSound(uuid, 1);
        llSay(0, "Looping: " + name);
    }
}

default {
    on_rez(integer startup) {
        llResetScript();
    }
    state_entry() {
        number_of_sounds = llGetInventoryNumber(INVENTORY_SOUND);
        next_loop();
        llSetMemoryLimit(10000);
    }

    touch_start(integer total_number) {
        next_loop();
    }
    changed(integer change) {
        if (change & CHANGED_INVENTORY) {
            number_of_sounds = llGetInventoryNumber(INVENTORY_SOUND);
        }
    }
}