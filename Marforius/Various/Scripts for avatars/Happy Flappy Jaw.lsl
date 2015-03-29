
rotation one;
rotation two;

rotation set_rot;

integer flip;

integer tongue;

integer UP = 5125;
integer DOWN = 5126;
integer MM_VOICE = 6100;
integer MM_TYPING = 6101;
integer MM_OTHER = 6102;
integer MOUTH_OPEN = 6300;
integer MOUTH_FLAP = 6400;

integer tongue_click;
integer tongue_up;

rotation tongue_rot_up;
rotation tongue_rot_down;

rotation start_rot;

float scale;

string CONFIG_CARD = "Mouth Movement UUIDs";

integer NotecardLine;
key QueryID;

list voice = [  "3557510a-5eb4-d0ce-0b91-67c72aa75312",
                "2b78c24a-2451-6135-fc49-ad274552bb68",
                "0f645c60-3151-2805-b6f7-28e710ed22ac",
                "9a7f3201-7bbd-4f75-b762-24270536e4e3",
                "68db359f-4c9c-0932-5f1e-e95e3a0b19bc",
                "7ef0d5c0-3346-06e4-5cfc-f081db108baa",
                "37694185-3107-d418-3a20-0181424e542d",
                "cb1139b6-e7c3-fdc7-a9c1-e21673d7a50e",
                "28a3f544-268d-da71-7da6-82c8dd522cb9",
                "cc340155-3e9d-60fe-d8e3-9e9abc7062d1",
                "bbf194d1-a118-1312-998b-8145cec6eaff",
                "a71890f1-0dab-8744-fd47-7defaf411dbf",
                "593e9a3d-58d8-c594-d6dd-f4b98965202e",
                "55fe6788-8a16-d998-2f63-3c1eab2b6009",
                "c1802201-5f4e-366f-7f78-2d08ec6ea54a",
                "69d5a8ed-9ec6-6dac-842f-d92d82e69428",
                "951070f8-00fc-d3bd-813d-bd2922464246"];
                
list typing = [ "c541c47f-e0c0-058b-ad1a-d6ae3a4584d9"];
list other =  [];

integer VOICE = 8;
integer TYPING = 16;
integer OTHER = 32;

integer keyType = VOICE;

integer mm_options = 56; // VOICE + TYPING + OTHER

integer animation_perm;

list playing_anims;

integer speech_detection()
{
    playing_anims = llGetAnimationList(llGetOwner());
    integer i = llGetListLength(playing_anims);
    integer j;
    
    integer result;
    
    list new_list;

    if(mm_options & VOICE)
        new_list += voice;
    if(mm_options & TYPING)
        new_list += typing;
    if(mm_options & OTHER)
        new_list += other;

    for(j = 0; j < i; ++j)
    {
        result = llListFindList(new_list, [llList2String(playing_anims, j)]);
        
        if(result != -1)
            return TRUE;
    }
    
    return FALSE;
}

mouth_flap()
{
    float blah = llFrand(0.6) + 0.4;
    
    if(flip)
    {
        llRotLookAt(one, 1.0, 1.0);
        llSleep(0.12);
        
        if(++tongue_click >= 1)
        {
            llSetLinkPrimitiveParamsFast(tongue, [PRIM_ROTATION, tongue_rot_up / llGetLocalRot(), PRIM_TEXT, " ", <0,0,llFrand(1.0)>, 1.0, PRIM_POSITION, <0.03389, 0.00000, -0.02295> * scale]);
            
            tongue_click = 0;
            tongue_up = TRUE;
        }
    }
    else
    {
        llRotLookAt(slerp(blah / 2.0, one, two), 1.0, 1.0);
        llSleep(0.02);
        
        if(tongue_up)
        {
            llSetLinkPrimitiveParamsFast(tongue, [PRIM_ROTATION, tongue_rot_down / llGetLocalRot(), PRIM_POSITION, <0.020, 0.00000, -0.033> * scale]);
            tongue_up = FALSE;
        }
        
        llRotLookAt(slerp(blah, one, two), 1.0, 1.0);
        llSleep(llFrand(0.035) + 0.08);
    }
    
    flip = !flip;
}

integer cfIsKey(key shadow)
{
    if (llStringLength(shadow) != 36) {
        return 0;
    }
    
    if (!(isHyphen(shadow, 8) && isHyphen(shadow, 13) && isHyphen(shadow, 18) && isHyphen(shadow,23))) {
        return 0;
    }
    
    return 1;                
}

