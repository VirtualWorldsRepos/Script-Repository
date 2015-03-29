//start_unprocessed_text
/*/|/ Put any texture converted by gif_2_SL_animation_v0.6.exe into a prim with this script to get it to play back automatically as a movie


integer animOn = TRUE; /|/Set to FALSE and call initAnim() again to stop the animation.
/|/Effect parameters: (can be put in list together, to make animation have all of said effects)
/|/LOOP - loops the animation
/|/SMOOTH - plays animation smoothly
/|/REVERSE - plays animation in reverse
/|/PING_PONG - plays animation in one direction, then cycles in the opposite direction
list effects = [LOOP];  /|/ LOOP for GIF89 movies
/|/Movement parameters (choose one):
/|/ROTATE - Rotates the texture
/|/SCALE - Scales the texture
/|/Set movement to 0 to slide animation in the X direction, without any special movement.
integer movement = 0;
integer face = ALL_SIDES; /|/Number representing the side to activate the animation on.
integer sideX = 1; /|/Represents how many horizontal images (frames) are contained in your texture.
integer sideY = 1; /|/Same as sideX, except represents vertical images (frames).
float start = 0.0; /|/Frame to start animation on. (0 to start at the first frame of the texture)
float length = 0.0; /|/Number of frames to animate, set to 0 to animate all frames.
float speed = 10.0; /|/Frames per second to play.
initAnim() /|/Call this when you want to change something in the texture animation.
{
    if(animOn)
    {
        integer effectBits;
        integer i;
        for(i = 0; i < llGetListLength(effects); i++)
        {
            effectBits = (effectBits | llList2Integer(effects,i));
        }
        integer params = (effectBits|movement);
        llSetTextureAnim(ANIM_ON|params,face,sideX,sideY,     start,length,speed);
    }
    else
    {
        llSetTextureAnim(0,face,sideX,sideY, start,length,speed);
    }
}

fetch()
{
     string texture = llGetInventoryName(INVENTORY_TEXTURE,0);
            llSetTexture(texture,ALL_SIDES);
            list data  = llParseString2List(texture,[";"],[]);
            llOwnerSay( llDumpList2String(data ,","));
            string X = llList2String(data,1);
            string Y = llList2String(data,2);
            string Z = llList2String(data,3);
            
            /|/ llOwnerSay("X=" + X + " Y=" + Y + " Z = " + (string) Z);
            
            sideX = (integer) X;
            sideY = (integer) Y;
            speed = (float) Z;
            if (speed) 
                initAnim();
}

default
{
    state_entry()
    {
        fetch();
    }
    changed(integer what)
    {
        if (what & CHANGED_INVENTORY)
        {
            fetch();
        }
    }
}
*/
//end_unprocessed_text
//nfo_preprocessor_version 0
//program_version DarkStorm v2.8 <Firestorm-Release v4.4.2.34167> - SecondGestapo
//mono


float start = 0.0;
float speed = 10.0;
integer sideY = 1;
integer sideX = 1;
integer movement = 0;
float length = 0.0;
integer face = ALL_SIDES;
list effects = [LOOP];
integer animOn = TRUE;
 
initAnim() 
{
    if(animOn)
    {
        integer effectBits;
        integer i;
        for(i = 0; i < llGetListLength(effects); i++)
        {
            effectBits = (effectBits | llList2Integer(effects,i));
        }
        integer params = (effectBits|movement);
        llSetTextureAnim(ANIM_ON|params,face,sideX,sideY,     start,length,speed);
    }
    else
    {
        llSetTextureAnim(0,face,sideX,sideY, start,length,speed);
    }
}


fetch()
{
     string texture = llGetInventoryName(INVENTORY_TEXTURE,0);
            llSetTexture(texture,ALL_SIDES);
            list data  = llParseString2List(texture,[";"],[]);
            llOwnerSay( llDumpList2String(data ,","));
            string X = llList2String(data,1);
            string Y = llList2String(data,2);
            string Z = llList2String(data,3);
            
            
            
            sideX = (integer) X;
            sideY = (integer) Y;
            speed = (float) Z;
            if (speed) 
                initAnim();
}


default
{
    state_entry()
    {
        fetch();
    }
    changed(integer what)
    {
        if (what & CHANGED_INVENTORY)
        {
            fetch();
        }
    }
}

