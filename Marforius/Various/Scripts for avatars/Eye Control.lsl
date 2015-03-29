integer LIDDEDNESS = 6060;
integer LOWERLID = 6070;
integer SMILE = 6103;
integer BROWS = 6080;
integer BLINKING_ACTIVE = 6600;
integer EYELASHES_ACTIVE = 6500;

integer blinking_active = TRUE;
integer eyelashes_active = TRUE;

integer blink_state = 1;
integer blink_in_progress;
integer dont_skip_closed_frame;

integer i;

integer link_lower_eyelid;
integer link_eyelashes_right;
integer link_eyelashes_left;

integer unique_channel;

float t;

float last_time;
integer frame;

list eyelid_frames = 
        ["bda0a74a-b9bd-06a4-1175-f57e5b35d0d7",
         "7ef640ea-90a7-a495-5b53-c85181242d7d",
         "86f4d3fc-6774-9d0d-548a-7ecd31f8116a", 
         "6caaec5b-5a2d-6c04-8f18-6933a02d33f8", 
         "aeaa4be2-dc27-c3b9-71f0-738a1e2cb638", 
         "082d14f1-1fbc-bbe0-c743-327e7bbe28e3", 
         "982e537d-06bf-6080-bc4b-6e7bc277eccb",
         "b644b776-74da-a83d-f628-46c5d2dd2874"];

list lower_eyelid_frames =
        ["a4bc4579-4edd-6b17-b59a-be00ef4d3dfe",
         "b2a66674-447b-8592-8a40-af974c188f51",
         "b47d81e8-0ef1-540b-3bb2-ee4f733c0df5"];

list eyelashes =
        ["1715664d-d2f4-5fd2-a823-2193b3aa0214",
         "2d214bba-4af7-7589-5886-3330c1d319be",
         "c7e6015a-496b-0668-018c-8d94898dc74c",
         "41dea503-f4ea-6fe9-64be-a10dc6afecb8"];

setEyeframe(integer frame)
{
    llSetLinkPrimitiveParamsFast(LINK_THIS, [PRIM_TYPE, PRIM_TYPE_SCULPT, llList2Key(eyelid_frames, frame), PRIM_SCULPT_TYPE_CYLINDER | PRIM_SCULPT_FLAG_INVERT]);
    
    if(eyelashes_active)
    {
        llSetLinkTextureAnim(link_eyelashes_left, ANIM_ON | SMOOTH | LOOP, 0, 0,0,0.4375 - (0.125 * (float)frame),0.00001,0.1);
        llSetLinkTextureAnim(link_eyelashes_right, ANIM_ON | SMOOTH | LOOP, 0, 0,0,0.4375 - (0.125 * (float)frame),0.00001,0.1);
    }
}

setLowerlid(integer num)
{
    if(num != 0)
    {
        llSetLinkAlpha(link_lower_eyelid, 1.0, ALL_SIDES);
        llSetLinkPrimitiveParamsFast(link_lower_eyelid, [PRIM_TYPE, PRIM_TYPE_SCULPT, llList2Key(lower_eyelid_frames, num - 1), PRIM_SCULPT_TYPE_PLANE | PRIM_SCULPT_FLAG_INVERT]);
    }
    else
        llSetLinkAlpha(link_lower_eyelid, 0.0, ALL_SIDES);
    
    llSetLinkPrimitiveParamsFast(link_eyelashes_right, [PRIM_TYPE, PRIM_TYPE_SCULPT, llList2Key(eyelashes, num), PRIM_SCULPT_TYPE_PLANE | PRIM_SCULPT_FLAG_INVERT | PRIM_SCULPT_FLAG_MIRROR]);
    llSetLinkPrimitiveParamsFast(link_eyelashes_left, [PRIM_TYPE, PRIM_TYPE_SCULPT, llList2Key(eyelashes, num), PRIM_SCULPT_TYPE_PLANE | PRIM_SCULPT_FLAG_INVERT]);
    
}

integer find_target(string target_name)
{
    integer i;
    
    for(i = 0; i <= llGetNumberOfPrims(); ++i)
        if(target_name == llGetLinkName(i))
            return i;
    
    llOwnerSay("'" + target_name + "' target not found.");
    return -99;
}

takeControls()
{
    if(llGetPermissions() & PERMISSION_TAKE_CONTROLS)
        llTakeControls(CONTROL_UP, TRUE, TRUE);
    else
        llRequestPermissions(llGetOwner(), PERMISSION_TAKE_CONTROLS);
}

