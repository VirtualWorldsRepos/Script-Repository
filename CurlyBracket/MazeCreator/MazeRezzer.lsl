string settings = "Maze Settings";
string name;
string rezz;
integer ctrl_channel;
vector base;
vector size;
integer u_hi;
integer v_hi;
integer w_hi;
list u_move = [1, 0, -1, 0];
list v_move = [0, 1, 0, -1];
list maze =[];
key nc_req;
integer w = 0;

default
{
    state_entry()
    {
        llSetText("Maze Builder", <1.0,0.8,0.0>, 1.0);
        llOwnerSay("Initializing Maze Rezzer");
        nc_req = llGetNotecardLine(settings, 1);
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
            llOwnerSay("name: "+name+
            "\nrezz: "+rezz+
            "\nctrl: "+(string)ctrl_channel+
            "\nbase: "+(string)base+
            "\nsize: "+(string)size+
            "\nx-repeats: "+(string)u_hi+
            "\ny-repeats: "+(string)v_hi);
            w_hi = u_hi*v_hi;
            llSetObjectName(name);
            llOwnerSay("Maze Rezzer initialized");
        }
    }

    touch_start(integer num)
    {
        if (1 || llDetectedKey(0) == llGetOwner()) {
            llOwnerSay("Creating Maze");
            string maze1 = "";
            integer u = 0;
            for (; u < u_hi; u++) {
                maze1 += "4";
            }
            maze = [];
            integer v = 0;
            for (; v < v_hi; v++) {
                maze += [maze1];
            }
            u = llFloor(u_hi/2);
            v = llFloor(v_hi/2);
            integer a = 1;
            integer n = 4;
            while (n > 0) {
                integer a1 = llFloor(llFrand(4.0));
                n = 4;
                while (n > 0 && (integer)llGetSubString(llList2String(maze, v), u, u) == 4) {
                    integer u1 = u+llList2Integer(u_move, a1);
                    integer v1 = v+llList2Integer(v_move, a1);
                    while (
                    u1 >= 0 && u1 < u_hi &&
                    v1 >= 0 && v1 < v_hi &&
                    (integer)llGetSubString(llList2String(maze, v1), u1, u1) != 4 && (
                    u1 != u ||
                    v1 != v
                    )
                    ) {
                        integer a2 = (integer)llGetSubString(llList2String(maze, v1), u1, u1);
                        u1 += llList2Integer(u_move, a2);
                        v1 += llList2Integer(v_move, a2);
                    }
                    if (u1 != u || v1 != v) {
                        if ((v == 0) && (u != v_hi-1)) {
                            a1 = 0;
                        }
                        else if ((u == u_hi-1) && (v != v_hi-1)) {
                            a1 = 1;
                        }
                        else if ((v == v_hi-1) && (u != 0)) {
                            a1 = 2;
                        }
                        else if ((u == 0) && (v != 0)) {
                            a1 = 3;
                        }
                        maze = llListInsertList(llDeleteSubList(maze, v, v), [llInsertString(llDeleteSubString(llList2String(maze, v), u, u), u, (string)a1)], v);
                    }
                    a1++;
                    if (a1 > 3) {
                        a1 = a1-4;
                    }
                    n--;
                }
                a1 = a+1;
                if (a1 > 3) {
                    a1 = a1-4;
                }
                integer u1 = u+llList2Integer(u_move, a1);
                integer v1 = v+llList2Integer(v_move, a1);
                n = 4;
                while (
                n > 0 && (
                u1 < 0 || u1 >= u_hi ||
                v1 < 0 || v1 >= v_hi ||
                (integer)llGetSubString(llList2String(maze, v1), u1, u1) != 4
                )
                ) {
                    a1--;
                    if (a1 < 0) {
                        a1 = a1+4;
                    }
                    u1 = u+llList2Integer(u_move, a1);
                    v1 = v+llList2Integer(v_move, a1);
                    n--;
                }
                // llOwnerSay("("+(string)u+","+(string)v+"): "+llList2CSV(maze));
                if (n > 0) {
                    a = a1;
                    u = u1;
                    v = v1;
                }
            }
            llOwnerSay("Maze created:\n"+llList2CSV(maze));
            
            w = 0;
            llRegionSay(ctrl_channel, "KILL,0,65536");
            llOwnerSay("Rezzing Maze");
            llRezObject(rezz, llGetPos()+<0.0,0.0,1.0>, ZERO_VECTOR, ZERO_ROTATION, w);
        }
    }

    object_rez(key rez_key)
    {
        integer n_texture = llGetInventoryNumber(INVENTORY_TEXTURE);
        if (n_texture > 0) {
            integer i_texture = w-n_texture*llFloor(w/n_texture);
            string name_texture = llGetInventoryName(INVENTORY_TEXTURE, i_texture);
           llGiveInventory(rez_key, name_texture);
        }
        llGiveInventory(rez_key, settings);
        w++;
        if(w < w_hi) {
            llRezObject(rezz, llGetPos()+<0.0,0.0,1.0>, ZERO_VECTOR, ZERO_ROTATION, w);
        }
        else {
            llOwnerSay("Maze Rezzed");
            llOwnerSay("Turning Maze");
            integer v = 0;
            for (; v < v_hi; v++) {
                llSleep(1.0);
                llRegionSay(ctrl_channel, "TURN,"+(string)(v*u_hi)+","+(string)(v*u_hi+u_hi-1)+","+llList2String(maze, v));
            }
            llOwnerSay("Maze Turned");
        }
    }

    changed(integer change)
    {
        if (
        (change & CHANGED_INVENTORY) && 
        (llGetInventoryNumber(INVENTORY_NOTECARD) > 0)
        ) {
            llResetScript();
        }
    }
}
