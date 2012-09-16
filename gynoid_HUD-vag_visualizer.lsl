integer CyberVaginaChannel = -76616769;
vector color = <1,0,0.6>;
key owner;
list last;

upd()
{
    integer i;
    string vs = "";
    for (i=5; i>2; i--)
        vs += llList2String(last,i) + "\n";
    llSetText(vs,color,1);
    llSetTimerEvent(5);
    llResetTime();
}

default
{
    state_entry()
    {
        llSetText("",ZERO_VECTOR,0);
        llListen(CyberVaginaChannel,"","","");
        owner = llGetOwner();
        last = [0.5,0.5,0.5,"o","()","[]"];
        upd();
    }
    
    link_message(integer sndr, integer num, string str, key id)
    {
        if (str == "reset") llResetScript();
    }
    
    listen(integer ch, string name, key id, string msg)
    {
        if (llGetOwnerKey(id) != owner) return;
        if (llGetSubString(msg,0,6) != "HUD vag") return;
        list l = llParseString2List(msg,[" "],[]);
        float f = (float)llList2String(l,3);
        integer n = (integer)llList2String(l,2);
        if ((n < 0) || (n > 2)) {
            llOwnerSay("ERR: n is out of range! line 28");
            return;
        }
        integer b = 0;
        string vs;
        if (f <= llList2Float(last,n)) b = 1;
        last = llListReplaceList(last,[f],n,n);
        if (n == 2) {
            if (b) vs = "[<- ^ ->]";
            else vs = "[-><-]";
        } else if (n == 1) {
            if (b) vs = "(<-->)";
            else vs = "(><)";
        } else if (n == 0) {
            if (b) vs = "<0>";
            else vs = "o";
        }
        last = llListReplaceList(last,[vs],n+3,n+3);
        upd();
    }
    
    timer()
    {
        llSetTimerEvent(0);
        last = llListReplaceList(last,["o","()","[]"],3,5);
        upd();
    }
    
    touch_start(integer p)
    {
        llOwnerSay("Reset...");
        llMessageLinked(LINK_SET,0,"reset",NULL_KEY);
    }
}

