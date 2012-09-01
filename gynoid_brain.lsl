/*
    Here will be something
*/

string version = "0.0.1.16";

integer GynoidIChan = -257776; // internal channel
integer GynoidRChan = -257770; // remote control channel

string config = "config";
string battery = "g-battery";

integer idebug = 10;

// **********************************************************************************

integer pBattery;
float pCharge;
float pBatInit;

string pAnim_EFail;
string pAnim_POff;
string pAnim_Pause;
string pAnim_RChrg;

list pData_Embed;
string pData_Charger;

key owner;
string hello;
key tmpKey;
integer tmpCount;
key followTo;
integer cIC;
integer cRC;
integer disableReason;
string cAO;
string nextDance;
integer curBat;

// **********************************************************************************

debug(integer lev, string str)
{
    // shows debug info
    if (lev <= idebug) {
        llOwnerSay("DEBUG (level "+(string)lev+"): "+str);
    }
}

parse(string data)
{
    list l = llParseString2List(data,[" "],[]);
    if (llGetListLength(l) < 1) return;
    // commands
    string param = llList2String(l,0);
    if (param == "i-channel") {
        GynoidIChan = llList2Integer(l,1);
        //
    } else if (param == "r-channel") {
        GynoidRChan = llList2Integer(l,1);
        //
    } else if (param == "battery") {
        pBattery = llList2Integer(l,1);
        //
    } else if (param == "charge") {
        pCharge = llList2Float(l,1);
        //
    } else if (param == "batinit") {
        pBatInit = llList2Float(l,1);
        //
    } else if (param == "anim_energyfail") {
        pAnim_EFail = llList2String(l,1);
        //
    } else if (param == "anim_poweroff") {
        pAnim_POff = llList2String(l,1);
        //
    } else if (param == "anim_paused") {
        pAnim_Pause = llList2String(l,1);
        //
    } else if (param == "anim_recharge") {
        pAnim_RChrg = llList2String(l,1);
        //
    } else if (param == "charger_name") {
        pData_Charger = llList2String(l,1);
        //
    } else if (param == "int_anim") {
        pData_Embed += [llList2String(l,1)];
        pData_Embed += [llList2Key(l,2)];
        //
    } else if (param != "//") {
        debug(1,"Unknown param "+param);
    }
}

key myGetInventoryKey(string nam)
{
    //
    key tmp = llGetInventoryKey(nam);
    integer i;
    integer n = llGetListLength(pData_Embed); // for speed reasons
    if (tmp == NULL_KEY) {
        for (i=0; i<n; i+=2) {
            if (nam==llList2String(pData_Embed,i)) {
                tmp = llList2Key(pData_Embed,(i+1));
                i = n;
            }
        }
    }
    return tmp;
}

string disasmcmd(string cmd)
{
    string _res;
    list _cmd = llParseString2List(cmd,[" "],[]);
//    debug(2,"cmd disasm: "+(string)_cmd);
    if (llGetListLength(_cmd)<2) return _res;
    key _tmk = llList2Key(_cmd,1);
    if (_tmk != owner) return _res;
    _res = llList2String(_cmd,0);
    return _res;
}

// **********************************************************************************

default
{
    state_entry()
    {
        debug(1,"Default entry point reached!");
        disableReason = 0;
        pData_Embed = [];
        owner = llGetOwner();
    }

    attach(key id)
    {
        if (owner != llGetOwner()) llResetScript();
        hello = llKey2Name(owner) + "'s -=Gynoid_Brain=- ver. " + version;
        if (id==NULL_KEY) {
            // detached
            llSay(0,hello+" is detached!");
            llSleep(0.5);
        } else {
            // attached
            llSay(0,hello+" is attached!");
            llRequestPermissions(llGetOwner(),PERMISSION_TRIGGER_ANIMATION | PERMISSION_TAKE_CONTROLS);
        }
    }

    run_time_permissions(integer perm)
    {
        if ( (perm & PERMISSION_TAKE_CONTROLS) && (perm & PERMISSION_TRIGGER_ANIMATION) )
        {
            debug(1,"permissions given");
            llTakeControls(0,FALSE,FALSE);
            state powerseq;
        }
    }
    
//    touch_start(integer p)
//    {
//        if (llDetectedKey(0) == llGetOwner()) llResetScript();
//    }
}