default
{
    state_entry()
    {
        llSetMemoryLimit(36000);
        llListen(1, "", llGetOwner(), "");
        llListen(unique_channel = (integer)("0xF" + llGetSubString(llGetOwner(), 0, 6)), "", "", "");
        
        link_lower_eyelid = find_target("eyelids.lower");
        link_eyelashes_right = find_target("eyelashes.right");
        link_eyelashes_left = find_target("eyelashes.left");
        
        if(!llGetAttached())
        {
            llSetLinkTextureAnim(link_eyelashes_left, 0, 0, 0,0,-0.4375 + (0.125 * (float)frame),0.00001,0.1);
            llSetLinkTextureAnim(link_eyelashes_right, 0, 0, 0,0,-0.4375 + (0.125 * (float)frame),0.00001,0.1);            
            llSetTimerEvent(0.0);
        }
        else if(link_lower_eyelid != -99)
        {
            takeControls();
            llSetTimerEvent(0.1);
        }
    }
    
    changed(integer change)
    {
        if(change & CHANGED_LINK)
        {
            link_lower_eyelid = find_target("eyelids.lower");
            link_eyelashes_right = find_target("eyelashes.right");
            link_eyelashes_left = find_target("eyelashes.left");
        }
        else if(change & CHANGED_OWNER)
            llResetScript();
    }
    
    on_rez(integer param)
    {
        if(!llGetAttached()) 
            llSetTimerEvent(0.0);
        else
        {
            takeControls();
            llSetTimerEvent(0.1);
        }
    }
    
    run_time_permissions(integer perm)
    {
        if(perm & PERMISSION_TAKE_CONTROLS)
            llTakeControls(CONTROL_UP, TRUE, TRUE);
    }
    
    listen(integer channel, string name, key id, string msg)
    {
        if(!llGetAttached() || llGetOwnerKey(id) != llGetOwner())
            return;
        
        if(channel == unique_channel && (integer)msg == 89901)
        {
            if(blink_state < 8)
                llSetTimerEvent(0.0001);
                
            return;
        }
        
        if(channel == 1)
        {
            if(llSubStringIndex(msg, "eyes ") == 0)
            {
                string args = llGetSubString(msg, 5, -1);
    
                integer arg1 = (integer)llGetSubString(msg, 5, 5);
                string arg2 = llGetSubString(msg, 6, 6);
    
                if(arg1)
                {
                    if(arg1 >= 1 && arg1 <= 7)
                    {
                        blink_state = arg1;
                        setEyeframe(arg1 - 1);
                        llSetTimerEvent(2.0);
                    }
                    else if(arg1 == 8)
                    {
                        blink_state = arg1;
                        llSetTimerEvent(0.0);
                        
                        setEyeframe(7);
                    }
                    
                    if(arg2 != "" && link_lower_eyelid != -99)
                    {
                        if(arg2 == "a")
                            setLowerlid(0);
                        else if(arg2 == "b")
                            setLowerlid(1);
                        else if(arg2 == "c")
                            setLowerlid(2);
                        else if(arg2 == "d")
                            setLowerlid(3);
                    }
                    
                    t = llGetTimeOfDay();
                }
            }
        }
        else if(channel == unique_channel)
        {
            integer code = (integer)msg;
            list data = llParseString2List(msg, ["|"], [""]);
            
            if(code == LIDDEDNESS)
            {
                integer liddedness = (integer)llList2String(data, 1);
                
                blink_in_progress = FALSE;
                
                if(liddedness >= 1 && liddedness <= 8)
                {
                    blink_state = liddedness;
                    setEyeframe(blink_state - 1);
                    llSetTimerEvent(0.0);
                    llSetTimerEvent(2.0);
                }
                else if(liddedness == 8)
                {
                    blink_state = liddedness;
                    setEyeframe(blink_state - 1);
                    llSetTimerEvent(0.0);
                    
                    setEyeframe(8);
                }
            }
            else if(code == LOWERLID && link_lower_eyelid != -99)
            {
                integer lowerlid_frame = (integer)llList2String(data, 1);
                
                setLowerlid(lowerlid_frame);
            }
            else if(code == EYELASHES_ACTIVE)
            {
                integer status = (integer)llList2String(data, 1);
            
                eyelashes_active = status;
                
                if(!eyelashes_active)
                {
                    llSetLinkAlpha(link_eyelashes_right, 0.0, ALL_SIDES);
                    llSetLinkAlpha(link_eyelashes_left, 0.0, ALL_SIDES);
                }
                else
                {
                    llSetLinkAlpha(link_eyelashes_right, 0.99, ALL_SIDES);
                    llSetLinkAlpha(link_eyelashes_left, 0.99, ALL_SIDES);
                }
            }
            else if(code == BLINKING_ACTIVE)
            {
                integer status = (integer)llList2String(data, 1);
            
                blinking_active = status;
            
                if(blinking_active)
                    llSetTimerEvent(0.1);
                else if(!blink_in_progress)
                    llSetTimerEvent(0.0);
            }
        }
    }
    
    timer()
    {
        if(!blink_in_progress)
        {
            blink_in_progress = TRUE;
            last_time = 0.0;
            frame = blink_state - 1;
            dont_skip_closed_frame = TRUE;
            
            //llOwnerSay("!blink_in_progress - " + (string)frame);
    
            setEyeframe(frame);
            ++frame;
            
            llResetTime();
            llSetTimerEvent(0.044);
            jump end;
        }
         
        float time_elapsed = (llGetTime() - last_time);
        integer frame_skip = (integer)(time_elapsed / 0.04);

        if(frame_skip > 0)
        {
            frame += frame_skip;
            last_time = llGetTime();
        }
        else
            jump end;
        
        if(dont_skip_closed_frame && frame >= 8)
        {
            dont_skip_closed_frame = FALSE;
            frame = 9;
            //llOwnerSay("dont_skip_closed_frame - " + (string)(7 - llAbs(frame - 8)));
            setEyeframe(7 - llAbs(frame - 8));
            llSleep(0.14);
            last_time = llGetTime();
            jump end;
        }

        if(frame >= 15 - (blink_state - 1))
        {
            frame = 15 - (blink_state - 1);
            blink_in_progress = FALSE;
           // llOwnerSay("--------");
        }
        //llOwnerSay("main - " + (string)(7 - llAbs(frame - 8)) + " -   " + (string)time_elapsed);
        setEyeframe(7 - llAbs(frame - 8));
        
        if(!blink_in_progress)
        {
            llSetTimerEvent(llFrand(4)+1.5);
           
            if(!blinking_active)
                llSetTimerEvent(0.0);
        }
            
        @end;
    }
}
