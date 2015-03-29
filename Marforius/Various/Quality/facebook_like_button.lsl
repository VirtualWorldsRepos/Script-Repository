list likes;
list dislikes;
list loves;

msg_vote(key id, string vote, integer duplicate) {
    if (duplicate == 0) {
        llRegionSayTo(id, 0, "Your " + vote + " vote was recorded.");
        llOwnerSay(avatar_profile_link(id) + " now " + vote + "s you.");
    }
    else {
        llRegionSayTo(id, 0, "Your vote was a duplicate, and discarded.");
    }
}


string avatar_profile_link(key id) {
    return "secondlife:///app/agent/" + (string) id + "/about";
}

string like_settext;
string dislike_settext;
string love_settext;

// There are invisible mesh prims around the buttons that this function takes into account, they were partially left in because of an edit
// However, they add to the clickability of the buttons!
Update_Votes() {
    // likes
    llSetLinkPrimitiveParamsFast(7, [PRIM_TEXT, like_settext, < 1.000, 1.000, 1.000 > , 1]);
    llSetLinkPrimitiveParamsFast(6, [PRIM_TEXT, "", < 1.000, 1.000, 1.000 > , 1]);

    // dislikes
    llSetLinkPrimitiveParamsFast(5, [PRIM_TEXT, dislike_settext, < 1.000, 1.000, 1.000 > , 1]);
    llSetLinkPrimitiveParamsFast(4, [PRIM_TEXT, "", < 1.000, 1.000, 1.000 > , 1]);

    // loves
    llSetLinkPrimitiveParamsFast(3, [PRIM_TEXT, love_settext, < 1.000, 1.000, 1.000 > , 1]);
    llSetLinkPrimitiveParamsFast(2, [PRIM_TEXT, "", < 1.000, 1.000, 1.000 > , 1]);
}

Remove_Any_Other_Votes_And_Apply_Vote_To_Selection(key toucher, string vote) {
    integer place;
    if (vote == "dislike") {
        if (~llListFindList(likes, (list) toucher)) {
            place = llListFindList(likes, [toucher]);
            likes = llDeleteSubList(likes, place, place);
        }
        else if (~llListFindList(loves, (list) toucher)) {
            place = llListFindList(loves, [toucher]);
            loves = llDeleteSubList(loves, place, place);
        }
        dislikes = [toucher] + dislikes;
    }
    else if (vote == "like") {
        if (~llListFindList(dislikes, (list) toucher)) {
            place = llListFindList(dislikes, [toucher]);
            dislikes = llDeleteSubList(dislikes, place, place);
        }
        else if (~llListFindList(loves, (list) toucher)) {
            place = llListFindList(loves, [toucher]);
            loves = llDeleteSubList(loves, place, place);
        }
        likes = [toucher] + likes;
    }
    else if (vote == "love") {
        if (~llListFindList(dislikes, (list) toucher)) {
            place = llListFindList(dislikes, [toucher]);
            dislikes = llDeleteSubList(dislikes, place, place);
        }
        else if (~llListFindList(likes, (list) toucher)) {
            place = llListFindList(likes, [toucher]);
            likes = llDeleteSubList(likes, place, place);
        }
        loves = [toucher] + loves;
    }
}

Init_Vote(key toucher, string vote) {
    if (vote == "like") {
        if (~llListFindList(likes, (list) toucher)) {
            msg_vote(toucher, vote, 1);
        }
        else {
            msg_vote(toucher, vote, 0);
            Remove_Any_Other_Votes_And_Apply_Vote_To_Selection(toucher, vote);
        }
    }
    else if (vote == "dislike") {
        if (~llListFindList(dislikes, (list) toucher)) {
            msg_vote(toucher, vote, 1);
        }
        else {
            msg_vote(toucher, vote, 0);
            Remove_Any_Other_Votes_And_Apply_Vote_To_Selection(toucher, vote);
        }
    }
    else if (vote == "love") {
        if (~llListFindList(loves, (list) toucher)) {
            msg_vote(toucher, vote, 1);
        }
        else {
            msg_vote(toucher, vote, 0);
            Remove_Any_Other_Votes_And_Apply_Vote_To_Selection(toucher, vote);
        }
    }
}

