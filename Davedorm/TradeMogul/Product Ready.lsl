//////////////////////////////////////////////////////////////////////////

// Filename:    TradeMogul Product Ready
// Version:     0.1
// Date:        08.31.2010

// Creator:     DaveDorm Gaffer

// Description: 

//////////////////////////////////////////////////////////////////////////

// This is a simple script that responds to the Factory Contol script. This script turn prims invisible while products aren't produced and visible when production is complete. The object can be placed as an indicator that there are products ready to be taken into inventory. There are many purposes for this script, it can indicate fruit on a vine, a crate on a conveyer belt, whatever you wish. 

//////////////////////////////////////////////////////////////////////////


default
{
    link_message(integer send_num, integer num, string str, key id)     {
        if(str=="alpha"){
            llSetLinkAlpha(LINK_THIS,0.0,ALL_SIDES);
        }
        if(str=="nonalpha"){
            llSetLinkAlpha(LINK_THIS,1.0,ALL_SIDES);
        }
    }
}

//////////////////////////////////////////////////////////////////////////

// For More information, see the TradeMogul website
/// at http://ezc.davedorm.com/trademogul

//////////////////////////////////////////////////////////////////////////