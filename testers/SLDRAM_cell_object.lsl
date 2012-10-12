//dynamic ram simple 2
// (c) Elizabeth Walpanheim,2012
integer icChan = -987110;
float litDelay = 1.2;

integer capacity;
list memory;
integer my_no;
key owner;
integer low;
integer hig;
integer litf;

lit()
{
    litf = 1;
    llSetTimerEvent(litDelay);
    llSetPrimitiveParams([PRIM_GLOW,ALL_SIDES,0.8]);
    llResetTime();
}

out(string s)
{
    llSay(icChan,s);
    lit();
    // maybe some debug out
}

resize(integer sz)
{
    memory = [];
    if (my_no < 0) return;
    capacity = sz;
    low = capacity * my_no;
    hig = low + capacity - 1;
    llOwnerSay("#"+(string)my_no+" Number "+(string)my_no+" is registered.\nLow = "+(string)low+"\nHigh = "+(string)hig);
    lit();
    integer i;
    for (i=0; i<capacity; i++) memory += [0];
    llOwnerSay("#"+(string)my_no+" Free memory: "+(string)llGetFreeMemory()+" bytes.");
    lit();
}

default
{
    state_entry()
    {
        my_no = -1;
        low = -1;
        hig = -1;
        memory = [];
    }
    
    on_rez(integer p)
    {
        owner = llGetOwner();
        my_no = p - 10;
        if (my_no < 0) state dead;
        llListen(icChan,"","","");
    }
    
    listen(integer ch, string nam, key id, string msg)
    {
        if (llGetOwnerKey(id) != owner) return;
        list lt = llParseString2List(msg,[" "],[]);
        string vs = llList2String(lt,0);
        integer adr = llList2Integer(lt,1);
        if (vs == "GET") {
            if ((adr < low) || (adr > hig)) return;
            out("VAL "+(string)adr+" "+(string)llList2Integer(memory,(adr-low)));
        } else if (vs == "PUT") {
            if ((adr < low) || (adr > hig)) return;
            adr -= low;
            memory = llListReplaceList(memory,[llList2Integer(lt,2)],adr,adr);
        } else if (vs == "RESIZE") {
            resize(llList2Integer(lt,1));
        } else if (vs == "DELETE") llDie();
    }
    
    timer()
    {
        if (litf) {
            litf = 0;
            llSetPrimitiveParams([PRIM_GLOW,ALL_SIDES,0.0]);
            llSetTimerEvent(0);
            llResetTime();
        }
    }
    
    touch_start(integer p)
    {
        if (llDetectedKey(0) != llGetOwner()) return;
        llOwnerSay("I'm #"+(string)my_no+"\nLow = $"+(string)low+"\nHigh = $"+(string)hig);
        llOwnerSay((string)llGetFreeMemory()+" bytes free.");
        lit();
    }
}

state dead
{
    state_entry()
    {
        llOwnerSay("Object dead");
    }
    on_rez(integer p)
    {
        llResetScript();
    }
}

