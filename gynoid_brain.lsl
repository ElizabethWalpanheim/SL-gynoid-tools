/*
    Here will be something textual ;)
    GPL v3
    
// Compatible with Eliz's MyPussy Script (CyberVagina)
//
// (C) Elizabeth Walpanheim, 2011-2012
*/

string version = "0.1.6.53";

integer GynoidIChan = -257776; // internal channel
integer GynoidRChan = -257770; // remote control channel
integer CyberVaginaChannel = -76616769; // CyberVagina Channel
integer WomIntChatChan = -283751; // womans chat

string config = "config";
string battery = "g-battery";
string cyberVaginaPrefix = "VAGINA!";
string RLVaPrefix = "RestrainedLove viewer";
string WomChatSignature = "VGWCHT00021";

float follow_limit = 60.0;

integer idebug = 2;

// **********************************************************************************

integer pBattery;
float pCharge;
float pBatInit;

string pAnim_EFail;
string pAnim_POff;
string pAnim_Pause;
string pAnim_RChrg;

string pData_Charger;
list pData_Embed;
list pData_SexStatic;
list pData_SexDynamic;
integer pData_lowbat;

key owner;
string owner_name;
string hello;
key tmpKey;
integer tmpCount;
key followTo;
integer followTarg;
integer cIC;
integer cRC;
integer cVC;
integer disableReason;
string cAO;
string nextDance;
integer curBat;
integer lowbat_state;
integer flgVaginaPresent;
integer flgRLVa;
list RLVstrictions;

// **********************************************************************************

debug(integer lev, string str)
{
    // shows debug info
    if (lev <= idebug) {
        llOwnerSay("DEBUG (level "+(string)lev+"): "+str);
    }
}

mySay(string msg)
{
    llWhisper(0,owner_name+"'s brain: "+msg);
}

integer circle(integer cval, integer max)
{
    integer r = cval + 1;
    if (r > max) r = 0;
    return r;
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
    } else if (param == "sex_anim") {
        if (llList2String(l,1) == "stat") {
            pData_SexStatic += [llList2String(l,2)];
        } else {
            pData_SexDynamic += [llList2String(l,2)];
        }
        //
    } else if (param == "lowbat") {
        pData_lowbat = llList2Integer(l,1);
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
    if (llGetListLength(_cmd)<2) return _res;
    if (llList2Key(_cmd,1) != owner) return _res;
    _res = llList2String(_cmd,0);
    return _res;
}

generateTarget(integer d)
{
    list l = llGetObjectDetails(llGetOwner(),[OBJECT_POS,OBJECT_ROT]);
    vector p;
    if (d == 1) p = <2.0,0,0>;
    else if (d == 2) p = <-2.0,0,0>;
    else if (d == 3) p = <0,2.0,0>;
    else if (d == 4) p = <0,-2.0,0>;
    debug(3,(string)p);
    p = llList2Vector(l,0) + p * llList2Rot(l,1);
    debug(3,(string)p);
    llMoveToTarget(p,0.7);
}

processRLV(key id, string msg)
{
    if (flgRLVa == 0) return;
    if (llGetSubString(msg,0,0) != "@") return;
    debug(2,"RLV: "+(string)id+": "+msg);
    key tst = (key)llGetSubString(msg,1,36);
    string nam = llKey2Name(tst);
    if (nam == "") return;
    string rcmd = llGetSubString(msg,37,-1);
    debug(2,"RLV target: "+nam+"\ncommand: "+rcmd);
    list cdl = llParseString2List(rcmd,["@",","],[]);
    debug(2,"RLV commands:\n"+llDumpList2String(cdl,"\n"));
    RLVstrictions += cdl;
    if (llListFindList(RLVstrictions,["clear"]) >= 0) {
        llOwnerSay("@clear,detach=n");
        RLVstrictions = ["detach=n"];
        debug(2,"ProcessRLV: CLEAR command found, cmd list purged");
    }
    llOwnerSay("@"+rcmd);
}

revokeRLV()
{
    llOwnerSay("@clear");
    string res = "@" + llDumpList2String(RLVstrictions,",");
    debug(2,"RLV restrictions:\n"+res);
    llOwnerSay(res);
}

// ****************************************************************************************************************