// **********************************************************************************

state poweronstd
{
    // controller powered on, receiving basic commands from RC and other sources
    state_entry()
    {
        debug(1,"!poweronstd!");
        cIC = llListen(GynoidIChan,"","","");
        cRC = llListen(GynoidRChan,"","","");
        llTakeControls(0,FALSE,TRUE);
        llSetTimerEvent(1.0);
        llResetTime();
    }
    
    listen(integer _chan, string _name, key _id, string _msg)
    {
        if (_chan == GynoidIChan) {
            debug(3,"IC received: "+_msg);
            if ((_name == battery) && (llGetOwnerKey(_id)==owner)) {
                curBat = (integer)_msg;
                return;
            } else if (_name == pData_Charger) {
                if (disasmcmd(_msg) == "CHRG-attach") {
                    // charger connected
                    disableReason = 4;
                    llSay(0,"I'm connected to charger module!");
                    state bodydisabled;
                }
            }
        } else if (_chan == GynoidRChan) {
            debug(3,"RC received: "+_msg);
            string tmp = disasmcmd(_msg);
            if (tmp=="") return;
        }
    }
    
    timer()
    {
        if (curBat < 1) {
            disableReason = 1;
            state bodydisabled;
        }
    }
    
    state_exit()
    {
        debug(2,"leaving poweron state");
        llListenRemove(cIC);
        llListenRemove(cRC);
    }
    
    attach(key id)
    {
        if (id==NULL_KEY) {
            // detached
            llSay(0,hello+" is detached!");
            state default;
        }
    }
}

state rctoy
{
    // RC-controlled toy state, accepts extended RC commands
    state_entry()
    {
        debug(1,"!rctoy!");
        llTakeControls(0,FALSE,FALSE);
        cIC = llListen(GynoidIChan,"","","");
        cRC = llListen(GynoidRChan,"","","");
        llSetTimerEvent(1.0);
        llResetTime();
    }
    
    listen(integer _chan, string _name, key _id, string _msg)
    {
        if (_chan == GynoidIChan) {
            debug(3,"IC received: "+_msg);
            if ((_name == battery) && (llGetOwnerKey(_id)==owner)) {
                curBat = (integer)_msg;
                return;
            }
        } else if (_chan == GynoidRChan) {
            debug(3,"RC received: "+_msg);
        }
    }
}

state doll
{
    // follower doll state, accepts only basic RC commands, following any avi/obj
    state_entry()
    {
        debug(1,"!doll!");
        llTakeControls(0,FALSE,FALSE);
        cIC = llListen(GynoidIChan,"","","");
        cRC = llListen(GynoidRChan,"","","");
        llSetTimerEvent(1.0);
        llResetTime();
    }
    
    listen(integer _chan, string _name, key _id, string _msg)
    {
        if (_chan == GynoidIChan) {
            debug(3,"IC received: "+_msg);
            if ((_name == battery) && (llGetOwnerKey(_id)==owner)) {
                curBat = (integer)_msg;
                return;
            }
        } else if (_chan == GynoidRChan) {
            debug(3,"RC received: "+_msg);
        }
    }
}

