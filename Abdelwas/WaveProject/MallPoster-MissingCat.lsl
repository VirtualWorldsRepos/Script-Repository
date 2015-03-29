///////////////////////////////////////////////////////////
// License: 
//
//
////////////////////////////////////////////////////////////

// Creator: Sherif Abdelwahab
// Contributors: 
// Description: Implements the  mall  poster for the missing cat activity
// Requires: Communication with the Combadge on a designated channel
//   

integer activityChannel = -9955; // The channel for this activity

default
{
    state_entry()
    {
        vector COLOR = <1.0, 0.0, 0.0>;
        float  OPAQUE      = 1.0;
 
//      prim's name (not necessarily object's)
        llSetText(llGetObjectName(), COLOR, OPAQUE );
    }
 
    touch_start(integer total_number)
    {
        key user =  llDetectedKey(0);
        string msg = "Miss Clark's cat has disappeared! Help Miss Clark by finding her cat. Miss Clark's cat was last seen at the entrance of the wilderness area. Don't forget to maintain your overall health levels while looking for her cat! When you will be done running, come back and treat your avatar with a new outfit or a refillable bottle of water!";
        llSay (activityChannel, msg);   
    }    
}