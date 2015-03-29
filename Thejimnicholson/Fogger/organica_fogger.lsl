string version ="0.4";
integer channel=5;       //Channel it listens for commands on

string on_cmd="on";           //What command turns it on
string off_cmd ="off";         //What command turns it off

key on_msg;
key off_msg;

list colors = [<1.0,1.0,1.0>,<0.0, 0.0, 1.0>,<0.0, 1.0, 1.0>,<0.0, 1.0, 0.0>,<1.0, 0.0, 1.0>,<1.0, 0.0, 0.0>,<0.4,0.3,1.0>,<0.3,0.0,0.3>,<1.0,0.5,0.0>,<0.0,0.8,1.0>];
float timer_interval = 2.0;

integer flags;
integer switch;
list sys;

        //INSERT CODE BETWEEN THESE LINES
integer glow = TRUE;
integer bounce = TRUE;
integer interpColor = TRUE;
integer interpSize = TRUE;
integer wind = FALSE;
integer followSource = TRUE;
integer followVel = TRUE;
integer pattern = PSYS_SRC_PATTERN_EXPLODE;
key target = "";
float age = 15.000000;
float maxSpeed = 2.000000;
float minSpeed = 0.010000;
string texture = "361f60b4-c848-9023-666d-1262cfad2203";
float startAlpha = 0.000000;
float endAlpha = 0.200000;
vector startColor = <0.00000, 1.00000, 1.00000>;
vector endColor = <0.00000, 0.00000, 1.00000>;
vector startSize = <1.30000, 1.40000, 0.10000>;
vector endSize = <6.00000, 6.00000, 0.10000>;
vector push = <0.00000, 0.00000, -0.30000>;
float rate = 0.010000;
float radius = 0.000000;
integer count = 11;
float anglebegin = 0.000000;
float angleend = 0.000000;
vector omega = <0.00000, 0.00000, 0.00000>;
float life = 0.000000;
        
                
        //INSERT CODE BETWEEN THESE LINES
integer rand(integer spread) {
    float fspread = (float) spread;
    float frand = llFrand(fspread);
    integer rand = (integer) (frand + 0.5) - 1;
    if (rand > spread) {
        return spread;
    }
    if (rand < 0) {
        return 0;
    }
    return rand;
}

particlesOn(vector sc, vector ec)
{
    flags = 0;
    if (target == "owner") target = llGetOwner();
    if (target == "self") target = llGetKey();
    if (glow) flags = flags | PSYS_PART_EMISSIVE_MASK;
    if (bounce) flags = flags | PSYS_PART_BOUNCE_MASK;
    if (interpColor) flags = flags | PSYS_PART_INTERP_COLOR_MASK;
    if (interpSize) flags = flags | PSYS_PART_INTERP_SCALE_MASK;
    if (wind) flags = flags | PSYS_PART_WIND_MASK;
    if (followSource) flags = flags | PSYS_PART_FOLLOW_SRC_MASK;
    if (followVel) flags = flags | PSYS_PART_FOLLOW_VELOCITY_MASK;
    if (target != "") flags = flags | PSYS_PART_TARGET_POS_MASK;
    sys = [  PSYS_PART_MAX_AGE,age,
                        PSYS_PART_FLAGS,flags,
                        PSYS_PART_START_COLOR, sc,
                        PSYS_PART_END_COLOR, ec,
                        PSYS_PART_START_SCALE,startSize,
                        PSYS_PART_END_SCALE,endSize, 
                        PSYS_SRC_PATTERN, pattern,
                        PSYS_SRC_BURST_RATE,rate,
                        PSYS_SRC_ACCEL, push,
                        PSYS_SRC_BURST_PART_COUNT,count,
                        PSYS_SRC_BURST_RADIUS,radius,
                        PSYS_SRC_BURST_SPEED_MIN,minSpeed,
                        PSYS_SRC_BURST_SPEED_MAX,maxSpeed,
                        PSYS_SRC_TARGET_KEY,target,
                        PSYS_SRC_ANGLE_BEGIN,anglebegin, 
                        PSYS_SRC_ANGLE_END,angleend,
                        PSYS_SRC_OMEGA, omega,
                        PSYS_SRC_MAX_AGE, life,
                        PSYS_SRC_TEXTURE, texture,
                        PSYS_PART_START_ALPHA, startAlpha,
                        PSYS_PART_END_ALPHA, endAlpha
                            ];
                            
    llParticleSystem(sys);
}
auto_upgrade() {
    string self = llGetScriptName();  // the name of this script.
    string basename = self;  // script name with no version attached.    
    
    if (llSubStringIndex(self, " ") >= 0) {
        integer posn;
        // minimum script name is 2 characters plus version.
        for (posn = llStringLength(self) - 1; (posn >= 2) && (llGetSubString(self, posn, posn) != " "); posn--) {
            // find the space.
        }
        if (posn < 2) return;  // no space found.
        string suffix = llGetSubString(self, posn, -1);
        // ditch the space character for our numerical check.
        string chopped_suffix = llGetSubString(suffix, 1, llStringLength(suffix) - 1);
        // strip out a 'v' if there is one.
        if (llGetSubString(chopped_suffix, 0, 0) == "v")
            chopped_suffix = llGetSubString(chopped_suffix, 1, llStringLength(chopped_suffix) - 1);
        // if it's a valid floating point number and is greater than zero, that works for our version.
        if ((float)chopped_suffix > 0.0)
            basename = llGetSubString(self, 0, -llStringLength(suffix) - 1);
    }
    integer posn;
    // find any scripts that match the basename.  they are variants of this script.
    for (posn = llGetInventoryNumber(INVENTORY_SCRIPT) - 1; posn >= 0; posn--) {
        string curr_script = llGetInventoryName(INVENTORY_SCRIPT, posn);
        // remove scripts with same name (except myself, of course).
        if ( (curr_script != self) && (llSubStringIndex(curr_script, basename) == 0) ) {
            llRemoveInventory(curr_script);
        }
    }
}


particlesOff()
{
    llParticleSystem([]);
}
default
{
    on_rez(integer num)
    {
        llResetScript();
    }
    state_entry()
    {
        llSay(0,version);
        particlesOff(); 
        llListen(channel,"", NULL_KEY, on_cmd);
        llListen(channel, "", NULL_KEY, off_cmd);
        //particlesOn();
    }
    listen(integer chan, string name, key id, string msg)
    {
        if (llSameGroup(id)) {
            if (msg == on_cmd) {
                integer start = rand(11);
                integer end = rand(11);   
                llSetTimerEvent(timer_interval);            
                particlesOn(llList2Vector(colors,start),llList2Vector(colors,start));
            }
            if(msg==off_cmd) {
                llSetTimerEvent(0.0);
                particlesOff();
            }
        }
        
    }
    
    
    touch_start(integer num)
    {
        if(llSameGroup(llDetectedKey(0)))
        {
            if(switch)
            {
                        integer start = rand(11);
        integer end = rand(11);

                switch=0;
                llSetTimerEvent(timer_interval);
                particlesOn(llList2Vector(colors,start),llList2Vector(colors,start));
            }else
            {
                switch=1;
                llSetTimerEvent(0.0);
                particlesOff();
            }
        }
    }
    timer() {
        integer start = rand(11);
        integer end = rand(11);
        vector start_color = llList2Vector(colors,start);
        vector end_color = llList2Vector(colors,end);
        particlesOn(start_color, end_color);
    }
}