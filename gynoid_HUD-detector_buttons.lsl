integer GynoidIChan = -257776; // internal channel
string battery = "g-battery";

key mkey;
integer m_n;
string fnm;
integer c_lev;
integer cntfr;

default
{
    state_entry()
    {
        llSetText("",ZERO_VECTOR,1.0);
        mkey = NULL_KEY;
        m_n = (integer)llGetObjectName();
        fnm = "";
        c_lev = -1;
        cntfr = 0;
        llListen(GynoidIChan,"","","");
        llSetTimerEvent(1.5);
    }

    touch_start(integer total_number)
    {
        if (mkey) llSay(1,(string)mkey);
    }
    
    link_message(integer sender, integer p1, string p2, key p3)
    {
        if (llToUpper(p2) == "RESET") llResetScript();
        else if ((p2 == "SET") && (m_n == p1)) {
            mkey = p3;
            c_lev = 0;
            fnm = "";
        }
        llResetTime();
    }
    
    timer()
    {
        if ((fnm == "") && (mkey != NULL_KEY)) {
            string nm = llKey2Name(mkey);
            if (nm == "") {
                fnm = "";
                mkey = NULL_KEY;
                cntfr = 1;
            } else {
                list l = llParseString2List(nm,[" "],[]);
                fnm = llList2String(l,0) + "\n" + llList2String(l,1) + "\nBattery: ";
                cntfr = 0;
            }
        }
        cntfr++;
        if (cntfr == 15) llSetText("",ZERO_VECTOR,0);
        llResetTime();
    }
    
    listen(integer _chan, string _name, key _id, string _msg)
    {
        if ((llGetOwnerKey(_id) == mkey) && (_name == battery)) {
            c_lev = (integer)_msg;
            if (fnm != "")
                llSetText(fnm+(string)c_lev,<1.0,1.0,1.0>,1.0);
            cntfr = 0;
        }
    }
}

