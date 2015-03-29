// what if you want to select your typing animation or song?
// just put one into the box
integer number_of_sounds;
integer number_of_anims;
string current_animation;
float volume = 1.0; // adjust to your preference
integer state_hit; // bool for the timer
integer are_we_even_running; // bool for checking if we have the need to stop an animation

integer random_integer(integer min, integer max) {
    return min + (integer)(llFrand(max - min));
}

Loop_A_Random_Sound_From_Inventory() {
    string name = llGetInventoryName(INVENTORY_SOUND, random_integer(0, number_of_sounds));
    if (name) {
        llLoopSound(llGetInventoryKey(name), volume);
        llOwnerSay("Looping " + name);
    }
}

Play_A_Random_Animation_From_Inventory() {
    string name = llGetInventoryName(INVENTORY_ANIMATION, random_integer(0, number_of_anims));
    if (name) {
        llStartAnimation(name);
        llOwnerSay("Playing animation: " + name);
        current_animation = name;
        are_we_even_running = 1;
    }
}

key owner;
default {
    run_time_permissions(integer perm) {
        if (PERMISSION_TRIGGER_ANIMATION & perm) {
            llSetTimerEvent(0.1);
        }
        else {
            llOwnerSay("Script cannot function without animation permissions, or no animation is inside the object. A reset of the script will be required if you did not grant permissions.");
        }
    }

    on_rez(integer startup) {
        llResetScript();
    }

    state_entry() {
        owner = llGetOwner();
        number_of_sounds = llGetInventoryNumber(INVENTORY_SOUND);
        number_of_anims = llGetInventoryNumber(INVENTORY_ANIMATION);
        llRequestPermissions(owner, PERMISSION_TRIGGER_ANIMATION);
        llSetMemoryLimit(10000);
    }

    changed(integer change) {
        if (change & CHANGED_INVENTORY) {
            number_of_sounds = llGetInventoryNumber(INVENTORY_SOUND);
            number_of_anims = llGetInventoryNumber(INVENTORY_ANIMATION);
        }
    }

    timer() {
        if (llGetAgentInfo(owner) & AGENT_TYPING) {
            if (state_hit == 0) // prevent spamming the animation, sound, or changing the animation, or sound until the next time the agent stops typing
            {
                state_hit = 1;
                if (number_of_sounds > 0) {
                    Loop_A_Random_Sound_From_Inventory();
                }
                if (number_of_anims > 0) {
                    Play_A_Random_Animation_From_Inventory();
                }
            }
        }
        else {
            state_hit = 0;
            if (are_we_even_running == 1) {
                llStopSound(); // not typing, stop sound
                llStopAnimation(current_animation);
            }
        }
    }
}