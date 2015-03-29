integer activityChannel = -9955; // The channel for this activity

default
{
    state_entry()
    {
        vector COLOR_GREEN = <0.0, 1.0, 0.0>;
        float  OPAQUE      = 1.0;
        //      prim's name (not necessarily object's)
        llSetText(llGetObjectName(), COLOR_GREEN, OPAQUE );
    }
 
    touch_start(integer total_number)
    {
        key user =  llDetectedKey(0);
        string msg = "Miss Clark's cat has disappeared! Help Miss Clark by finding her cat in less than [TIME OF ACTIVITY]. Miss Clark's cat was last seen in front of the grocery store. Don't forget to maintain your overall health levels while looking for her cat! Miss Clark doesn't want you to sacrifice your health for this mission! She will give you a reward up to 100 pts and 100 L$ depending on your overall health when you find her cat!"; // whatever message on board
        llSay (activityChannel, msg);   
    }    
}