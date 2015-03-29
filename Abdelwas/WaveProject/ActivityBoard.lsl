////////////////////////////////////////////////////////////
// License: 
//
//
////////////////////////////////////////////////////////////

// Creator: Sherif Abdelwahab
// Contributors: 
// Description: Skeleton fo an instruction board of a particular activity (defined by the channel) 
// Requires: 
//   


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
        string msg = "Go to next poster"; // whatever message on board
        llSay (activityChannel, msg);   
	
	// add logic here (example teleport the cat)
	
    }    
}
