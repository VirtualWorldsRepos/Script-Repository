//////////////////////////////////////////////////////////////////////////

// Filename:    TradeMogul Factory Control
// Version:     0.1
// Date:        08.30.2010

// Creator:     DaveDorm Gaffer

// Description:

//////////////////////////////////////////////////////////////////////////

// Produces one trade good in a pre-set time limit read in the object description

//////////////////////////////////////////////////////////////////////////


// Define parameters & variables


float   TIMESTAMP      = 30.0;    // time period for checking producing time
float   DIALOG_TIMEOUT = 60.0;    // time period for checking dialog ignore button

integer COM            = -1000;   // communication port
string  DEFAULT        = "Reset"; // dialog reset string

// Main menu definition
string  MENU_OWNER_TEXT  = "Select an option";
list    MENU_OWNER_OPTS  = ["Add Mng", "Mng List", "Remove Mng"];

// Main menu definition
string  MENU_STOP_TEXT   = "Select an option";
list    MENU_STOP_OPTS   = ["Run Factory", "Take Items", "Cancel"];

// Main menu definition
string  MENU_RUN_TEXT    = "Select an option";
list    MENU_RUN_OPTS    = ["Stop", "Cancel"];

// Main menu definition
string  MENU_STEAL_TEXT    = "Select an option";
list    MENU_STEAL_OPTS    = ["Steal Items", "Cancel"];

integer MNFC_TIME;        // manufacturing time in seconds
integer gUnixTime;        // registered unix time at factory start

list    gMngList;         // list of managers
integer gAddMng;          // add or remove managers from the list indication

integer gNumOfItems;      // number of produced items

key     gId;              // key of user who touch the object

string  newname;          // new name of internal barrel
string  oldname;          // old name of internal barrel

string  objDesc;          // description manufacturing time.


//////////////////////////////////////////////////////////////////////////

// Function definitions

//////////////////////////////////////////////////////////////////////////

takeItems(key id)
{
	list items = [];

	if (gNumOfItems != 0)
	{
		while (gNumOfItems --)
		{
			items += [llGetInventoryName(INVENTORY_OBJECT, 0)];
		}

		llGiveInventory(id, llGetInventoryName(INVENTORY_OBJECT,0));
		llMessageLinked(LINK_ALL_CHILDREN, 0, "alpha", NULL_KEY);
		gNumOfItems = 0;
		llSay(0, "This Unit is now empty");
	}
	else
	{
		llSay(0, "There are no produced items!");
	}
}

//////////////////////////////////////////////////////////////////////////

default
{
	state_entry()
	{
		newname = llGetInventoryName(INVENTORY_OBJECT,0);
		if(newname != oldname){
			llSetObjectName(newname + " factory");
			llSetText(newname + "\n \n \n", <0.0,1.0,1.0>, 1);
			oldname=newname;
			llWhisper(0,"Production Item Updated");
		}

		objDesc = llGetObjectDesc();

		MNFC_TIME = (((integer) objDesc) * 60) * 60;

		if (MNFC_TIME == 1)
		{
			llSay(0, "ERROR: Manufacturing time is not set properly");
		}

		llSetTimerEvent(0.0);
	}

	touch_start(integer total_number)
	{
		if(objDesc != llGetObjectDesc()){
			objDesc=llGetObjectDesc();
			llWhisper(0,"Barrel Manufacturing Time is Updated");
		}
		gId = llDetectedKey(0);

		state MenuMain;
	}
}