integer isHyphen(string x, integer pos)
{
    if (llGetSubString(x,pos,pos) == "-")
        return 1;
    return 0;
}

rotation slerp(float u, rotation rot_a, rotation rot_b)
{
    // cosine theta = dot product of rot_a and rot_b
    float cos_t = rot_a.x * rot_b.x + rot_a.y * rot_b.y + rot_a.z * rot_b.z + rot_a.s * rot_b.s;
    
    // if b is on opposite hemisphere from a, use -a instead
    integer bflip;
    
    if (cos_t < 0.0)
    {
        cos_t = -cos_t;
        bflip = TRUE;
    }
    else
        bflip = FALSE;

    // if B is (within precision limits) the same as A,
    // just linear interpolate between A and B.
    float alpha;    // interpolant
    float beta;        // 1 - interpolant
    if (1.0 - cos_t < 0.00001)
    {
        beta = 1.0 - u;
        alpha = u;
     }
    else
    {
         float theta = llAcos(cos_t);
         float sin_t = llSin(theta);
         beta = llSin(theta - u * theta) / sin_t;
         alpha = llSin(u * theta) / sin_t;
     }

    if (bflip)
        beta = -beta;

    // interpolate
    rotation ret;
    
    ret.x = beta*rot_a.x + alpha*rot_b.x;
    ret.y = beta*rot_a.y + alpha*rot_b.y;
    ret.z = beta*rot_a.z + alpha*rot_b.z;
    ret.s = beta*rot_a.s + alpha*rot_b.s;

    return ret;
}

integer find_target(string target_name)
{
    integer i;
    
    for(i = 0; i <= llGetNumberOfPrims(); ++i)
        if(target_name == llGetLinkName(i))
            return i;
    
    llOwnerSay("'" + target_name + "' target not found.");
    return 1024;
}

initialize()
{
    //if(llGetPermissions() & PERMISSION_TAKE_CONTROLS && llGetPermissions() & PERMISSION_TRIGGER_ANIMATION)
    //    llTakeControls(1024, TRUE, TRUE);
    //else
        llRequestPermissions(llGetOwner(), PERMISSION_TAKE_CONTROLS | PERMISSION_TRIGGER_ANIMATION);
}

integer hListen;
integer unique_channel;

activateListen()
{
    unique_channel = (integer)("0xF" + llGetSubString(llGetOwner(), 0, 6));
    
    if(hListen)
    {
        llListenRemove(hListen);
        hListen = 0;
    }
    
    hListen = llListen(unique_channel, "", "", "");
}

default
{
    state_entry()
    {
        if(llGetInventoryType(CONFIG_CARD) == INVENTORY_NOTECARD)
        {
            NotecardLine = 0;
            QueryID = llGetNotecardLine( CONFIG_CARD, NotecardLine );
            llOwnerSay("Configuration in process -- reading notecard.");
            
            voice = [];
            typing = [];
            other = [];
        }
        else
        {
            llOwnerSay("'" + CONFIG_CARD + "'" + " not found, using default values.");
            state running;
        }
        
        vector root_size = llGetScale();
        scale = 0.015 / root_size.x;
    }
    
    dataserver(key queryid, string data)
    {
        if(queryid == QueryID)
        {
            if(data != EOF)
            {
                if(llGetSubString(data, 0, 0) == "[" && llGetSubString(data, -1, -1) == "]")
                {
                    string newType = llGetSubString(data, 1, -2);

                    if(newType == "VOICE")
                        keyType = VOICE;
                    else if(newType == "TYPING")
                        keyType = TYPING;
                    else if(newType == "OTHER")
                        keyType = OTHER;
                }
                else if(cfIsKey(data))
                {
                    if(keyType == VOICE)
                        voice += data;
                    else if(keyType == TYPING)
                        typing += data;
                    else if(keyType == OTHER)
                        other += data;
                }
                
                ++NotecardLine;
                QueryID = llGetNotecardLine( CONFIG_CARD, NotecardLine );
            }
            else
            {
                llOwnerSay("Configuration complete.");
                state running;
            }
        }
    }
}
           
