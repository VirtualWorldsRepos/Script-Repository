
///////////////////////////////////////////////////////////
// License: 
//
//
////////////////////////////////////////////////////////////

// Creator: Sherif Abdelwahab
// Contributors: 
// Description: Implements the  Grocery Store poster for the missing cat activity
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
        string msg = "Miss Clark's cat has disappeared! Help Miss Clark by finding her cat. Miss Clark's cat was last seen in front of the restaurant The Bistro. Don't forget to maintain your overall health levels while looking for her cat! Have you had a drink yet? You can buy drinks at the grocery store.";
        llSay (activityChannel, msg);   
    }    
}