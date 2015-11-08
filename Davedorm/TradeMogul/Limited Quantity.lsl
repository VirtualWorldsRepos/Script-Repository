//////////////////////////////////////////////////////////////////////////

// Filename:    TradeMogul Limited Quantity
// Version:     0.1
// Date:        08.31.2010

// Creator:     DaveDorm Gaffer

// Description: 

//////////////////////////////////////////////////////////////////////////

// A distibution crate that stores a number of prducts. This is to represent a "case" of jars or other boxes sold in bulk. The crate has no expiration, however items inside may be timed. When clicked, a menu offers a selection. The Object Description defines how many of the object are inside.  This can work with multiple items, but the limit is *per* item.  Once the total is reached,the objecy inside is deleted and the crate is empty and useless. Unlike warehouse or delivery crates, this crate cannot be stolen from.

//////////////////////////////////////////////////////////////////////////

// Define parameters & variables

// global constants
integer COM = -12345;
string  DLG_TXT = "What would you like?\n";

// global variables
integer gNumOfItems;        // [item name, numOf]
list    gItemList;
integer gMenuIndex;
integer gListen;
key     gId;

//////////////////////////////////////////////////////////////////////////

// Define functions

// update main delivery point object inventory list
UpdateInventoryList()
{
    integer i;
    integer index;
    integer numOf;
    integer invTyp;
    integer maxNum;
    string  invName;
    list    itemStrd;

    maxNum = (integer) llGetObjectDesc();

    if (maxNum == 0)
    {
        llOwnerSay("ERROR: No maximum number of items is set in the object description!");
    }
    
    gNumOfItems = llGetInventoryNumber(INVENTORY_OBJECT);
    
    for (i = 0; i < gNumOfItems; i ++)
    {
        invName = llGetInventoryName(INVENTORY_OBJECT, i);

        itemStrd = llList2ListStrided(gItemList, 0, -1, 2);
        index    = llListFindList(itemStrd, [invName]);

        if (index == -1)
        {
            gItemList = (gItemList = []) + gItemList + [invName, maxNum];
        }
    }

    itemStrd = llList2ListStrided(gItemList, 0, -1, 2);
    numOf    = llGetListLength(itemStrd);
    
    for (i = 0; i < numOf; i ++)
    {
        invName = llList2String(itemStrd, i);
        invTyp  = llGetInventoryType(invName);

        if (invTyp == INVENTORY_NONE)
        {
            gItemList = llDeleteSubList(gItemList, i * 2, (i * 2) + 1);
        }
    }
}

list GetItemButtonList (list itemList)
{
    integer i;
    integer numOf;
    integer namLen;
    string  itemName;
    list    itemStrd;
    list    itemButtonList = [];

    itemStrd = llList2ListStrided(itemList, 0, -1, 2);
    numOf    = llGetListLength(itemStrd);

    if (numOf > 0)
    {
        for (i = 0; i < numOf; i ++)
        {
            itemName = llList2String(itemStrd, i);
            namLen   = llStringLength(itemName);

            if (namLen > 24)
            {
                itemName = llGetSubString(itemName, 0, 23);
            }

            itemButtonList = (itemButtonList = []) + itemButtonList + [itemName];
        }
    }

    return itemButtonList;
}

// prepare a dialog options list from all available items
list GetItemsMenu (list source, integer menuIndex)
{
    integer numOf;
    integer menuStart;
    integer menuEnd;
    list    menuList;
        
    numOf = llGetListLength(source);

    menuStart = menuIndex * 6;
    menuEnd   = menuStart + 5;

    if (menuEnd > numOf)
    {
        menuEnd = numOf;
    }

    menuList = llList2List(source, menuStart, menuEnd);

    if (menuStart > 0)
    {
        menuList = (menuList = []) + menuList + ["Prev"];
    }

    if (menuEnd < numOf - 1)
    {
        menuList = (menuList = []) + menuList + ["Next"];
    }

    menuList += ["Cancel"];

    return menuList;
}

//////////////////////////////////////////////////////////////////////////