default
{
    state_entry()
    {
        debug(1,"Default entry point reached!");
        disableReason = 0;
        pData_Embed = [];
        pData_SexStatic = [];
        pData_SexDynamic = [];
        owner = llGetOwner();
        owner_name = llKey2Name(owner);
        flgVaginaPresent = 0;
        flgRLVa = 0;
        llRequestPermissions(owner,PERMISSION_TRIGGER_ANIMATION | PERMISSION_TAKE_CONTROLS);
    }

    attach(key id)
    {
        if (owner != llGetOwner()) {
            llResetScript();
            return;
        }
        hello = " -=Gynoid_Brain=- ver. " + version;
        if (id==NULL_KEY) {
            // detached
            mySay(hello+" is detached!");
            llSleep(0.5);
        } else {
            // attached
            mySay(hello+" is attached!");
            llRequestPermissions(owner,PERMISSION_TRIGGER_ANIMATION | PERMISSION_TAKE_CONTROLS);
        }
    }

    run_time_permissions(integer perm)
    {
        if ( (perm & PERMISSION_TAKE_CONTROLS) && (perm & PERMISSION_TRIGGER_ANIMATION) )
        {
            debug(1,"permissions given");
            llTakeControls(0,FALSE,FALSE);
            llRegionSay(WomIntChatChan,WomChatSignature+"|"+owner_name+"|"+"I'm activated my electronic brain!");
            state powerseq;
        }
    }
    
    touch_start(integer p)
    {
        //if (llDetectedKey(0) == llGetOwner()) 
        llResetScript();
    }
}

// ****************************************************************************************************************

state poweronstd
{
    // controller powered on, receiving basic commands from RC and other sources
    state_entry()
    {
        debug(1,"!poweronstd!");
        cIC = llListen(GynoidIChan,"","","");
        cRC = llListen(GynoidRChan,"","","");
        llTakeControls(0,FALSE,TRUE);
        followTo = NULL_KEY;
        lowbat_state = 0;
        llSetTimerEvent(1.0);
        llResetTime();
        llWhisper(GynoidIChan,cyberVaginaPrefix+"|UPD");
        llWhisper(GynoidIChan,"RUN ");
        llRegionSay(WomIntChatChan,WomChatSignature+"|"+owner_name+"|"+"I'm ready!");
        revokeRLV();
        debug(1,"Free memory: "+(string)llGetFreeMemory());
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
                    mySay("I'm connected to charger module!");
                    state bodydisabled;
                }
            } else processRLV(_id,_msg);
        } else if (_chan == GynoidRChan) {
            debug(3,"RC received: "+_msg);
/*            list l = llParseString2List(_msg,[" "],[]);
            if (llGetListLength(l)<1) {
                debug(2,"parsed command list is empty");
                return;
            }
            if (llList2Key(l,1) != owner) return;*/
            string tmp = disasmcmd(_msg);
            debug(3,"parsing command");
            if (tmp=="") return;
            else if (tmp == "RCTOY") {
                followTo = llGetOwnerKey(_id);
                state rctoy;
            } else if (tmp == "DOLL") {
                followTo = llGetOwnerKey(_id);
                state doll;
            } else if (tmp == "PAUSE") {
                disableReason = 3;
                state bodydisabled;
            } else if (tmp == "REBOOT") {
                mySay("I'm going to reboot!");
                llWhisper(GynoidIChan,"RST! ");
                llResetScript();
            } else if (tmp == "SHUTDWN") {
                disableReason = 2;
                state bodydisabled;
            } else if (tmp == "DEBUG") {
                idebug = circle(idebug,4);
                mySay("Brain debugging level is "+(string)idebug);
            }
        }
    }
    
    timer()
    {
        if (curBat < 1) {
            disableReason = 1;
            state bodydisabled;
        } else if (curBat < pData_lowbat) {
            lowbat_state++;
            if (lowbat_state % 10) {
                mySay("I need to recharge!");
                llSensor(pData_Charger,NULL_KEY,(PASSIVE | ACTIVE),30.0,PI);
            }
        }
    }
    
    sensor(integer p)
    {
        //lowbat_state = 2;
        followTo = llDetectedKey(0);
        mySay("I found the charger!");
        state doll;
    }
    
    no_sensor()
    {
        //lowbat_state = 9;
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
            mySay(hello+" is detached!");
            state default;
        } else revokeRLV();
    }
    
    touch_start(integer p)
    {
        //if (llDetectedKey(0) == llGetOwner()) 
        llResetScript();
    }
}

// ****************************************************************************************************************

