integer IM_CHANNEL      = -12610699; // channel to request IMs on
integer SLAVE_CHANNEL   = -12610000; // starting channel for slaves
vector  FIRST_POS       = <148.0, 95.0, 28.0>;
vector  OFFSET          = <0.0, 0.0, 2.0>;
integer PING_CHECK      = 15;

integer MAX_SLAVES      = 5;
list    slaves          = [];
list    slave_owners    = [];
integer current_slave   = 0;
integer num_slaves      = 0;
integer ims             = 0;

status() {
    integer i = 0;
    string str = "Active cores: " + (string)num_slaves + "\n";
    str += "IMs sent: " + (string)ims + "\n\n";

    for(i = 0; i < MAX_SLAVES; ++i) {
        if (llList2Key(slaves,i) == NULL_KEY) {
            str += "[ no core ]\n";
            if(current_slave==i) {
                if (++current_slave >= MAX_SLAVES)
                    current_slave = 0;
            }
        } else {
            str += "[";
            if(current_slave==i) str += ">"; else str += " ";
            str += llList2String(slave_owners,i);
            if(current_slave==i) str += "<"; else str += " ";
            str += "]\n";
        }
    }
    llSetText(str, <1,1,1>, 1.0);
}

default {
    state_entry() {
        llListen(IM_CHANNEL, "", NULL_KEY, "");
        integer i;
        for ( i = 0; i < MAX_SLAVES; ++i ) {
            llRegionSay( SLAVE_CHANNEL+i, "reset" );
            slaves += [NULL_KEY];
            slave_owners += [NULL_KEY];
        }

        status();
        llSetTimerEvent(PING_CHECK);
    }

    timer() {
        integer i = MAX_SLAVES;
        while ( i-- ) {
            key k = llList2Key(slaves,i);
            if(k!=NULL_KEY) {
                if(llKey2Name(k)=="") {
                    llOwnerSay("lost core " + (string)i + "[" + (string)k + "]");
                    llRegionSay(SLAVE_CHANNEL+i, "reset");
                    slaves = llListReplaceList( slaves, [NULL_KEY], i, i );
                    --num_slaves;
                }
            }
        }
        status();
    }

    dataserver(key qid, string data) {
        integer idx = llListFindList(slave_owners, [qid]);
        if(idx != -1)
            slave_owners = llListReplaceList(slave_owners, [data], idx, idx);
        status();
    }

    listen(integer channel, string name, key id, string msg) {
        if ( name == "register" ) {
            integer idx = llListFindList(slaves, [id]);
            if ( idx == -1 )
                idx = llListFindList( slaves, [NULL_KEY] );

            if ( idx == -1 ) {
                llRegionSay((integer)msg, "full");
                return;
            }

            llRegionSay( (integer)msg,
                         (string)(SLAVE_CHANNEL + idx) +
                         "|" +
                         (string)(FIRST_POS + (OFFSET * idx)) );
            slaves = llListReplaceList( slaves, [id], idx, idx );
            key qid = llRequestAgentData(llGetOwnerKey(id), DATA_NAME);
            slave_owners = llListReplaceList( slave_owners, [qid], idx, idx );
            ++num_slaves;
            status();
            return;
        }

        // no slaves, can't do anything
        if ( num_slaves == 0 )
            return;

        do {
            if ( ++current_slave >= MAX_SLAVES )
                current_slave = 0;
        } while ( llList2Key( slaves, current_slave ) == NULL_KEY );

        llRegionSay( SLAVE_CHANNEL + current_slave, msg );
        ++ims;
        status();
    }
}
