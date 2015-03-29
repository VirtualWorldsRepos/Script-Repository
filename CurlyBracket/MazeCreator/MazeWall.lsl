string name;
string rezz;
integer ctrl_channel;
integer ctrl_handle;
vector base;
vector size;
vector pos;
integer u_hi;
integer v_hi;
integer w_hi;
integer notecard_done = 0;
integer texture_done = 0;
key nc_req;
integer w = 0;

default
{
    state_entry()
    {
    }

    on_rez(integer num)
    {
        w = num;
    }

    changed(integer change)
    {
        if (change & CHANGED_INVENTORY) {
            if (
            (llGetInventoryNumber(INVENTORY_TEXTURE) > 0) &&
            (! texture_done)
            ) {
                string name_texture = llGetInventoryName(INVENTORY_TEXTURE, 0);
                llSetTexture(name_texture, 1);
                llSetTexture(name_texture, 3);
                texture_done = 1;
            }
            if (
            (llGetInventoryNumber(INVENTORY_NOTECARD) > 0) &&
            (! notecard_done)
            ) {
                string settings = llGetInventoryName(INVENTORY_NOTECARD, 0);
                nc_req = llGetNotecardLine(settings, 1);
            }
        }
    }

    dataserver(key req, string str)
    {
        if (req == nc_req) {
            list values = llCSV2List(str);
            name = llList2String(values, 1);
            rezz = llList2String(values, 2);
            ctrl_channel = llList2Integer(values, 3);
            base = (vector)llList2String(values, 4);
            size = (vector)llList2String(values, 5);
            u_hi = llList2Integer(values, 6);
            v_hi = llList2Integer(values, 7);
            size.x = size.x*2;
            integer v = llFloor(w/u_hi);
            integer u = w-v*u_hi;
            pos = <
            base.x+size.x/2.0*((float)u-((float)u_hi*0.5-0.5)),
            base.y+size.x/2.0*((float)v-((float)v_hi*0.5-0.5)),
            base.z
            >;
            while (llVecDist(llGetPos(), pos) > 0.01) {
                llSetPos(pos);
            }
            llSetScale(size);
            ctrl_handle = llListen(ctrl_channel, name, NULL_KEY, "");
        }
    }

    listen(integer channel, string from_name, key from_id, string str)
    {
        list values = llCSV2List(str);
        string cmd = llList2String(values, 0);
        integer w1 = llList2Integer(values, 1);
        integer w2 = llList2Integer(values, 2);
        if((cmd == "KILL") && (w >= w1) && (w <= w2)) {
            llDie();
        }
        else if ((cmd == "TURN") && (w >= w1) && (w <= w2)) {
            string data = llList2String(values, 3);
            integer turn = (integer)llGetSubString(data, w-w1, w-w1);
            if ((turn >= 0) && (turn <= 3)) {
                llSetRot(llEuler2Rot(<0.0,0.0,(float)turn*PI_BY_TWO>));
            }
            else if (turn == 4) {
                llDie();
            }
        }
    }
}
