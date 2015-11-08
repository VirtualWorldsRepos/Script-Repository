//////////////////////////////////////////////////////////////////////////

// Filename:    TradeMogul Timed Product (Minutes)
// Version:     0.1
// Date:        08.31.2010

// Creator:     DaveDorm Gaffer

// Description: 

//////////////////////////////////////////////////////////////////////////

// Allows a product to disappear after a certain amount of time (in minutes.) This is to simulate consumption. Once rezzed or attached, the prims have a lifespan of X minutes (set in object description) This uses a UNIX timestamp, in effect even if taken back into inventory. If rezzed again after the expiration, the prim will simply disappear. 

//////////////////////////////////////////////////////////////////////////

// Define parameters & variables


// global constants
integer TIMEOUT   = 3;            // timeout in seconds for object to disapear
float   TIMESTAMP = 60.0;         // checking the timeout in seconds

// global variables
integer gRezTime;
integer gRezed = 0;

//////////////////////////////////////////////////////////////////////////

default
{
    state_entry()
    {
    }
    
    on_rez(integer start_param)
    {
        gRezTime = llGetUnixTime();

        TIMEOUT = (integer)llGetObjectDesc();

        if (TIMEOUT > 0)
        {
            state Counting;
        }
        else
        {
            llOwnerSay("Please, set timeout in minutes in the Object Description");
        }
    }
}

state Counting
{
    state_entry()
    {
         llSetTimerEvent(TIMESTAMP);
         llSay(0, "Timed");   
    }

    touch_start(integer total_number)
    {
        integer days;
        integer hours;
        integer minutes;

        integer minLeft;

        minLeft = TIMEOUT - ((llGetUnixTime() - gRezTime) / 60);

        if (minLeft < 0)
        {
            minLeft = 0;
        }

        days    =  minLeft / 60 / 24;
        hours   = (minLeft / 60) % 24;
        minutes =  minLeft % 60;

        llSay
        (
            0, "Time left: " +
            (string) days + " days, " +
            (string) hours + " hours, and " +
            (string) minutes + " minutes"
        );
    }

    on_rez(integer start_param)
    {
        if (TIMEOUT - ((llGetUnixTime() - gRezTime) / 60) <= 0)
        {
            llDie();
        }
    }

    timer()
    {
        if (TIMEOUT - ((llGetUnixTime() - gRezTime) / 60) <= 0)
        {
            llDie();
        }
    }
}

//////////////////////////////////////////////////////////////////////////

// For More information, see the TradeMogul website
/// at http://ezc.davedorm.com/trademogul

//////////////////////////////////////////////////////////////////////////