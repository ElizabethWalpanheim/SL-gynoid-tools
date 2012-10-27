string ver = "ver. 0.1 rev 6";
integer updChan = -10730;       // local updaters channel
integer GynoidRChan = -257770; // remote control channel
float flush_delay = 35.0; //sec
float controlDistance = 1.9; //m
integer dlgChan = -643201;
integer uploading = 0;
integer h_DlgLst;
list scripts;
list targets;
list found;

upload()
{
        integer i;
        key k;
        uploading = 1;
//        llWhisper(0,"request");
        llWhisper(updChan,"GYNUP uAvailable");
        llSleep(3.0);
//        llWhisper(0,"upload");
/*        for (i=0; i<llGetListLength(found); i++) {
            k = llList2Key(found,i);
            llRemoteLoadScriptPin(k,target_script,(1-updChan),1,1);
            llWhisper(0,"-->\t"+(string)k+" ["+llKey2Name(llGetOwnerKey(k))+"]");
        }*/
        //llSleep(3.0);
//        llWhisper(0,"hold");
        llWhisper(updChan,"GYNUP uSent");
//        llWhisper(0,"done!");
        uploading = 0;
}

default
{
    state_entry()
    {
        integer i;
        string we = llGetScriptName();
        string vs;
        llSay(0,"Gynoid Update Server "+ver);
        llWhisper(0,"Init...");
        found = [];
        scripts = [];
        targets = [];
        i = llGetInventoryNumber(INVENTORY_SCRIPT);
        while (i) {
            vs = llGetInventoryName(INVENTORY_SCRIPT,--i);
            if (vs != we) {
                llSetScriptState(vs,FALSE);
                scripts += [vs];
                llWhisper(0,"Script target registered: "+vs);
            }
        }
        llListen(updChan,"","","");
        llSetTimerEvent(flush_delay);
        llWhisper(0,"init done");
        llResetTime();
    }
    
    on_rez(integer p)
    {
        llResetScript();
    }
    
    listen(integer chan, string name, key id, string msg)
    {
        if (uploading) return;
        if (chan == dlgChan) {
            //llOwnerSay(msg);
            integer i;
            uploading = 1; // busy mode
            llListenRemove(h_DlgLst);
            if (msg == "Detected") {
                i = llGetListLength(found);
                if (i < 1) llWhisper(0,"Nothing detected so far");
                while (--i >= 0)
                    llWhisper(0,llKey2Name(llGetOwnerKey(llList2Key(found,i)))+": "+llList2String(targets,i*2)+" ("+llList2String(scripts,llList2Integer(targets,i*2+1))+")");
            } else if (msg == "Scripts") {
                //
            } else if (msg == "Burn") {
                //
            }
            uploading = 0;
            return;
        }
        list vl = llParseString2List(msg,["|"],[]);
        if (llList2String(vl,0) != "GYNOID ATTACHMENT PRESENT") return;
        integer n;
        if (llListFindList(found,[id]) < 0) {
            n = llListFindList(scripts,[llList2String(vl,1)]);
            if (n >= 0) {
                found += [id];
                targets += [name,n];
                //llWhisper(0,name+" added / "+llList2String(vl,1)+" #"+(string)n);
            }
        }
        llResetTime();
    }
    
    timer()
    {
        if (uploading) return;
        found = [];
        targets = [];
    }

    touch_start(integer total_number)
    {
        if (uploading) return;
        if (llVecDist(llDetectedPos(0),llGetPos()) > controlDistance) return;
        llDialog(llDetectedKey(0),"Gynoid Update Server Main Menu",["Detected","Scripts","Burn"],dlgChan);
        h_DlgLst = llListen(dlgChan,"",llDetectedKey(0),"");
    }
}