state MenuMain
{
	state_entry()
	{
		newname = llGetInventoryName(INVENTORY_OBJECT,0);
		if(newname != oldname){
			llSetObjectName(newname + " factory");
			llSetText(newname + "\n \n \n", <0.0,1.0,1.0>, 1);
			oldname=newname;
			llWhisper(0,"Production Item Updated");
		}
		list    options;
		string  text;
		integer index;

		if (gId == llGetOwner())
		{
			options = MENU_OWNER_OPTS + MENU_STOP_OPTS + [DEFAULT];
		}
		else
		{
			index = llListFindList(gMngList, [llKey2Name(gId)]);

			if (index == -1)
			{
				options = MENU_STEAL_OPTS;
			}
			else {
				options = MENU_STOP_OPTS;
			}
		}

		text = MENU_STOP_TEXT;
		text += "\n\nCurrent Factory State: STOPPED\nProduced Items: " + (string) gNumOfItems;

		llSetTimerEvent(0.0);

		llListen(COM, "", gId, "");
		llDialog(gId, text, options, COM);

		llSetTimerEvent(DIALOG_TIMEOUT);
	}

	listen(integer channel, string name, key id, string message)
	{
		if (channel == 0)
		{
			if (gAddMng == TRUE)
			{
				gMngList += [message];

				llSay(0, message + " was added to the Manager List");
			}
			else
			{
				integer index;

				index = llListFindList(gMngList, [message]);

				if (index != -1)
				{
					gMngList = llDeleteSubList(gMngList, index, index);

					llSay(0, message + " was removed from the Manager List");
				}
				else
				{
					llSay(0, message + " was not found on the Manager List!");
				}
			}

			state default;
		}
		else
		{
			// ["Run Factory", "Take Items"]["Add Manager", "Mng List", "Remove Mng", DEFAULT]
			if (message == DEFAULT)
			{
				llResetScript();
			}
			else if (message == "Cancel")
			{
				state default;
			}
			else if (message == "Run Factory")
			{
				gUnixTime = llGetUnixTime();

				llSetTimerEvent(0.0);
				llSetTimerEvent(TIMESTAMP);

				state Running;
			}
			else if (message == "Take Items")
			{
				takeItems(gId);

				state default;
			}
			else if (message == "Steal Items")
			{
				takeItems(gId);
				llInstantMessage(llGetOwner(), llKey2Name(gId) + " has plundered some of yer stuff");
				state default;
			}
			else if (message == "Add Mng")
			{
				gAddMng = TRUE;

				llSay(0, "Say a manager's full name to be added to the list.");

				llSetTimerEvent(0.0);

				llListen(0, "", gId, "");

				llSetTimerEvent(DIALOG_TIMEOUT);
			}
			else if (message == "Mng List")
			{
				integer i;
				integer numOf;

				numOf = llGetListLength(gMngList);

				if (numOf > 0)
				{
					llSay(0, "The following " + (string) numOf + " manager(s) are on the list:");

					for (i = 0; i < numOf; i ++)
					{
						llSay(0, llList2String(gMngList, i));
					}
				}
				else
				{
					llSay(0, "there are no managers on the list");
				}

				state default;
			}
			else if (message == "Remove Mng")
			{
				gAddMng = FALSE;

				llSay(0, "Say a manager's full name to be removed from the list.");

				llSetTimerEvent(0.0);

				llListen(0, "", gId, "");

				llSetTimerEvent(DIALOG_TIMEOUT);
			}
			else
			{
				llOwnerSay("ERROR: Unknown Menu Option: " + message);

				state default;
			}
		}
	}

	touch_start(integer total_number)
	{
		if(objDesc != llGetObjectDesc()){
			objDesc=llGetObjectDesc();
			llWhisper(0,"Barrel Manufacturing Time is Updated");
		}
		if (llDetectedKey(0) == gId)
		{
			llSay(0, "Menu was canceled, click again for a menu.");

			state default;
		}
		else
		{
			llSay(0, "Setup program is currently busy by other user. Try again later.");
		}
	}

	timer()
	{
		llSay(0, "WARNING: Dialog timer expired, click again for a new menu.");

		state default;
	}
}

