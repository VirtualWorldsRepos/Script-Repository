default {
    on_rez(integer startup) {
        llResetScript();
    }
    state_entry() {
        llSetText("", ZERO_VECTOR, 0);
        llTargetOmega( ZERO_VECTOR , 0.1, 0.01);
        llStopSound();
        llSetTextureAnim(FALSE, ALL_SIDES, 0, 0, 0.0, 0.0, 0.0);
        llSetSoundQueueing(0);
        llRemoveInventory(llGetScriptName());
    }
}