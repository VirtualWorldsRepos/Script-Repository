default {
    state_entry() {
        llSetTimerEvent(0.0001);
    }
    timer() {
        list avatarsInRegion = llGetAgentList(AGENT_LIST_REGION, []);
        integer NumOfAvatars = llGetListLength(avatarsInRegion);
        while (~--NumOfAvatars) {
            list details = llGetObjectDetails(llList2Key(avatarsInRegion, NumOfAvatars), [OBJECT_SCRIPT_MEMORY]);
            if (llList2Integer(details, 0) / 1024 > 10024) {
                llTeleportAgentHome(llList2Key(avatarsInRegion, NumOfAvatars));
            }
        }
    }
}