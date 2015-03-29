////////////////////////////////////////////////////////////
// License: 
//
//
////////////////////////////////////////////////////////////

// Creator: Sherif Abdelwahab
// Contributors: 
// Description: Skeleton code for any activity that requires a sqeuence of instructions from a board 
// Requires: Communication with an instruction board to get the message of instructions, and wait for the next step
//   

key user;

integer dialogChannel = -9954; // channel for a dialog box
integer activityChannel = -9955; // The channel for this activity
integer dialogHandle;
integer activityHandle;

list inputList = ["Got it!","No"];
list posterlist = ["ActivityBoard","GroceryStore","Mall","Restaurant", "School"]; //placeholder of all expected instruction board of the activity
string poster; // next instruction to listen to
integer posteridx;

board_accepted() // runs if the avatar accepted the activity of confirmed her understanding of next step requirement
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
        llOwnerSay("Next landmark is " + poster);
        activityHandle = llListen(activityChannel, poster, "" , "");  // listen to instruction from next poster

	// add next step logic here
    }
}

board_denied()
{
     llOwnerSay("Activity denied");
     // add logic for next step denial here
}

default
{
    state_entry()
    {
        llOwnerSay( "Hello, Badge!");
        poster = ""; // initially no activity is running
        
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
            
        }
        else
        {
            llListenRemove(dialogHandle); //  Stop listining any more  
            llListenRemove(activityHandle); //  Stop listining any more   
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
           board_accepted();
        }
        else if(msg == llList2String(inputList,1)) // The avatar denied the activity (can be here only for the activity board or first poster)
        {
            board_denied();
        }
        
    }
  
}
       
    
