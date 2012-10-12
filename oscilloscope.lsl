// (C) Elizabeth Walpanheim, 2012
// BSD license
integer chan = -180;
integer leng = 120;
float theta = 0.016667;
string buf;
string csc;
string lst;
string hld;
integer syncf;
integer h_lst;

render()
{
    llSetText(buf+"\nch = "+(string)chan,<1,1,1>,1);
}

add(string msg)
{
    string hd = llGetSubString(buf,0,0);
    if ((hd == "/") || (hd == "\\")) buf = llGetSubString(buf,2,-1);
    else buf = llGetSubString(buf,1,-1);
    if (msg == lst) {
        if (msg == "0") buf += "_";
        else buf += "*";
    } else {
        if (msg == "1") buf += "/*";
        else buf += "\\_";
    }
    lst = msg;
    render();
}

init()
{
    integer i;
    buf = "";
    for (i=0; i<leng; i++) buf += "_";
    csc = "";
    lst = "0";
    hld = "0";
    render();
}

sync(integer on)
{
    syncf = on;
    if (on) {
        llSetTimerEvent(theta);
        llSay(0,"Sync Ready. Theta = "+(string)theta);
        llResetTime();
    } else {
        llSetTimerEvent(0);
        llSay(0,"Ready. Async mode.");
    }
    init();
}

default
{
    state_entry()
    {
        h_lst = llListen(chan,"","","");
        llListen(0,"",llGetOwner(),"");
        sync(0);
    }
    
    listen(integer ch, string name, key id, string msg)
    {
        if (chan == ch) {
            msg = llGetSubString(msg,0,0);
            if ((msg != "0") && (msg != "1")) return;
            if (syncf) hld = msg;
            else add(msg);
        } else {
            list l = llParseString2List(msg,[" "],[]);
            string cmd = llList2String(l,0);
            if (cmd == "sync") sync(1);
            else if (cmd == "async") sync(0);
            else if (cmd == "flush") init();
            else if (cmd == "chan") {
                integer j = (integer)llList2String(l,1);
                if (j == 0) {
                    llSay(0,"Invalid argument");
                    return;
                }
                llListenRemove(h_lst);
                h_lst = llListen(j,"","","");
                llSay(0,"New sensor on channel "+(string)j);
            } else if ((cmd == "freq") || (cmd == "period")) {
                float jf = (float)llList2String(l,1);
                if (jf <= 0.0) {
                    llSay(0,"Invalid argument");
                    return;
                }
                sync(0); // reset timers, etc
                if (cmd == "period") {
                    theta = jf;
                    jf = 1.0 / theta;
                } else {
                    theta = 1.0 / jf;
                }
                llSay(0,"New period ~ "+(string)theta+" sec.");
                llSay(0,"New frequency ~ "+(string)jf+" Hz");
                sync(1);
            } else if (cmd == "setlen") {
                leng = (integer)llList2String(l,1);
                sync(syncf);
            }
        }
    }
    
    timer()
    {
        if (!syncf) return;
        add(hld);
        llResetTime();
    }

    touch_start(integer total_number)
    {
        llSay(0,"resetting...");
        llResetScript();
    }
    
    on_rez(integer p)
    {
        //if (p > 0) chan = p;
        //state default;
        llResetScript();
    }
}