state rctoy
{
    // RC-controlled toy state, accepts extended RC commands
    state_entry()
    {
        debug(1,"!rctoy!");
        llTakeControls(0,FALSE,FALSE);
        cIC = llListen(GynoidIChan,"","","");
        cRC = llListen(GynoidRChan,"","","");
        mySay("RC mode ON");
        llSetTimerEvent(1.0);
        llResetTime();
        if (flgRLVa) llOwnerSay("@unsit=force");
        llWhisper(GynoidIChan,cyberVaginaPrefix+"|UPD");
        llRegionSay(WomIntChatChan,WomChatSignature+"|"+owner_name+"|"+"I'm radio controlled doll now ;)");
    }
    
    listen(integer _chan, string _name, key _id, string _msg)
    {
        integer i;
        if (_chan == GynoidIChan) {
            debug(3,"IC received: "+_msg);
            if ((_name == battery) && (llGetOwnerKey(_id)==owner)) {
                curBat = (integer)_msg;
                return;
            } else processRLV(_id,_msg);
        } else if (_chan == GynoidRChan) {
            debug(3,"RC received: "+_msg);
            string tmp = disasmcmd(_msg);
            if (tmp=="") return;
            else if (tmp == "RCTOY") {
                mySay("RC mode OFF");
                state poweronstd;
            } else if (tmp == "LEFT") {
                generateTarget(3);
            } else if (tmp == "RIGHT") {
                generateTarget(4);
            } else if (tmp == "FORWARD") {
                generateTarget(1);
            } else if (tmp == "BACKWARD") {
                generateTarget(2);
            } else if (tmp == "SEXDANCE") {
                i = (integer)llFrand((float)llGetListLength(pData_SexDynamic));
                nextDance = llList2String(pData_SexDynamic,i);
                debug(2,"SexDanceDynamic: "+(string)i+" ["+nextDance+"]");
                disableReason = 10;
                state bodydisabled;
            }
        }
    }
    
    timer()
    {
        llStopMoveToTarget();
    }
    
    state_exit()
    {
        debug(1,"RC mode off");
        llStopMoveToTarget();
        llListenRemove(cIC);
        llListenRemove(cRC);
    }

    touch_start(integer p)
    {
        //if (llDetectedKey(0) == llGetOwner()) 
        llResetScript();
    }

    attach(key id)
    {
        if (id==NULL_KEY) {
            // detached
            mySay(hello+" is detached!");
            state default;
        } else revokeRLV();
    }
}

// ****************************************************************************************************************

state doll
{
    // follower doll state, accepts only basic RC commands, following any avi/obj
    state_entry()
    {
        debug(1,"!doll!");
        llTakeControls(0,FALSE,FALSE);
        cIC = llListen(GynoidIChan,"","","");
        cRC = llListen(GynoidRChan,"","","");
        if (followTo == NULL_KEY) {
            llOwnerSay("Doll state switched without target UUID!");
            state poweronstd;
            return;
        }
        followTarg = 0;
        mySay("Doll mode ON");
        llSetTimerEvent(1.5);
        llResetTime();
        if (flgRLVa) llOwnerSay("@unsit=force");
        llWhisper(GynoidIChan,cyberVaginaPrefix+"|UPD");
        llRegionSay(WomIntChatChan,WomChatSignature+"|"+owner_name+"|"+"I'm a doll!");
    }
    
    timer()
    {
        if (followTarg) return;
        list l = llGetObjectDetails(followTo,[OBJECT_POS]);
        if (llGetListLength(l)<1) {
            llOwnerSay("We've lost our mistress!");
            state poweronstd;
            return;
        }
        vector tps = llList2Vector(l,0);
        float dist = llVecDist(tps,llGetPos());
        if (dist>1) {
            followTarg = llTarget(tps,1.0);
            if (dist > follow_limit) {
                tps = llGetPos() + follow_limit * llVecNorm( tps - llGetPos() ) ; 
            }
            llMoveToTarget(tps,1.0);
        }
    }
    
    at_target(integer tnum, vector tpos, vector ourpos) {
        llTargetRemove(tnum);
        llStopMoveToTarget();
        followTarg = 0;
        llResetTime();
        list l = llGetObjectDetails(followTo,[OBJECT_CREATOR]);
        if (followTo == llList2Key(l,0)) state poweronstd;
    }
    
    listen(integer _chan, string _name, key _id, string _msg)
    {
        if (_chan == GynoidIChan) {
            debug(3,"IC received: "+_msg);
            if ((_name == battery) && (llGetOwnerKey(_id)==owner)) {
                curBat = (integer)_msg;
                return;
            } else processRLV(_id,_msg);
        } else if (_chan == GynoidRChan) {
            debug(3,"RC received: "+_msg);
            string tmp = disasmcmd(_msg);
            if (tmp=="") return;
            else if (tmp == "DOLL") {
                debug(3,"transition out of doll-follower state");
                state poweronstd;
            }
        }
    }
    
    state_exit()
    {
//        debug(2,"leaving doll state");
        mySay("Doll mode OFF");
        llStopMoveToTarget();
        llListenRemove(cIC);
        llListenRemove(cRC);
        if (followTarg) llTargetRemove(followTarg);
    }

    touch_start(integer p)
    {
        //if (llDetectedKey(0) == llGetOwner()) 
        llResetScript();
    }
    
    attach(key id)
    {
        if (id==NULL_KEY) {
            // detached
            mySay(hello+" is detached!");
            state default;
        } else revokeRLV();
    }
}

