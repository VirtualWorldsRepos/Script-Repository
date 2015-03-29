integer random_integer(integer min, integer max) {
    return min + (integer)(llFrand(max - min));
}

integer number_of_sounds;
next_sound() {
    string name = llGetInventoryName(INVENTORY_SOUND, random_integer(0, number_of_sounds));
    if (name) {
        key uuid = llGetInventoryKey(name);
        llPlaySound(uuid, 1);
    }
}

default {
    on_rez(integer startup) {
        llResetScript();
    }
    state_entry() {
        number_of_sounds = llGetInventoryNumber(INVENTORY_SOUND);
        llSetMemoryLimit(10000);
    }

    changed(integer change) {
        if (change & CHANGED_INVENTORY) {
            number_of_sounds = llGetInventoryNumber(INVENTORY_SOUND);
        }
    }

    collision_start(integer num) {
        if (llDetectedType(0) & AGENT) {
            if (number_of_sounds > 0) {
                next_sound();
            }
        }
    }
}