//////////////////////////////////////////////////////////////////////////

// Filename:    TradeMogul Delivery Point
// Version:     0.1
// Date:        08.30.2010

// Creator:     DaveDorm Gaffer

// Description: 

//////////////////////////////////////////////////////////////////////////

// A script to be used in any oject that will hold trade goods. This can be a cargo door linked to a hull, a simple container or crate, or a warehouse. This script "preserves" the items in a sort of in-gane stasis. As long as the product has not been previously rezzed in world, there is no exporation date on the products. So items can be moved into an avatar's inventory and between these crates without starting the timer.

// However, while inside this crate they are vulnerable. Any avatar within five meters (5m) may click the box for a menu. They can respond "Steal Item" and take one random object (limited to once per box per day.) or they may get a full list of goods inside and be alowed a chance to confiscate the whole load.

// That's all part of the game, the goods can be stolen! You'll need to assign better guards. Also, pirates, remember it's "pillage THEN burn." If this container is destroyed, such as the ship to which it is linked is sunk, the cargo is lost forever as well.

//////////////////////////////////////////////////////////////////////////

// Define parameters & variables

integer COM = -100;            // communication port for dialog communication
float   DROP_TIMEOUT = 60.0;   // timeout for delivery items
integer STEAL_TIMEOUT;         // timeout in minutes if object was stolen

string  STEAL_NOTIFICATION    = "Someone stole something!";
string  STEAL_WARNING         = "You may only steal one item per day!";
string  BOX_EMPTY             = "The Box is empty";

string  DIALOG_TEXT = "TradeMogul Delivery Point. Add items to the box while holding down the CTRL key.";
list    DIALOG_OPTIONS = ["Add Items", "Steal Item", "List Items"];

string  CONFISCATE_TEXT = "Would you Like to confiscate the enclosed items?";
list    CONFISCATE_OPTIONS = ["Confiscate", "Leave Items"];

key     gId;                // the avatar using the menu
integer gNumOfItems;        // total items inside
integer gNewItems = 0;      // new items added
list    gBlackList;         // who cannot steal
float   gGlow;              // glowy affect

list    gItemList;          // list of ites inside
list    gNewItemList;       //list of recently added
list    gNewStridedList;   

//////////////////////////////////////////////////////////////////////////

