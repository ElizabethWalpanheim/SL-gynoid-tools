// vaginal message pipe logger and user commands processor
integer cpu_rev = 1;
integer CyberVaginaChannel = -76616769;
integer cmdPU_Ch = 12;
vector color = <1,1,1>;
integer depth = 5;
integer h_vagLst;
key owner;
list log;
list commands_help = ["help - this message","change_channel","etc"];

//TODO: add transparency faders on message events

update()
{
    string vs = "";
    integer i = llGetListLength(log);
    if (i > depth)
        log = llDeleteSubList(log,0,(i-depth-1));
    for (i=0; i<depth; i++)
        vs += llList2String(log,i) + "\n";
    llSetText(vs,color,1);
}

default
{
    state_entry()
    {
        llSetText("LOGGER",ZERO_VECTOR,1);
        h_vagLst = llListen(CyberVaginaChannel,"","","");
        owner = llGetOwner();
        log = [];
    }
    
    state_exit()
    {
        llListenRemove(h_vagLst);
        log = [];
    }
    
    link_message(integer sndr, integer num, string str, key id)
    {
        if (str == "reset") llResetScript();
        else {
            list l = llParseString2List(str,["|"],[]);
            string c = llList2String(l,0);
            string a = llList2String(l,1);
            if (c == "setlogdepth") depth = (integer)a;
            else if (c == "setlogcolorall") color = (vector)a;
        }
    }
    
    listen(integer ch, string name, key id, string msg)
    {
        if ((llGetOwnerKey(id) != owner) || (msg == "PING")) return;
        log += [msg];
        update();
    }
    
    touch_start(integer p)
    {
        state commandPU;
    }
}

state commandPU
{
    state_entry()
    {
        llSetText("Command Processor [rev. "+(string)cpu_rev+"]",ZERO_VECTOR,1);
        llOwnerSay("HUD Command processor channel is "+(string)cmdPU_Ch);
        h_vagLst = llListen(cmdPU_Ch,"",owner,"");
        log = [];
    }
    
    state_exit()
    {
        llListenRemove(h_vagLst);
        log = [];
    }
    
    touch_start(integer p)
    {
        state default;
    }
    
    timer()
    {
        //
    }
    
    listen(integer ch, string name, key id, string msg)
    {
        list cl = llParseString2List(msg,[" "],[]);
        log += ["$ "+msg];
        update();
        string cmd = llList2String(cl,0);
        if (cmd == "help") {
            log += commands_help;
        } else if (cmd == "change_channel") {
            CyberVaginaChannel = (integer)llList2String(cl,1);
        } else {
            log += ["Unknown command."];
        }
        update();
    }
    
    link_message(integer sndr, integer num, string str, key id)
    {
        if (str == "reset") llResetScript();
    }
}

