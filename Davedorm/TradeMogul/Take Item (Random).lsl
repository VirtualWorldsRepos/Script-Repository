//////////////////////////////////////////////////////////////////////////

// Filename:    TradeMogul Take Item From Crate
// Version:     0.1
// Date:        09.03.2010

// Creator:     DaveDorm Gaffer

// Description: 

//////////////////////////////////////////////////////////////////////////

// A distibution crate that stores a quantity of a single prduct. This is to represent a "case" of jars or other boxes sold in bulk. Hovertext is set in the Object Name, recipient must be within 2m of the crate to take an item. This is to cut down on "shopliftng," as this is not a vendor. The crate has no expiration, however items inside may be timed. When clicked, one object is given to the recipient. Once they are gone, the crate is empty and will IM the owner to be restocked.

//////////////////////////////////////////////////////////////////////////

float totalobjects;
key gId;

default
{
    state_entry()
    {
        gId = llGetOwner();
        totalobjects = llGetInventoryNumber(INVENTORY_OBJECT);
        llSetText(llGetObjectName() + "\n \n \n", <1.0,0.5,0.0>, 1);

    }
        
    touch_start(integer total_number)
    {
        llSensor(llKey2Name(gId),gId,1,2,PI);
        totalobjects = llGetInventoryNumber(INVENTORY_OBJECT);
        if (totalobjects == 0)
        {
            llInstantMessage(llGetOwner(),llGetObjectName() + " crate is empty. Please reorder!");
        }
        totalobjects = llFrand(totalobjects);
        llGiveInventory(llDetectedKey(0),llGetInventoryName(INVENTORY_OBJECT, (integer)totalobjects));
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