default
{
    state_entry()
    {

        llSetText(llGetObjectName() + "\n \n \n", <1.0,0.5,0.0>, 1);        
//      llSetText("", <1.0,1.0,1.0>,1.0);
        integer i;
        
        gNumOfItems = llGetInventoryNumber(INVENTORY_OBJECT);
        gItemList = [];

        for (i = 0; i < gNumOfItems; i ++)
        {
            gItemList = (gItemList = []) + gItemList + [llGetInventoryName(INVENTORY_OBJECT, i)];
        }

        gId = llGetOwner();
    }

    touch_start(integer total_number)
    {
        gId = llDetectedKey(0);
        llSensor(llKey2Name(gId),gId,1,5,PI);
    }
    sensor(integer num_detected)
    {
        llListen(COM, "", gId, "");
        llDialog(gId, DIALOG_TEXT, DIALOG_OPTIONS, COM);
    }
    listen(integer channel, string nam, key id, string message)
    {
        integer i;
        
        gNumOfItems = llGetInventoryNumber(INVENTORY_OBJECT);
        gItemList = [];

        for (i = 0; i < gNumOfItems; i ++)
        {
                gItemList = (gItemList = []) + gItemList + [llGetInventoryName(INVENTORY_OBJECT, i)];
        }
        if (message == "Confiscate"){
            list        inventory;
            string      name;
            integer     num = llGetInventoryNumber(INVENTORY_ALL)-2;
            string      text = llGetObjectName() + " items are being confiscated by " + llKey2Name(gId);
            integer     i;
            key         user = gId;
            for (i = 0; i < num; ++i) {
                name = llGetInventoryName(INVENTORY_ALL, i);
                llSetText(text + (string)((integer)(((i + 1.0) / num) * 100))+ "%", <1, 1, 1>, 1.0);         
                llGiveInventory(gId,llGetInventoryName(INVENTORY_OBJECT, 0));

            }
            llSetText("",<1,1,1>,1.0);

        }
        if (message == "Leave Items"){
            llResetScript();
        } 
        if (message == "List Items"){
            for(i = 0; i < gNumOfItems; i++)
            {
                llWhisper(0,llList2String(gItemList,i));  
            }
            if(gNumOfItems>=1){
                llDialog(gId, CONFISCATE_TEXT, CONFISCATE_OPTIONS, COM);    
            }
            if(gNumOfItems==0){
                llSay(0,"The Box is Empty");
            }
        }
        if (message == "Steal Item")
        {
            if (gNumOfItems > 0)
            {
                string  custName;  
                list    names;    
                integer index;    
                integer time;     
                custName  = llKey2Name(gId);
                names = llList2ListStrided(gBlackList, 0, -1, 2);
                index = llListFindList(names, [custName]);
                time    = llGetUnixTime() / 60;
                if (index == -1)
                {
                    gBlackList = (gBlackList = []) + gBlackList + [custName, time];
                    llGiveInventory(gId, llGetInventoryName(INVENTORY_OBJECT, 0));
                    llInstantMessage(llGetOwner(), STEAL_NOTIFICATION);
                }
                else
                {
                    integer timePassed;
                    index = (index * 2) + 1;
                    timePassed = time - llList2Integer(gBlackList, index);
                    STEAL_TIMEOUT = (integer) llGetObjectDesc();
    
                    if (timePassed > STEAL_TIMEOUT)
                    {
                        gBlackList = llListReplaceList((gBlackList = []) + gBlackList, [time], index, index);
                        llGiveInventory(gId, llGetInventoryName(INVENTORY_OBJECT, 0));
                        llInstantMessage(llGetOwner(), STEAL_NOTIFICATION);
                    }
                    else
                    {
                        llSay(0, STEAL_WARNING);
                    }
                }
            }
            else
            {
                llSay(0, BOX_EMPTY);
            }

            gNumOfItems = llGetInventoryNumber(INVENTORY_OBJECT);
            gItemList = [];
    
            for (i = 0; i < gNumOfItems; i ++)
            {
                gItemList = (gItemList = []) + gItemList + [llGetInventoryName(INVENTORY_OBJECT, i)];
            }
        }
        else if (message == "Add Items")
        {
            gGlow = llList2Float(llGetPrimitiveParams([PRIM_GLOW, ALL_SIDES]), 0);
            llSetPrimitiveParams([PRIM_GLOW, ALL_SIDES, 0.0]);
            llSetTimerEvent(DROP_TIMEOUT);
            llAllowInventoryDrop(TRUE);
        }
    }
    
    changed(integer change)
    {
        integer i;
        integer index;
        integer numOf;
        string  inventoryName;
        
        if (change & CHANGED_ALLOWED_DROP || CHANGED_INVENTORY)
        {
            numOf = llGetInventoryNumber(INVENTORY_OBJECT);

            if (numOf > gNumOfItems)
            {
                for (i = 0; i < numOf; i ++)
                {
                    inventoryName = llGetInventoryName(INVENTORY_OBJECT, i);
                    index = llListFindList(gItemList, [inventoryName]);

                    if (index == -1)
                    {
                        gNewItemList = (gNewItemList = []) + gNewItemList + [inventoryName];
                        gNewItems ++;

                        gItemList    = (gItemList = []) + gItemList + [inventoryName];
                        gNumOfItems ++;
                    }
                }
                llSetTimerEvent(DROP_TIMEOUT);
            }
            else
            {
                 gNumOfItems = numOf;
            }
            
            
            // restore delivery point appearance
            llAllowInventoryDrop(FALSE);
            llSetPrimitiveParams([PRIM_GLOW, ALL_SIDES, gGlow]);
        }
    }
    
    timer()
    {
        integer i;
        integer j;
        integer strLen;
        integer items;
        string  itemName;
        string  itemNamePrev;
        string  text;
        string  date;

        if (gNewItems > 0)
        {
            items = 0;
            
            for (i = 0; i < gNewItems; i ++)
            {
                itemName = llList2String(gNewItemList, i);
                strLen = llStringLength(itemName);
    
                // remove sequence number at the end of repeated names           
                for (j = 0; j < strLen; j ++)
                {
                    if ((integer) llGetSubString(itemName, -1 - j, -1) > 0)
                    {
                        itemName = llGetSubString(itemName, 0 , -1-j-1);
                    }
                }

                itemName = llStringTrim(itemName, STRING_TRIM);

                if (itemNamePrev == "")
                {
                    itemNamePrev = itemName;
                }
                
                if (itemName != itemNamePrev)
                {
                    date = llGetDate();
                    text = llKey2Name(gId) + " delivered " + (string) items + " " + itemNamePrev + "(s) on " + date;
                    
                    llInstantMessage(llGetOwner(), text);

                    itemNamePrev = itemName;
                    items = 1;
                }
                else
                {
                    items ++;
                }
            }

            date = llGetDate();
            text = llKey2Name(gId) + " delivered " + (string) items + " " + itemName + "(s) on " + date;   
            llInstantMessage(llGetOwner(), text);
        }
        gNumOfItems = llGetInventoryNumber(INVENTORY_OBJECT);
        gItemList = [];
        for (i = 0; i < gNumOfItems; i ++)
        {
            gItemList = (gItemList = []) + gItemList + [llGetInventoryName(INVENTORY_OBJECT, i)];
        }
        gNewItems = 0;
        gNewItemList = [];
        gNewStridedList = [];
        gId = llGetOwner();
        llAllowInventoryDrop(FALSE);
        llSetPrimitiveParams([PRIM_GLOW, ALL_SIDES, gGlow]);
        
        llSetTimerEvent(0.0);
    }

    on_rez(integer start_param)
    {
        llResetScript();
    }
}

//////////////////////////////////////////////////////////////////////////

// CREDITS AND DISCLAIMER

//////////////////////////////////////////////////////////////////////////

// TradeMogul is a Role Play Trade System and does not have any "real" value in Linden Dollars (L$) or the Real World™. The TradeMogul is just a tool to be used for the sole purpose of role play. DaveDorm Gaffer is not to be held liable for any misuse of the system. The TradeMogul HUD and basic Trade Scripts will **always** be available for free. However DaveDorm Gaffer may sell other TradeMogul products, such as camping chores, compatible trade goods, factories, vendors, or other enhancements to the TradeMogul System

// The TradeMogul System was assembled by DaveDorm Gaffer for use in Second Life® role playing. It is designed to simulate an economy in a role playing community. The HUD is based on the TradeMatey system by Rya Eastkew and was forked from her project, and incorperated into the TradeMogul Sysyem with her permission. 

// The TradeMogul Trade Goods scripts were based on the Jabberwock Trade System, the code for which was massaged over time by many talented avatars including Teleworm Gelber, Burnman Bedlam, Daren Blackadder, and Gregoe Zlatkis. They are designed to be compatible around the grid to serve as tokens to role play commodity trading in Second Life®.

//////////////////////////////////////////////////////////////////////////