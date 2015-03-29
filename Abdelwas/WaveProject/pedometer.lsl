////////////////////////////////////////////////////////////
// License: 
//
//
////////////////////////////////////////////////////////////

// Creator: Sherif Abdelwahab
// Contributors: 
// Description: A pedometer that an avatar wear to measure the time, distance, current speed, average speed, and number of steps required to perform an activityi.
// Requires: Permission from the user to control the keyboard inputs
//   


vector initpos; // position
integer counter; // needed for the timer
float   period = 1.0; // periodicity of the timer
key user; // who is currently wearing the pedometer
float velocity; // current velocity
float avgvelocity = 0; // placeholder for the average velocity
float distance = 0; // total distance
integer steps = 0; // total number of steps
string msg = "Pedometer ON"; // initial message 
integer dialogChannel = -9954; // needed for the dialogbox
integer dialogHandle; // needed for the dialogbox
list inputList = ["Summary", "Reset"]; // needed for the dialogbox


default
{
    state_entry()
    {
        llSay(0, "Hello, Avatar from pedometer!");
    }

    attach(key id)
    {
        user = id;
        if (id)     // is a valid key and not NULL_KEY
        {
            llOwnerSay("Timer Start and Initial position!");
            initpos = llGetPos();
            llSetTimerEvent(period);
            velocity = llVecMag(llGetVel());
            llRequestPermissions(user, PERMISSION_TAKE_CONTROLS); // request permission from the user to control the keyboard
            
            dialogHandle = llListen(dialogChannel, "", user, "");
            llDialog(user, msg, inputList, dialogChannel);  // the pedometer screen is simply a dialogbox
        }
        else
        {
	    // no one is putting on the pedometer, shutdown everything
            llOwnerSay("The Timer Stop!");
            llSetTimerEvent(0.0);
            counter = 0;
            llListenRemove(dialogHandle);
            
        }
    }
    
    run_time_permissions(integer perm) 
    {   // permissions dialog answered
        if (perm & PERMISSION_TAKE_CONTROLS) { // we got a yes
            llTakeControls(CONTROL_FWD | CONTROL_BACK, TRUE, TRUE); // take up and down controls
        }
    }
    
    control(key id, integer held, integer change)
     { 
	// the number of steps = number of key strocks the user press to move around
        if (held & CONTROL_FWD) { 
            ++steps;
        } else if (held  & CONTROL_BACK) { 
            ++steps; 
        }
    }
    
    timer()
    {
        vector curpos = llGetPos();
        
        if (! (llGetAgentInfo(user) & AGENT_FLYING ))
        {
            ++counter; 
            velocity = llVecMag(llGetVel());
            avgvelocity += velocity / counter;
            distance += llVecDist(curpos, initpos) ;
            msg =  "Elapsed Time: " + (string)(counter * period) +  " Current Velocity: " + 
                    (string) velocity +   " Average Velocity: " + 
                    (string) avgvelocity +  
                    " Distance: " + (string) distance + 
                    " Steps: " + (string) steps;    
        } 
        
	initpos = curpos;        
        // Update the dialogbox 
        llDialog(user, msg, inputList, dialogChannel);  
    }
    
    listen(integer channel, string name, key id, string button)
    {
        if(channel != dialogChannel) // listen only to the correct channel
            return;

	// ToDo: What is the summary needed for the user
        if(button == "Summary")
            llOwnerSay ("Summary");
 
        else if(button == "Reset")
        {

	    // reinitialize everything on the pedometer screen
            counter  = 0; 
            velocity = 0; 
            avgvelocity = 0; 
            distance = 0; 
            steps = 0;
            initpos = llGetPos();
            llDialog(user, msg, inputList, dialogChannel);
        }
 
      
 
       
    }
        
}


 
