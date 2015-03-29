list beams;
list color_names = ["red","green","blue","yellow","cyan","magenta","white"];
list colors = [<1.0,0,0>,<0,1.0,0>,<0,0,1.0>,<1.0,1.0,0>,<0,1.0,1.0>,<1.0,0,1.0>,<1.0,1.0,1.0>];
integer color_count;
vector INVALID_COLOR = <-1.0,-1.0,-1.0>;
vector color_from_string(string color) {
	integer i;
	for ( i = 0; i < color_count; i++) {
		if (color == llList2String(color_names,i)) {
			return llList2Vector(colors,i);
		}
	}
	return INVALID_COLOR;
}
upgrade() {
//Get the name of the script
	string self = llGetScriptName();
	string basename = self;
// If there is a space in the name, find out if it's a copy number and correct the basename.
	if (llSubStringIndex(self, " ") >= 0) {
// Get the section of the string that would match this RegEx: /[ ][0-9]+$/
		integer start = 2; // If there IS a version tail it will have a minimum of 2 characters.
		string tail = llGetSubString(self, llStringLength(self) - start, -1);
		while (llGetSubString(tail, 0, 0) != " ") {
			start++;
			tail = llGetSubString(self, llStringLength(self) - start, -1);
		}
// If the tail is a positive, non-zero number then it's a version code to be removed from the basename.
		if ((integer) tail > 0) {
			basename = llGetSubString(self, 0, -llStringLength(tail) - 1);
		}
	}
// Remove all other like named scripts.
	integer n = llGetInventoryNumber(INVENTORY_SCRIPT);
	while (n-- > 0) {
		string item = llGetInventoryName(INVENTORY_SCRIPT, n);
// Remove scripts with same name (except myself, of course)
		if (item != self && 0 == llSubStringIndex(item, basename)) {
			llRemoveInventory(item);
		}
	}
}
report() {
	llOwnerSay("Beams: "+llList2CSV(beams));
}
default {
	on_rez(integer numb) {
		llResetScript();
	}
	state_entry() {
		upgrade();
		llSay(0, "Initializing...");
		color_count = llGetListLength(color_names);
		llMessageLinked(LINK_ALL_CHILDREN,1,"register",llGetKey());
		llListen( 7000, "", NULL_KEY, "");
	}
	listen(integer channel, string name, key id, string message) {
		if (llSameGroup(id)) {
			llOwnerSay("Received command ["+message+"] from "+name);
			if (message == "report") {
				report();
				return;
			}
			if (message == "start"){
				llMessageLinked(LINK_ALL_CHILDREN,1,"start",id);
				llTargetOmega(<0,0,5>,6*DEG_TO_RAD,1);
				return;
			}
			if (message == "stop") {
				llMessagedLinked(LINK_ALL_CHILDREN,1,"stop",id);
				llTargetOmega(<0,0,0>,0,0);
				return;
			}
			vector color = color_from_string(message);
			if (color != INVALID_COLOR) {
				integer beam_count = llGetListLength(beams);
				integer i;
				for (i = 0; i < beam_count; i++) {
					llSetLinkColor(llList2Integer(beams,i),color,ALL_SIDES);
				}
				return;
			}
			llMessageLinked(LINK_ALL_CHILDREN,1,message,id);
		}
	}
	link_message(integer sender, integer num, string message, key id) {
		llOwnerSay("received ["+message+"] from link ["+(string) num+"] "+(string) id);
		if (message == "beam") {
			beams = (beams=[]) + beams + [num];
		}
	}
}
//********************************************************
//This Script was pulled out for you by YadNi Monde from the LSL WIKI at http://wiki.secondlife.com/wiki/LSL_Library, it is intended to stay FREE by it s author(s) and all the comments here in ORANGE must NOT be deleted. They include notes on how to use it and no help will be provided either by YadNi Monde or it s Author(s). IF YOU DO NOT AGREE WITH THIS JUST DONT USE!!!
//********************************************************
//Thanks to Markov Brodsky's Self Upgrading Script and Jippen Faddoul's update to the idea, I was inspired to add to the flexibility and usefulness of their original works.
//
//Markov Brodsky's original code is quite good, and I based my own implementation upon it, but it has an admitted flaw: It requires that all the scripts that use it have no spaces within the name. For me this will not do. I like my space ;D
//
//Jippen Faddoul's update is also pretty good, but while it is nicely shortened and optimized, it can't handle being copied into the prim more than 2 times. This makes it unusable for my coding style. (Tweak, save, copy, test, repeat...)
//
//So here's my edition to fix those shortcomings. (You may use this code freely and distribute it freely, but DO NOT even try to SELL it.)
//As far as my testing was able to show, I was able to have spaces in my script names and I was even able to tack on a number at the end of my script for personal version tracking and had no troubles. I was able to copy the script into the same prim over and over again with only the latest ever staying.
//
//Cron
//
//Note: Due to the nature of SL, your script's name will alternate between "scriptname" and "scriptname 1", where "scriptname" is the actual name of your script.
// Self Upgrading Script by Cron Stardust based upon work by Markov Brodsky and Jippen Faddoul. If this code is used, this header line MUST be kept.