default
{
    state_entry()
    {
        gItemList = [];
        UpdateInventoryList();
        gListen = 0;
    }
    
    touch_start(integer total_number)
    {
        integer index;
        integer numOf;
        string  dlgTxt;
        list    dlgOpts;
        
        llSetTimerEvent(0.0);
        gId = llDetectedKey(0);

        numOf = llGetListLength(gItemList) / 2;

        if (numOf > 0)
        {
            gMenuIndex = 0;
            dlgOpts = GetItemsMenu(GetItemButtonList(gItemList), gMenuIndex);

            if (numOf >= (gMenuIndex * 6) + 6)
            {
                numOf = (gMenuIndex * 6) + 6;
            }
            
            dlgTxt = DLG_TXT;
            
            for (index = gMenuIndex * 6; index < numOf; index ++)
            {
                dlgTxt += "\n(" + (string)llList2Integer(gItemList, (index * 2) + 1) + ")\t";
                dlgTxt += llList2String(gItemList, index * 2);
            }

            if (gListen != 0)
            {
                llListenRemove(gListen);
            }
            
            gListen = llListen(COM, "", gId, "");
            llDialog(gId, dlgTxt, dlgOpts, COM);
            
            llSetTimerEvent(60.0);
        }
        else
        {
            llDialog(gId, "\nSorry, this container is empty!", ["OK"], COM);
        }
    }

    timer()
    {
        llSetTimerEvent(0.0);
        
        if (gListen != 0)
        {
            llListenRemove(gListen);
        }

        llInstantMessage(gId, "Dialog Timeout. Please, try again.");
    }

    listen(integer channel, string nam, key id, string message)
    {
        integer index;
        integer numOf;
        string  dlgTxt;
        list    dlgOpts;
        
        llSetTimerEvent(0.0);
        
        if (gListen != 0)
        {
            llListenRemove(gListen);
        }
        
        if (message == "Cancel")
        {
        }
        else if (message == "Next")
        {
            gMenuIndex ++;
            dlgOpts = GetItemsMenu(GetItemButtonList(gItemList), gMenuIndex);
            
            numOf = llGetListLength(gItemList) / 2;

            if (numOf >= (gMenuIndex * 6) + 6)
            {
                numOf = (gMenuIndex * 6) + 6;
            }
            
            dlgTxt = DLG_TXT;
            
            for (index = gMenuIndex * 6; index < numOf; index ++)
            {
                dlgTxt += "\n(" + (string)llList2Integer(gItemList, (index * 2) + 1) + ")\t";
                dlgTxt += llList2String(gItemList, index * 2);
            }

            gListen = llListen(COM, "", gId, "");
            llDialog(gId, dlgTxt, dlgOpts, COM);
            
            llSetTimerEvent(60.0);
        }
        else if (message == "Prev")
        {
            gMenuIndex --;
            dlgOpts = GetItemsMenu(GetItemButtonList(gItemList), gMenuIndex);
            
            numOf = llGetListLength(gItemList) / 2;

            if (numOf >= (gMenuIndex * 6) + 6)
            {
                numOf = (gMenuIndex * 6) + 6;
            }
            
            dlgTxt = DLG_TXT;
            
            for (index = gMenuIndex * 6; index < numOf; index ++)
            {
                dlgTxt += "\n(" + (string)llList2Integer(gItemList, (index * 2) + 1) + ")\t";
                dlgTxt += llList2String(gItemList, index * 2);
            }

            gListen = llListen(COM, "", gId, "");
            llDialog(gId, dlgTxt, dlgOpts, COM);
            
            llSetTimerEvent(60.0);
        }
        else
        {
            string  itemName;
            list    itemList;
                
            // get full item name from trimed button name
            itemList = GetItemsMenu(GetItemButtonList(gItemList), gMenuIndex);
            
            index = llListFindList(itemList, [message]);
            index += gMenuIndex * 6;
            index *= 2;
            
            itemName = llList2String(gItemList, index);

            // get number of items
            index ++;
            numOf = llList2Integer(gItemList, index);
            numOf --;

            llGiveInventory(gId, itemName);

            // update item list
            if (numOf > 0)
            {
                gItemList = llListReplaceList(gItemList, [numOf], index, index);
            }
            else
            {
                gItemList = llDeleteSubList(gItemList, index - 1, index);
                llRemoveInventory(itemName);
            }
        }
    }

    changed(integer change)
    {
        if (change & CHANGED_ALLOWED_DROP || CHANGED_INVENTORY)
        {
            UpdateInventoryList();
        }
    }
    
    on_rez(integer start_param)
    {
        llResetScript();
    }
}

//////////////////////////////////////////////////////////////////////////

// For More information, see the TradeMogul website
/// at http://ezc.davedorm.com/trademogul

//////////////////////////////////////////////////////////////////////////