key owner;
default {
    on_rez(integer d) {
        if (owner != llGetOwner() && owner != NULL_KEY) {
            // Reset the script on a new owner.
            llResetScript();
        }
    }
    state_entry() {
        owner = llGetOwner();
        llSetTimerEvent(0.1);
        llOwnerSay("Type \"/11 reset\" to reset your likes, dislikes and loves or \"/11 list\" to list who has voted.\nEdited in collaberation with [secondlife:///app/agent/75800968-a31a-424b-98bf-debd0c5994fd/about Mayumi Rieko]");
        llListen(11, "", llGetOwner(), "");
        Update_Votes();
    }

    timer() {
        like_settext = (string) llGetListLength(likes) + " likes";
        dislike_settext = (string) llGetListLength(dislikes) + " dislikes";
        love_settext = (string) llGetListLength(loves) + " loves";
        Update_Votes();
    }

    touch_start(integer total_number) {
        key toucher = llDetectedKey(0);
        integer detected_link_number = llDetectedLinkNumber(0);
        if (toucher == owner) return; // prevent the owner from clicking any of the buttons
        if (detected_link_number == 7 || detected_link_number == 6) {
            Init_Vote(toucher, "like");
        }

        if (detected_link_number == 5 || detected_link_number == 4) {
            Init_Vote(toucher, "dislike");
        }

        if (detected_link_number == 3 || detected_link_number == 2) {
            Init_Vote(toucher, "love");
        }

        if (detected_link_number == 1) {
            // For sim-wide click spammers.
            llOwnerSay(avatar_profile_link(toucher) + " touched the root prim.");
        }
    }

    listen(integer channel, string name, key id, string message) {
        if (message == "reset") {
            llResetScript();
        }
        else if (message == "list") {
            integer avatars_on_list = llGetListLength(likes);
            integer when_to_split; // when to split the string, to evade the troublesome limits lsl has
            string stuff_to_print;
            while (~--avatars_on_list) {
                llOwnerSay("The following people like you: ");
                when_to_split++;
                stuff_to_print += avatar_profile_link(llList2Key(likes, avatars_on_list)) + ", ";
                if (when_to_split == 25 || when_to_split == 50 || when_to_split == 75 || when_to_split == 100) // fancy
                {
                    llOwnerSay(stuff_to_print);
                    stuff_to_print = ""; // flush the string, seperate the waters
                }
                if (avatars_on_list == 0) {
                    llOwnerSay(stuff_to_print + " all like you."); // at the end, for when you don't have enough on the list to trigger the huge if
                }
            }
            avatars_on_list = llGetListLength(dislikes);
            while (~--avatars_on_list) {
                llOwnerSay("The following people dislike you: ");
                when_to_split++;
                stuff_to_print += avatar_profile_link(llList2Key(dislikes, avatars_on_list)) + ", ";
                if (when_to_split == 25 || when_to_split == 50 || when_to_split == 75 || when_to_split == 100) // fancy
                {
                    llOwnerSay(stuff_to_print);
                    stuff_to_print = ""; // flush the string, seperate the waters
                }
                if (avatars_on_list == 0) {
                    llOwnerSay(stuff_to_print + " all dislike you."); // at the end, for when you don't have enough on the list to trigger the huge if
                }
            }
            avatars_on_list = llGetListLength(loves);
            while (~--avatars_on_list) {
                llOwnerSay("The following people love you: ");
                when_to_split++;
                stuff_to_print += avatar_profile_link(llList2Key(loves, avatars_on_list)) + ", ";
                if (when_to_split == 25 || when_to_split == 50 || when_to_split == 75 || when_to_split == 100) // fancy
                {
                    llOwnerSay(stuff_to_print);
                    stuff_to_print = ""; // flush the string, seperate the waters
                }
                if (avatars_on_list == 0) {
                    llOwnerSay(stuff_to_print + " all love you."); // at the end, for when you don't have enough on the list to trigger the huge if
                }
            }
        }
    }
}