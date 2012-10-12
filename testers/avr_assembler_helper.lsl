string note = "AVR Tiny - Arithmetic";
key kQuery;
list set;
integer iLine;
integer NN;

next()
{
    kQuery = llGetNotecardLine(note,++iLine);
}

string getmnem(integer n)
{
    integer j;
    string vs = "";
    if ((n < 0) || (n >= NN)) return vs;
    for (j=0; j<5; j++) vs += llList2String(set,n*5+j) + " ";
    return vs;
}

default
{
    state_entry()
    {
        llSetText("",ZERO_VECTOR,0);
        iLine = -2;
        kQuery = llGetNumberOfNotecardLines(note);
    }
    
    listen(integer ch, string name, key id, string msg)
    {
        list l = llParseString2List(msg,[" "],[]);
        string cmd = llList2String(l,0);
        integer i;
        if (cmd == "cell") {
            llSay(0,llList2String(set,(integer)llList2String(l,1)));
        } else if (cmd == "getmem") {
            llSay(0,(string)llGetFreeMemory()+" bytes free.");
        } else if (cmd == "find") {
            i = llListFindList(set,[llToUpper(llList2String(l,1))]);
            if (i < 0)
                llSay(0,"'"+llList2String(l,1)+"' not found.");
            else
                llSay(0,getmnem(llFloor(i/5)));
        } else if (cmd == "codegen") {
            // TODO
        } else if (cmd == "gensubset") {
            // sub set from another note
        }
    }
    
    dataserver(key query_id, string data)
    {
        integer i;
        if (query_id != kQuery) return;
        else if (iLine == -2) {
            iLine++;
            set = [];
            NN = llFloor((float)data / 5.0);
            for (i=0; i<NN; i++)
                set += ["m","o","d","p","f"];
            llSay(0,"Loading set for "+(string)NN+" mnemonics.\nMemory allocated for "+(string)llGetListLength(set)+" entries.");
            llSay(0,(string)llGetFreeMemory()+" bytes free.");
            next();
            return;
        } else if (data == "") {
            next();
            return;
        } else if (data == EOF) {
            llSetText("",ZERO_VECTOR,0);
            llSay(0,"Reading and placing is done!");
            llSay(0,(string)llGetFreeMemory()+" bytes free after the process.");
            llSetTimerEvent(2.0);
            llListen(0,"",llGetOwner(),"");
            llResetTime();
            return;
        }
        if (iLine < NN) i = iLine * 5;
        else if (iLine < NN*2) i = (iLine - NN) * 5 + 1;
        else if (iLine < NN*3) i = (iLine - 2*NN) * 5 + 2;
        else if (iLine < NN*4) i = (iLine - 3*NN) * 5 + 3;
        else if (iLine < NN*5) i = (iLine - 4*NN) * 5 + 4;
        //llOwnerSay("DEBUG:\niLine="+(string)iLine+"\ni="+(string)i+"\n"+data);
        //if (i >= llGetListLength(set)) { llSay(0,"Err"); return; }
        set = llListReplaceList(((set=[])+set),[data],i,i);
        llSetText((string)iLine+" / "+(string)(NN*5),<1,0,0>,1);
        next();
    }
    
    timer()
    {
        llSetText(getmnem(llFloor(llFrand(NN))),<1,1,1>,1.0);
    }
    
    on_rez(integer p)
    {
        llResetScript();
    }
    
    touch_start(integer p)
    {
        llWhisper(0,llDumpList2String(set,"|"));
    }
}

