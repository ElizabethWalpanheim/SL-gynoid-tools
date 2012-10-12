// SLDRAM tester object
// idea && implement done by me, Elizabeth Walpanheim
// (c) 2012
string objname = "SDMC simple 2";
vector dpos = <-5, 0, 0.5>;
vector rpos = <0.2, 0, 0>;
vector spos = <0, 0, 0.15>;
vector cpos;

integer icChan = -987110;
integer mem_top = 24;
integer cell_size = 2048;

integer st;

integer wait;
integer req_adr;

default
{
    state_entry()
    {
        llSay(icChan,"DELETE ");
        llSleep(2.0);
        llOwnerSay("Prepare. Size is "+(string)mem_top+" KB");
        llListen(icChan,"","","");
        mem_top = mem_top * 4096;
        llOwnerSay("Need "+(string)mem_top+" integer LSL cells");
        integer cells = llCeil((float)mem_top / (float)cell_size);
        llOwnerSay("Need "+(string)cells+" DRAM cells");
        integer i;
//        cpos = dpos;
        for (i=0; i<cells; i++) {
            llRezObject(objname,(llGetPos()+dpos),ZERO_VECTOR,llGetRot(),(i+10));
            dpos += rpos;
            // need more complicated mechanism to create more elements
        }
        llOwnerSay("rezzed");
        st = 0;
    }
    
    touch_start(integer p)
    {
        if (llDetectedKey(0) != llGetOwner()) return;
        if (st == 0) {
            st = 1;
            llWhisper(0,"resizing");
            llSay(icChan,"RESIZE "+(string)cell_size);
            return;
        } else if (st == 1) {
            llSetTimerEvent(1.5);
            llOwnerSay("go");
            wait = 0;
            st = 2;
        } else if (st == 2) {
            llSetTimerEvent(0.0); // for queue freeeing reason
            llOwnerSay("pause");
            st = 1;
        }
        llResetTime();
    }
    
    timer()
    {
        if (wait == 0) {
            req_adr = llCeil(llFrand((float)mem_top));
            integer nw = llCeil(llFrand(256));
            string vs = "PUT "+(string)req_adr+" "+(string)nw;
            llWhisper(0,vs);
            llSay(icChan,vs);
            wait++;
        } else if (wait == 1) {
            string vs = "GET "+(string)req_adr;
            llWhisper(0,vs);
            llSay(icChan,vs);
            wait++;
        }
        llResetTime();
    }
    
    listen(integer ch, string nam, key id, string msg)
    {
        if (!wait) return;
        if (llGetOwnerKey(id) != llGetOwner()) return;
        list lt = llParseString2List(msg,[" "],[]);
        if (llList2String(lt,0) == "VAL") {
            if (llList2Integer(lt,1) == req_adr) {
                llWhisper(0,"Successfully received value: $"+(string)req_adr+" = "+(string)llList2Integer(lt,2));
                wait = 0;
                llResetTime();
            } else {
                llWhisper(0,"Memory error at request $"+(string)req_adr+" : received of $"+(string)llList2Integer(lt,1));
            }
        }
    }
    
    on_rez(integer p)
    {
        llResetScript();
    }
}

