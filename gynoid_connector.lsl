integer gynoidUniversalChannel = -75382110;
list names = ["COMPUTER","PC","LAPTOP","SERVER","CPU","MCU","CONNECTOR"];
float mindist = 3.7; //in SL distances appears smaller than it's physical equivalent in RL

integer GynoidIChan = -257776; // GynCPU internal channel
integer GynoidRChan = -257770; // GynCPU remote control channel
integer CyberVaginaChannel = -76616769;
//integer VaginaPubChannel = 8;
integer WomChatChan = -283751;
string WomSignature = "VGWCHT00021";

key owner;
integer h_Lst;
integer attempt;

string describe_chan(integer number)
{
    if (number == GynoidIChan) return ("BrainInternal");
    if (number == GynoidRChan) return ("BrainRemote");
    if (number == CyberVaginaChannel) return ("CyberVagina");
    if (number == WomChatChan) return ("WomanChat");
    return ("UNKNOWN");
}

init()
{
    llOwnerSay("Connector init()");
    owner = llGetOwner();
    llParticleSystem([]);
    if (h_Lst) {
        llListenRemove(h_Lst);
        h_Lst = 0;
    }
    llListen(GynoidIChan,"","","");
    llListen(GynoidRChan,"","","");
    llListen(CyberVaginaChannel,"","","");
    llListen(WomChatChan,"","","");
    attempt = -1;
}

connect(key id)
{
    llOwnerSay("Connecting...");
    // only particle flow implemented yet
    llListen(gynoidUniversalChannel,"","","");
}

try()
{
    attempt++;
    if (attempt == 0)
        llSensor("","",SCRIPTED,mindist,PI);
    else if (attempt == 1)
        llSensor("","",ACTIVE|PASSIVE,mindist,PI);
    else {
        llOwnerSay("No objects found in range :(");
        attempt = -1;
    }
}

default
{
    state_entry()
    {
        h_Lst = 0;
        init();
    }
    
    attach(key id)
    {
        if (id) init();
    }

    touch_start(integer total_number)
    {
        llOwnerSay("Touched by "+llDetectedName(0));
        if (llDetectedKey(0) == owner) try();
    }
    
    sensor(integer n)
    {
        list pass = [];
        list b;
        integer i;
        integer j;
        vector v = llGetPos();
        float min;
        float cur;
        llOwnerSay((string)n+" detected at all");
        while (n) {
            b = llParseString2List(llToUpper(llDetectedName(--n)),[],names);
            llOwnerSay("b: "+llDumpList2String(b,"|"));
            for (i=llGetListLength(names)-1; i>=0; i--) {
                j = llListFindList(b,[llList2String(names,i)]);
                if (j >= 0) {
                    //there can be more than one search pattern in one object's name
                    if (llListFindList(pass,[n]) < 0) pass += [n];
                    llOwnerSay("debug: "+llDetectedName(n)+" passed");
                }
            }
        }
        llOwnerSay(llDumpList2String(pass,", "));
        //double reverse in search directions gives us positive directed result :)
        n = llGetListLength(pass);
        if (n < 1) { // no objects passed test
            try();
            return;
        }
        min = mindist;
        j = -1;
        while (n) {
            i = llList2Integer(pass,--n);
            cur = llVecDist(llDetectedPos(i),v);
            llOwnerSay("debug: distance "+(string)cur);
            if (cur < min) {
                min = cur;
                j = i;
            }
        }
        if (j < 0) {
            try();
            return;
        }
        llOwnerSay("Found nearest connection point: "+llDetectedName(j));
        connect(llDetectedKey(j));
    }
    
    no_sensor()
    {
        try();
    }
    
    listen(integer chan, string name, key id, string msg)
    {
        if (chan == gynoidUniversalChannel) {
            //
        } else if (llGetOwnerKey(id) != owner) return;
        // universal dumper (main nerve cord data pipe)
        llSay(gynoidUniversalChannel,"PIPE|"+describe_chan(chan)+"|"+(string)id+"|"+msg);
    }
}

