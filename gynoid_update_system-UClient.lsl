//GPLv3

string target_script = "myVagina";
integer updChan = -10730;         // update channel
integer GynoidRChan = -257770; // remote control channel

default
{
    state_entry()
    {
        llSetRemoteScriptAccessPin(1-updChan);
        llListen(updChan,"","","");
        llSetTimerEvent(5.0);
        llOwnerSay("GYNOID UPDATE: "+(string)(llGetFreeMemory()/1024)+" Kbytes free.");
    }

    listen(integer chan, string name, key id, string msg)
    {
        list vl = llParseString2List(msg,[" "],[]);
        if (llList2String(vl,0) != "GYNUP") return;
        string cmd = llList2String(vl,1);
        if (cmd == "uAvailable") {
            llWhisper(GynoidRChan,"SHUTDWN "+(string)llGetOwner());
            llSleep(1.2);
            llSetScriptState(target_script,FALSE);
            llSleep(0.5);
            llRemoveInventory(target_script);
            llOwnerSay("GYNOID UPDATE: ready");
        } else if (cmd == "uSent") {
            llSetScriptState(target_script,TRUE);
            llResetOtherScript(target_script);
            llOwnerSay("GYNOID UPDATE: reset");
        }
    }
    
    timer()
    {
        llWhisper(updChan,"GYNOID ATTACHMENT PRESENT|"+target_script);
    }
}