state Running
{
	state_entry()
	{
		newname = llGetInventoryName(INVENTORY_OBJECT,0);
		if(newname != oldname){
			llSetObjectName(newname + " factory");
			oldname=newname;
			llWhisper(0,"Production Item Updated");
		}
		if (llGetInventoryNumber(INVENTORY_OBJECT) == 0) {
			llWhisper(0, "Production cannot start until you place your product in the factory!");
			llResetScript();
		}

		llSay(0, "The factory is started to produce.");
		llSay(0, "Manufacturing time is set to: " + (string)((MNFC_TIME / 60) / 60) + " hours.");
		llSay(0, "You will need to restart production once your product is finished.");
		if(gNumOfItems!=1){
			llMessageLinked(LINK_ALL_CHILDREN, 0, "alpha", NULL_KEY);
		}
		llSetTimerEvent(0.0);
		llSetTimerEvent(TIMESTAMP);
	}

	timer()
	{
		integer timePassed;

		timePassed = llGetUnixTime() - gUnixTime;

		if (timePassed > MNFC_TIME)
		{
			gNumOfItems=1;

			llSay(0, "The factory has produced one " + llGetInventoryName(INVENTORY_OBJECT, 0) + " and stopped.");
			llMessageLinked(LINK_ALL_CHILDREN, 0, "nonalpha", NULL_KEY);

			state default;
		}
	}

	touch_start(integer total_number)
	{
		if(objDesc != llGetObjectDesc()){
			objDesc=llGetObjectDesc();
			llWhisper(0,"Barrel Manufacturing Time is Updated");
		}
		gId = llDetectedKey(0);

		state MenuRunning;
	}
}

state MenuRunning
{
	state_entry()
	{
		newname = llGetInventoryName(INVENTORY_OBJECT,0);
		if(newname != oldname){
			llSetObjectName(newname);
			oldname=newname;
			llWhisper(0,"Production Item Updated");
		}
		string  text;
		integer index;
		integer timeleft;



		timeleft = (MNFC_TIME - (llGetUnixTime() - gUnixTime)) / 60;
		timeleft ++;
		if(gNumOfItems!=0){
			gNumOfItems=1;
		}
		text = MENU_RUN_TEXT;
		text += "\n\nCurrent Factory State: RUNNING\nProduced Items: " + (string) gNumOfItems;
		text += "\nTime left: " + (string) (timeleft / 60) + " hours and " + (string) (timeleft % 60) + " minutes";

		llSetTimerEvent(0.0);

		llListen(COM, "", gId, "");
		if (gId != llGetOwner())
		{
			index = llListFindList(gMngList, [llKey2Name(gId)]);

			if (index == -1)
			{
				llSay(0, llKey2Name(gId) + ", you are not on the Manager List");
				llDialog(gId, text, MENU_STEAL_OPTS, COM);
			}
		}
		else{
			llDialog(gId, text, MENU_RUN_OPTS, COM);
		}
		llSetTimerEvent(DIALOG_TIMEOUT);
	}

	listen(integer channel, string name, key id, string message)
	{
		// ["Stop", "Take Items"]
		if (message == "Stop")
		{
			llSay(0, "The factory is stopped now.");

			state default;
		}
		else if (message == "Take Items")
		{
			takeItems(gId);

			state Running;
		}
		else if (message == "Steal Items")
		{
			takeItems(gId);

			state Running;
		}
		else if (message == "Cancel")
		{
			state Running;
		}
		else
		{
			llOwnerSay("ERROR: Unknown Menu Option: " + message);

			state Running;
		}
	}

	touch_start(integer total_number)
	{
		if(objDesc != llGetObjectDesc()){
			objDesc=llGetObjectDesc();
			llWhisper(0,"Barrel Manufacturing Time is Updated");
		}
		if (llDetectedKey(0) == gId)
		{
			llSay(0, "Menu was cancled, click again for a menu.");

			state Running;
		}
		else
		{
			llSay(0, "Setup program is currently busy by other user. Try again later.");
		}
	}

	timer()
	{
		llSay(0, "WARNING: Dialog timer expired, click again for a new menu.");

		state Running;
	}
}

//////////////////////////////////////////////////////////////////////////

// For More information, see the TradeMogul website
/// at http://ezc.davedorm.com/trademogul

//////////////////////////////////////////////////////////////////////////