state bodydisabled
{
    // RC and body controls disabled, animations overrided
    state_entry()
    {
        debug(1,"!bodydisabled!");
        debug(1,"Reason = "+(string)disableReason);
        cIC = 0;
        cAO = "";
        if (disableReason == 1) { // out-of-energy
            cAO = pAnim_EFail;
            llSay(0,"Out of energy! Please replace my battery!");
        } else if (disableReason == 2) { // shutdown
            cAO = pAnim_POff;
            llSay(0,"I'm going to shutdown!");
        } else if (disableReason == 3) { // pause
            cAO = pAnim_Pause;
            llSay(0,"-=PAUSED=-");
        } else if (disableReason == 4) { // recharge
            cAO = pAnim_RChrg;
        } else if (disableReason == 10) { // dancing
            cAO = nextDance;
        } else {
            llOwnerSay("Error: unexpected disable!");
            state poweronstd;
            return; // just in case
        }
        tmpKey = myGetInventoryKey(cAO);
        if (tmpKey==NULL_KEY) {
            llOwnerSay("Error: animation "+cAO+" not found in inventory!");
            state poweronstd;
            return; // just in case
        }
        cIC = llListen(GynoidIChan,"","","");
        llTakeControls(0,FALSE,FALSE);
        llStartAnimation(cAO);
        tmpCount = 0;
        llSetTimerEvent(1.0);
        llResetTime();
    }
    
    listen(integer _chan, string _name, key _id, string _msg)
    {
        if (_chan != GynoidIChan) return;
        debug(3,"IC received: "+_msg);
        if ((_name == battery) && (llGetOwnerKey(_id)==owner) && (disableReason != 4)) {
            curBat = (integer)_msg;
            return;
        }
        if ((disableReason == 4) && (_name == pData_Charger) && (disasmcmd(_msg) == "CHRG-detach")) {
            // charger disconnected
            llSay(0,"I'm disconnected from charger module!");
            state poweronstd;
        }
    }
    
    timer()
    {
        if (cAO == "") {
            llSetTimerEvent(0);
            return;
        }
        // Here is a simple timer-driven animation overrider
        list anm = llGetAnimationList(owner);
        integer i;
        integer n = llGetListLength(anm);
        key tK;
        for (i=0; i<n; i++) {
            tK = llList2Key(anm,i);
            if (tK != tmpKey) llStopAnimation(tK);
        }
        // get battery state
        if ((disableReason == 3) || (disableReason > 9)) {
            if (curBat < 1) state poweronstd;
        } else if (disableReason == 1) {
            if (curBat > 0) state poweronstd;
        } else if (disableReason == 4) {
            tmpCount++;
            i = (integer)(pBattery * pCharge * 60);
            n = (integer)(tmpCount * pBattery / i);
//            n = curBat + ((integer)(pBattery/i));
            if (n > pBattery) n = pBattery;
            curBat = n;
            debug(2,"Power calc has given result "+(string)n+" after "+(string)tmpCount+" sec.");
            llWhisper(GynoidIChan,"PWR "+(string)n);
        }
        // reset
        llResetTime();
    }
    
    state_exit()
    {
        debug(2,"leaving disabled state");
        if (cIC) llListenRemove(cIC);
        if (tmpKey!=NULL_KEY) llStopAnimation(tmpKey);
    }
    
    attach(key id)
    {
        if (id==NULL_KEY) {
            // detached
            llSay(0,hello+" is detached!");
            state default;
        }
    }
}

// **********************************************************************************

state powerseq
{
    // power-up sequence
    state_entry()
    {
        debug(1,"!powerseq!");
        llTakeControls(0,FALSE,FALSE);
        llSay(0,"Starting power-up sequence!");
        tmpCount = 0;
        tmpKey = llGetNotecardLine(config,tmpCount);
    }
    
    dataserver(key qid, string data)
    {
        if (qid == tmpKey) {
            if (data != EOF) {
                if (data != "") parse(data);
                tmpCount++;
                debug(2,"Parsing line "+(string)tmpCount);
                tmpKey = llGetNotecardLine(config,tmpCount);
            } else {
                state findbattery;
            }
        }
    }
}

state findbattery
{
    // controller tries to find gynoid's battery pack
    state_entry()
    {
        debug(1,"!find battery!");
        cIC = llListen(GynoidIChan,"","","");
        tmpCount = 0;
        llTakeControls(0,FALSE,FALSE);
        llSetTimerEvent(24);
        llResetTime();
    }
    
    listen(integer _chan, string _name, key _id, string _msg)
    {
        if (_chan != GynoidIChan) return;
        if ((_name == battery) && (llGetOwnerKey(_id)==owner)) {
            tmpCount++;
            curBat = (integer)_msg;
        }
    }
    
    timer()
    {
        if (tmpCount < 2) {
            llSay(0,"Battery not installed or broken!");
            tmpCount = 0;
        } else {
            llSay(0,"Power-up sequence complete. Brain activated!");
            llWhisper(GynoidIChan,"PWR "+(string)((integer)(pBattery*pBatInit))); // init battery
            state poweronstd;
        }
    }
    
    state_exit()
    {
        debug(2,"leaving find bat state");
        llListenRemove(cIC);
    }
    
    attach(key id)
    {
        if (id==NULL_KEY) {
            // detached
            llSay(0,hello+" is detached!");
            state default;
        }
    }
}

// **********************************************************************************

state dummy
{
    state_entry()
    {
        llOwnerSay("Dummy loop initiated!");
    }
}
