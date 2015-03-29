////////////////////////////////////////////////////////////
// License: 
//
//
////////////////////////////////////////////////////////////

// Creator: Sherif Abdelwahab
// Contributors: 
// Description: Implements the missing cat activity!
// Requires: Communication boards named according to the description of the missing cat on WiKi ("ActivityBoard","GroceryStore","Mall","Restaurant", "School")
//   

// ToDo: Currently it starts working on attach to avatar, This should be changed when the code is integrated with combadge code so that it gets called from a main script in combadge :)


key user;

integer dialogChannel = -9954; // channel for a dialog box
integer activityChannel = -9955; // The channel for this activity
integer dialogHandle;
integer activityHandle;

list inputList = ["Got it!","No"];
list posterlist = ["ActivityBoard","GroceryStore","Mall","Restaurant", "School"]; //placeholder of all expected instructions of the activity
string poster; // next instruction to listen to
integer posteridx;

// for the timer
float gap = 1.0;
float counter = 0.0;

// Missing Cat Parameters
list Weather = "Sunny,75°F"; 
string Intensity = "Moderate";
float TimeOut =  60.0; // timeout timer in seconds

board_accepted()
{
    // go to next poster, if it is the last one end the activity
    
    posteridx += 1;
    if (posteridx == llGetListLength(posterlist))
    {
         llOwnerSay("Well Done!");
         llListenRemove(dialogHandle); //  Stop listining any more 
         llListenRemove(activityHandle); //  Stop listining to the current poster 
         llResetScript(); // reset the script
    }
    else
    {
        llListenRemove(activityHandle); //  Stop listining to the current poster
        poster = llList2String(posterlist,posteridx); // next poster
        llOwnerSay("Go to: " + poster);
        activityHandle = llListen(activityChannel, poster, "" , "");  // listen to instruction from next poster
    }
}

board_denied()
{
    
     llResetScript(); // reset the script
     
}

default
{
    state_entry()
    {
        posteridx = 0;
        poster = llList2String(posterlist,posteridx); // next poster // initially no activity is running
        
    }

    attach(key id)
    {
        user = id;
        if (id)     // is a valid key and not NULL_KEY
        {
            // listen only to messages from the first poster in the activity (activity board)
            posteridx = 0;
            poster = llList2String(posterlist,posteridx); // next poster
            
            dialogHandle = llListen(dialogChannel, "", user , "");   // listen to user input for dialogbox
            activityHandle = llListen(activityChannel, poster, "" , "");  // listen to instruction from next poster
            
            llSetTimerEvent(gap); // start the timer
            
        }
        else
        {
            llListenRemove(dialogHandle); //  Stop listining any more  
            llListenRemove(activityHandle); //  Stop listining any more   
        }
    }
    
    timer()
    {
        counter = counter + gap; 
        if (counter >= TimeOut)
        {
             llSetTimerEvent(0); // Stop the timer and terminate the activity
             string msg = "Oh! you did not complete the activity in the required time! Hard luck!";
             llDialog(user, msg, llList2String(inputList,0), dialogChannel); // dialogbox to verify user actions
             llResetScript(); // reset the script
        }
    }
    
    listen(integer channel, string name, key id, string msg)
    {
        if (channel == activityChannel & name == poster) // This is an instruction
        {   if (posteridx == 0) // first poster in the activity
            {
                llDialog(user, msg, inputList, dialogChannel); // dialogbox to verify user actions (all input list)
            }
            else
            {
                 llDialog(user, msg, llList2String(inputList,0), dialogChannel); // dialogbox to verify user actions
            }
        }
        
        if(channel != dialogChannel) // only parse messages on the correct dialog channel
            return;

        // This is an avatar response to the dialog 
        
        if(msg ==  llList2String(inputList,0)) // The avatar accepted 
        { 
            llOwnerSay("Missing Cat activity accepted!"); 
            board_accepted();
        }
        else if(msg == llList2String(inputList,1)) // The avatar denied the activity (can be here only for the activity board or first poster)
        {
            llOwnerSay("Missing Cat activity denied!");
            //board_denied();
        }
        
    }
  
}
       
    