state running
{
    state_entry()
    {
        llSetTimerEvent(0.1);
        
        //one = llEuler2Rot(<270, 0, 180> * DEG_TO_RAD);
        two = llEuler2Rot(<0, 25, 0> * DEG_TO_RAD);
        tongue_rot_up = llEuler2Rot(<180, 295, 270> * DEG_TO_RAD);
        tongue_rot_down = llEuler2Rot(<0, 270, 90> * DEG_TO_RAD);        
        
        tongue = find_target("tongue");
        
        if(llGetAttached())
            initialize();
            
        activateListen();
    }
        
    run_time_permissions(integer perm)
    {
        //if(perm & PERMISSION_TAKE_CONTROLS)
        //    llTakeControls(1024, TRUE, TRUE);
            
        if(perm & PERMISSION_TRIGGER_ANIMATION)
            animation_perm = TRUE;
        else
            animation_perm = FALSE;
    }
    
    on_rez(integer param)
    {
        if(llGetAttached())
            initialize();
        
        activateListen();
    }
    
    listen(integer channel, string name, key id, string msg)
    {
        if(!llGetAttached() || llGetOwnerKey(id) != llGetOwner())
            return;
        
        integer code = (integer)msg;
        list data = llParseString2List(msg, ["|"], [""]);
        
        if(code == MM_VOICE)
        {
            if((integer)llList2String(data, 1) == TRUE)
                mm_options = mm_options | VOICE;
            else
                mm_options = mm_options ^ VOICE;
        }
        else if(code == MM_TYPING)
        {
            if((integer)llList2String(data, 1) == TRUE)
                mm_options = mm_options | TYPING;
            else
                mm_options = mm_options ^ TYPING;
        }
        else if(code == MM_OTHER)
        {
            if((integer)llList2String(data, 1) == TRUE)
                mm_options = mm_options | OTHER;
            else
                mm_options = mm_options ^ OTHER;
        }
        else if(code == MOUTH_FLAP)
        {
            if((integer)llList2String(data, 1) == TRUE)
                mouth_flap();
                llSleep(0.5);
                llRotLookAt(set_rot, 1.0, 1.0);
                llSetLinkPrimitiveParamsFast(tongue, [PRIM_ROTATION, tongue_rot_down / llGetLocalRot(), PRIM_POSITION, <0.020, 0.00000, -0.033> * scale]);
        }
        else if(code == MOUTH_OPEN)
        {
            float value = (float)llList2String(data, 1);
            
            llSetTimerEvent(0.1);
            llSetLinkPrimitiveParamsFast(LINK_THIS, [PRIM_ROTATION, set_rot = slerp(value, one, two)]);            
            //llRotLookAt(set_rot = slerp(value, one, two), 1.0, 1.0);
            
            if(tongue_up)
            {
                llSetLinkPrimitiveParamsFast(tongue, [PRIM_ROTATION, tongue_rot_down / llGetLocalRot(), PRIM_POSITION, <0.020, 0.00000, -0.033> * scale]);
                tongue_up = FALSE;
            }

            llSetText(" ", <0,0,llFrand(1.0)>, 0.0);
            
//            if(set_rot == ZERO_ROTATION)
//                llSetText(" ", <0,0,llFrand(1.0)>, 1.0);
        }
    }
         
    timer()
    {
        if(llGetRegionTimeDilation() < 0.9)
        {
            llSetTimerEvent(1.0);
        }
        else
        {
            llSetTimerEvent(0.1);
        }
        
        if(llGetAgentInfo(llGetOwner()) & AGENT_TYPING && (mm_options & TYPING))
        {
            //start_rot = llGetLocalRot();
            
            do
            {
                mouth_flap();
            }
            while(llGetAgentInfo(llGetOwner()) & AGENT_TYPING);
            
            llRotLookAt(set_rot, 1.0, 1.0);
            llSetLinkPrimitiveParamsFast(tongue, [PRIM_ROTATION, tongue_rot_down / llGetLocalRot(), PRIM_POSITION, <0.020, 0.00000, -0.033> * scale]);

            flip = FALSE;
        }
        else
        {
            if(speech_detection())
            {
                //start_rot = llGetLocalRot();
                
                do
                {
                    mouth_flap();
                }
                while(speech_detection());
                
                llRotLookAt(set_rot, 1.0, 1.0);
                llSetLinkPrimitiveParamsFast(tongue, [PRIM_ROTATION, tongue_rot_down / llGetLocalRot(), PRIM_POSITION, <0.020, 0.00000, -0.033> * scale]);                
                
                flip = FALSE;
            }
        }
    }
}