// ****************************************************************************************************************

state bodydisabled
{
    // RC and body controls disabled, animations overrided
    state_entry()
    {
        debug(1,"!bodydisabled!");
        debug(1,"Reason = "+(string)disableReason);
        cIC = 0;
        cRC = 0;
        cAO = "";
        if (disableReason == 1) { // out-of-energy
            cAO = pAnim_EFail;
            mySay("Out of energy! Please replace my battery!");
        } else if (disableReason == 2) { // shutdown
            cAO = pAnim_POff;
            if (flgRLVa) llOwnerSay("@clear");
            mySay("I'm going to shutdown!");
        } else if (disableReason == 3) { // pause
            cAO = pAnim_Pause;
            mySay("-=PAUSED=-");
        } else if (disableReason == 4) { // recharge
            cAO = pAnim_RChrg;
        } else if (disableReason == 10) { // dancing
            cAO = nextDance;
        } else {
            llOwnerSay("Error: unexpected disable!");
            state poweronstd;
            return; // just in case
        }
        llWhisper(GynoidIChan,"HLT "); // stop battery discharge
        tmpKey = myGetInventoryKey(cAO);
        if (tmpKey==NULL_KEY) {
            llOwnerSay("Error: animation "+cAO+" not found in inventory!");
            state poweronstd;
            return; // just in case
        }
        cIC = llListen(GynoidIChan,"","","");
        cRC = llListen(GynoidRChan,"","","");
        llTakeControls(0,FALSE,FALSE);
        llStartAnimation(cAO);
        tmpCount = 0;
        // TODO: add some restrained actions
        llRegionSay(WomIntChatChan,WomChatSignature+"|"+owner_name+"|"+"My work is interrupted!");
        llSetTimerEvent(1.0);
        llResetTime();
    }
    
    listen(integer _chan, string _name, key _id, string _msg)
    {
        if (_chan == GynoidIChan) {
            debug(3,"DSTATE: IC received: "+_msg);
            if ((_name == battery) && (llGetOwnerKey(_id)==owner) && (disableReason != 4)) {
                curBat = (integer)_msg;
                return;
            }
            if ((disableReason == 4) && (_name == pData_Charger) && (disasmcmd(_msg) == "CHRG-detach")) {
                // charger disconnected
                mySay("I'm disconnected from charger module!");
                state poweronstd;
            }
            processRLV(_id,_msg);
        } else if (_chan == GynoidRChan) {
            debug(3,"DSTATE: RC received: "+_msg);
            string tmp = disasmcmd(_msg);
            if (tmp=="") return;
            else if ((tmp == "PAUSE") && (disableReason == 3)) {
                llOwnerSay("We're unpaused!");
                mySay("-=OPERATE=-");
                state poweronstd;
            } else if ((tmp == "SEXDANCE") && (disableReason == 10)) {
                llOwnerSay("End of dance.");
                state rctoy;
            } else if (tmp == "REBOOT") {
                mySay("I'm going to reboot!");
                llResetScript();
            }
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
        } else if (disableReason == 4) { // battery charging code
            tmpCount++;
            i = (integer)(pBattery * pCharge * 60);
            n = (integer)(tmpCount * pBattery / i);
//            n = curBat + ((integer)(pBattery/i));
            if (n > pBattery) n = pBattery;
            curBat = n;
            debug(2,"Power calc has given result "+(string)n+" after "+(string)tmpCount+" sec.");
            llWhisper(GynoidIChan,"PWR "+(string)n);
        }
        // update and reset vagina's internal counters
        llWhisper(GynoidIChan,cyberVaginaPrefix+"|UPD");
        // reset
        llResetTime();
    }
    
    state_exit()
    {
        debug(2,"leaving disabled state");
        if (cIC) llListenRemove(cIC);
        if (cRC) llListenRemove(cRC);
        if (tmpKey) {
            llStopAnimation(cAO);
            llStopAnimation(tmpKey);
        }
        llWhisper(GynoidIChan,cyberVaginaPrefix+"|FRESET");
        llWhisper(GynoidIChan,"RUN "); // run battery
    }
    
    attach(key id)
    {
        if (id==NULL_KEY) {
            // detached
            mySay(hello+" is detached!");
            state default;
        } else if (disableReason == 2) {
            // attached while shutted down
            cIC = 0;
            cRC = 0;
            tmpKey = NULL_KEY;
            state default;
        }
    }

    touch_start(integer p)
    {
        //if (llDetectedKey(0) == llGetOwner()) 
        llResetScript();
    }
}

