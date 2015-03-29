float length_of_the_sounds = 9;

list music_uuids = [];
integer current_position = -1;
integer total_positions;

default {
    on_rez(integer unused) {
        llResetScript();
    }
    state_entry() {
        integer items_contained = llGetInventoryNumber(INVENTORY_SOUND);
        integer iterator;

        while (~--items_contained) {
            string current_name = llGetInventoryName(INVENTORY_SOUND, iterator);
            music_uuids += (string) llGetInventoryKey(current_name);
            iterator++;
        }

        llSetTimerEvent(length_of_the_sounds); // begin timer to circumvent the sleep in the preload
        total_positions = (llGetListLength(music_uuids));
        while (~--total_positions) {
            llPreloadSound(llList2Key(music_uuids, total_positions));
        }
        total_positions = (llGetListLength(music_uuids) - 2); // we cut two positions off to account for modulus starting the iteration at -1 and restarting the iteration at the second to last clip
    }

    timer() {
        current_position++;
        //llSay(0, " playing " + llList2String(music_uuids, current_position) + " #" + (string) current_position + " maximum positions = " + (string) total_positions); // debug
        llPlaySound(llList2Key(music_uuids, current_position), 1.0);
        if (current_position > total_positions) {
            current_position = -1;
        }
        llPreloadSound(llList2Key(music_uuids, current_position + 1));
    }
}