// ****************************************************************************************************************

state powerseq
{
    // power-up sequence
    state_entry()
    {
        debug(1,"!powerseq!");
        llTakeControls(0,FALSE,FALSE);
        mySay("Starting power-up sequence!");
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

    touch_start(integer p)
    {
        llResetScript();
    }
    
    attach(key id)
    {
        if (id==NULL_KEY) state default;
    }
}

state findbattery
{
    // controller tries to find gynoid's battery pack and vagina
    state_entry()
    {
        cIC = llListen(GynoidIChan,"","","");
        cVC = llListen(CyberVaginaChannel,"","","");
        cRC = llListen(llAbs(GynoidIChan),"",owner,"");
        tmpCount = 0;
        llTakeControls(0,FALSE,FALSE);
        llWhisper(GynoidIChan,"RST! "); //reset the battery! ;)
        mySay("Checking battery...");
        //query for cyber vagina
        flgVaginaPresent = 0;
        llWhisper(GynoidIChan,cyberVaginaPrefix+"|UPD");
        //query for RLV
        flgRLVa = 0;
        llOwnerSay("@versionnew="+(string)llAbs(GynoidIChan));
        RLVstrictions = [];
        llSetTimerEvent(24);
        llResetTime();
    }
    
    listen(integer _chan, string _name, key _id, string _msg)
    {
        if (_chan == llAbs(GynoidIChan)) {
            debug(1,"RLV answer: "+_msg);
            if (llToUpper(llGetSubString(_msg,0,llStringLength(RLVaPrefix)-1)) == llToUpper(RLVaPrefix)) {
                flgRLVa = 1;
                llOwnerSay("@clear,detach=n");
                RLVstrictions = ["detach=n"];
                mySay("RLV compatible viewer found!");
            }
            return;
        } else
            if (llGetOwnerKey(_id) != owner) return;
        if (_chan == GynoidIChan) {
            if (_name == battery) {
                tmpCount++;
                curBat = (integer)_msg;
            } else
                processRLV(_id,_msg);
        } else if ((_chan == CyberVaginaChannel) && (flgVaginaPresent == 0)) {
            flgVaginaPresent = 1;
            mySay("CyberVagina found!");
        }
    }
    
    timer()
    {
        if (tmpCount < 2) {
            mySay("Battery not installed or broken!");
            tmpCount = 0;
        } else {
            mySay("Power-up sequence complete. Brain activated!");
            llWhisper(GynoidIChan,cyberVaginaPrefix+"|FRESET");
            integer n = (integer)(pBattery*pBatInit);
            if (curBat > n) n = curBat;
            llWhisper(GynoidIChan,"PWR "+(string)n); // init battery
            state poweronstd;
        }
    }
    
    state_exit()
    {
        debug(2,"leaving find bat state");
        llListenRemove(cRC); // RLV
        llListenRemove(cVC); // CyberVag
        llListenRemove(cIC); // CPU int chan
    }
    
    attach(key id)
    {
        if (id==NULL_KEY) state default;
    }

    touch_start(integer p)
    {
        llResetScript();
    }
}

// ****************************************************************************************************************

state dummy
{
    state_entry()
    {
        llOwnerSay("Dummy loop initiated!");
    }
    touch_start(integer p)
    {
        llResetScript();
    }
    attach(key id)
    {
        llResetScript();
    }
}

