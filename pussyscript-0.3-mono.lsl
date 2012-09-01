// MyPussy Main Script
// Compatible with Eliz's GynoidBrain
//
// (C) Elizabeth Walpanheim, 2011-2012

string version = "ver 0.3 beta rev. 121";

// ***********************************

float Delta = 0.3;

// *** DO NOT CHANGE THIS ***
list holes_x = [0.6, 0.5, 0.6];
list holes_y = [0.4, 0.25, 0.35, 0.15, 0.4, 0.25];
list hole_cuts = [<0.0,1.0,0.0>, <0.0,1.0,0.0>, <0.05,0.950,0.0>];
float holes_delta = 0.03;
// *** DO NOT CHANGE THIS ***

integer GynoidIChan = -257776;
integer GynoidRChan = -257770; // remote control channel
integer CyberVaginaChannel = -76616769;

integer ticks_max = 1000;
integer critical_sense = 33;
integer minutes_to_hurt = 25;
integer orgazm_length = 20;
integer close_delay = 31;
float dist_near = 2.1;
float dist_lolimit = 0.31;

key owner; // speed variable to remove iterative llGetOwner() calls
integer n_prims;
vector st_color;
integer stat;
integer ticks;
integer sense;
integer vsf;
list cur_holes = [0,0,0];
integer c_hole_s;
integer c_minutes;
integer c_touches;
integer c_last_charge;
list friends;
string s_last_sim;
integer f_cycle;
integer f_rc;
integer f_perm;
integer f_orgazzm;

// *****************************************

set_led_state(string name, integer on)
{
    integer i;
    for (i=1; i<=n_prims; i++)
        if (llGetLinkName(i) == name) {
            llSetLinkPrimitiveParamsFast(i,[PRIM_GLOW,ALL_SIDES,(float)on]);
            return;
        }
}

set_hole_size(integer no, float y_hole)
{
    integer i;
    string name;
    list tmp = [PRIM_TYPE,PRIM_TYPE_TORUS,0];
    if (no==0) name = "inner";
    else if (no==1) name = "middle";
    else if (no==2) name = "outer";
    else return;
    tmp += [llList2Vector(hole_cuts,no),0,ZERO_VECTOR];
    vector v = < (llList2Float(holes_x,no)), y_hole, 0.0 >;
    tmp += [v,ZERO_VECTOR,<0,1,0>,ZERO_VECTOR,0,0,0];
    for (i=1; i<=n_prims; i++)
        if (llGetLinkName(i) == name) {
            llSetLinkPrimitiveParamsFast(i,tmp);
            return;
        }
}

integer hole_dyn(integer no)
{
    float c = llList2Float(cur_holes,no);
    float max = llList2Float(holes_y,no*2);
    float min = llList2Float(holes_y,no*2+1);
    integer flag = 0;
    if (c>max) {
        c = max;
        c_hole_s = -1;
        flag = 1;
    } else if (c<min) {
        c = min;
        c_hole_s = 1;
        flag = 1;
    }
    c += (c_hole_s * holes_delta);
    list r = [c];
    cur_holes = llListReplaceList(cur_holes,r,no,no);
    set_hole_size(no,c);
    return flag;
}

full_state(integer A)
{
    integer i;
    for (i=0; i<3; i++)
        set_hole_size(i,llList2Float(holes_y,i*2+A));
}

dyn_random(integer mx)
{
    integer x = llFloor(llFrand(mx));
    if ((x<0)||(x>2)) return;
    float max = llList2Float(holes_y,x*2);
    float min = llList2Float(holes_y,x*2+1);
    float v = llFrand(max-min)+min;
//    llOwnerSay("x = "+(string)x+"\nv = "+(string)v);
    set_hole_size(x,v);
}

integer permId(key id)
{
    if (id == owner) return 1;
    else if (llGetOwnerKey(id) == owner) return 1;
    else {
        integer i;
        for (i=0; i<llGetListLength(friends); i++)
            if (llList2Key(friends,i) == id) return 1;
    }
    return 0;
}

setNewColor(vector ncol)
{
    integer i;
    list l;
    for (i=0; i<n_prims; i++) {
        l = llGetLinkPrimitiveParams(i,[PRIM_COLOR,1]);
        if (llList2Vector(l,0) == st_color)
            llSetLinkPrimitiveParams(i,[PRIM_COLOR,ALL_SIDES,ncol,llList2Float(l,1)]);
    }
    st_color = ncol;
}

rcontrols(integer flg)
{
    if (f_perm == 0) return;
    llTakeControls(0,FALSE,llAbs(1-flg));
    string s = "HUD ";
    if (flg > 0) s += "begin";
    else s += "end";
    llWhisper(CyberVaginaChannel,s+" lock");
    llOwnerSay("dbg: rcontrols("+(string)flg+")\ns="+s);
}

power(integer on)
{
    if (on) {
        stat = 1;
        s_last_sim = "";
        llSetTimerEvent(Delta);
        llOwnerSay("Activated");
    } else {
        stat = 0;
        rcontrols(0);
        llSetTimerEvent(60);
        llOwnerSay("I was acessed "+(string)c_touches+" times during last session!");
        llOwnerSay("Stand by");
    }
    llMessageLinked(LINK_ALL_OTHERS,0,"reset",NULL_KEY);
    llWhisper(CyberVaginaChannel,"HUD reset");
    full_state(0); // close vagina
    llResetTime();
    set_led_state("powerled",on); // update power led
    set_led_state("powerled2",on); // update power led
    set_led_state("haltled",llAbs(1-on));
    set_led_state("senseled",0);
    ticks = 0;
    c_minutes = 0;
    c_touches = 0;
    c_last_charge = -1;
    friends = [];
    sense = 0;
    vsf = 0;
    f_cycle = 0;
    f_rc = 0;
    f_orgazzm = 0;
}

friendList(key id)
{
    if (id == NULL_KEY) return;
    integer i;
    integer f = 0;
    for (i=0; i<llGetListLength(friends); i++) {
        if (llList2Key(friends,i) == id) {
            i = llGetListLength(friends);
            f = 1;
        }
    }
    if (f == 0) {
        string nm = llKey2Name(id);
        if (nm == "") return;
        friends += [id];
        llOwnerSay("There are new friend: "+nm);
    }
}

makeHoney(key id)
{
    integer i;
    for (i=0; i<llGetListLength(friends); i++)
        if (llList2Key(friends,i) == id) {
            llWhisper(CyberVaginaChannel,"RESP "+(string)id);
            vector v = llList2Vector(llGetObjectDetails(id,[OBJECT_POS]),0);
            vector m = llGetPos();
            if (llVecDist(v,m) < dist_near) {
                //llOwnerSay("[dbg] so near!");
                llTarget(v,0.2);
                //v = m + 20.0 * llVecNorm(v-m) ; 
                llMoveToTarget(v,1.0);
            }
            return;
        }
}

myHoney()
{
    if ((vsf<30) || (vsf>43)) vsf = 30;
    ticks = 0;
    sense++;
    if (c_last_charge >= 0) {
        c_last_charge++;
        //llOwnerSay("New gynoid battery charge is "+(string)c_last_charge);
        llWhisper(GynoidIChan,"PWR "+(string)c_last_charge);
    }
    if (sense > 3) llWhisper(CyberVaginaChannel,"HUD honey");
}

orgazzm(integer f)
{
    if (f > 0) {
        f_orgazzm = 1;
        ticks = 0;
        rcontrols(1);
        set_led_state("powerled",0);
        set_led_state("powerled2",1);
        llWhisper(CyberVaginaChannel,"HUD begin orgazm");
        llMessageLinked(LINK_ALL_OTHERS,1,"cum",NULL_KEY);
    } else {
        f_orgazzm = 0;
        f_cycle = 0;
        sense = 2;
        rcontrols(0);
        set_led_state("powerled",1);
        set_led_state("powerled2",0);
        set_led_state("haltled",0);
        vsf = 40; // close hole
        llWhisper(CyberVaginaChannel,"HUD end orgazm");
        llMessageLinked(LINK_ALL_OTHERS,0,"reset",NULL_KEY);
    }
    ticks = 0;
}

fck_touch()
{
    if (stat == 0) {
        power(1);
        return;
    }
    if (sense >= critical_sense) orgazzm(1);
    else {
        if (sense == 0) {
            llWhisper(CyberVaginaChannel,"HUD begin sense");
            if (llDetectedKey(0) != owner)
                // send IM only for one due to a big time of IM generation
                llInstantMessage(llDetectedKey(0),"You've touched me right now!\nUhhmmmm......");
        }
        myHoney();
        set_led_state("senseled",1);
    }
}

emrg_hide(integer al)
{
    if (al) power(0);
    llSetLinkAlpha(LINK_SET,(float)llAbs(al-1),ALL_SIDES);
}

default
{
    state_entry()
    {
        owner = llGetOwner();
        n_prims = llGetNumberOfPrims();
        llOwnerSay("Cyber-Vagina "+version+"\n(C) Elizabeth Walpanheim, 2011-2012");
        llOwnerSay("Start init...");
        llListen(0,"","","");
        llListen(8,"","","");
        llListen(GynoidIChan,"","","");
        llListen(CyberVaginaChannel,"","","");
        f_perm = 0;
        llOwnerSay("Initialized.");
        llRequestPermissions(owner,PERMISSION_TRIGGER_ANIMATION | PERMISSION_TAKE_CONTROLS);
        power(1);
        st_color = llGetColor(1);
    }
    
    attach(key id)
    {
        if (id != NULL_KEY) llResetScript();
        else llOwnerSay("Detaching...");
    }
    
    timer()
    {
        if (stat == 0) {
            c_minutes++;
            if (c_minutes >= minutes_to_hurt) {
                llOwnerSay("I'm hurt! Somebody forget that I'm here for "+(string)c_minutes+" minutes!!!");
                rcontrols((c_minutes - minutes_to_hurt) % 2);
                if ((c_minutes > (minutes_to_hurt * 2)) && (llFrand(1.0) < 0.3)) {
                    llOwnerSay("Ooops...");
                    power(1);
                }
            }
            return;
        }
        // ***
        ticks++;
        if (f_orgazzm) {
            set_led_state("haltled",ticks%2);
            if (ticks > orgazm_length) orgazzm(0);
        } else {
            set_led_state("powerled2",ticks%2);
        }
        if ((ticks > ticks_max) && (f_rc == 0)) {
            power(0);
            return;
        }
        if (f_rc) set_led_state("haltled",ticks%3);
        // ***
        if ((ticks == close_delay) && (vsf > 30) && (vsf < 40)) vsf = 40;
        // ***
        if ((ticks % 10 == 0) && (llGetRegionName() != s_last_sim)) {
            //llOwnerSay("dbg: sim changed");
            s_last_sim = llGetRegionName();
            friends = [];
        }
        if ((ticks % 10) == 0) llSay(CyberVaginaChannel,"PING");
        // ***
        if (f_orgazzm) {
            // orgazm dynamic moves
            set_hole_size(0,llList2Float(holes_y,ticks%2));
            set_hole_size(1,llList2Float(holes_y,(ticks%2)+2));
        } else {
            // opening
            if ((vsf > 29) && (vsf < 33)) {
                c_hole_s = -1;
                if (hole_dyn(llAbs(vsf-32))) vsf++;
            } else if (vsf == 33) {
                ticks = 1;
                full_state(1);
                if (f_cycle) vsf = 40;
                else vsf = 35;
            } else if (vsf == 35) dyn_random(2);
            // closing
            else if ((vsf > 39) && (vsf < 43)) {
                c_hole_s = 1;
                if (hole_dyn(vsf-40)) vsf++;
            } else if (vsf == 43) {
                full_state(0);
                if (f_cycle) vsf = 30;
                else {
                    vsf = 45;
                    if (sense > 0) {
                        sense = 0;
                        llWhisper(CyberVaginaChannel,"HUD end sense");
                        set_led_state("senseled",0);
                        ticks = 0;
                    }
                }
            }
        }
        // ***
        llResetTime();
    }
    
    run_time_permissions(integer perm)
    {
        if ((perm & PERMISSION_TAKE_CONTROLS) && (perm & PERMISSION_TRIGGER_ANIMATION)) {
            llOwnerSay("Permissions given.");
            f_perm = 1;
        }
    }
    
    touch_start(integer tn)
    {
        integer i;
        for (i=0; i<tn; i++) {
            llOwnerSay("I've touched by "+llDetectedName(i));
            makeHoney(llDetectedKey(i));
        }
        c_touches += tn;
        fck_touch();
    }
    
    at_target(integer tnum, vector tpos, vector ourpos) {
        llTargetRemove(tnum);
        llStopMoveToTarget();
        llResetTime();
    }
    
    listen(integer ch, string nm, key id, string msg)
    {
        if (id == llGetKey()) return;
        if ((ch == CyberVaginaChannel) && (stat > 0)) {
            if (msg == "PING") {
                key id_own = llGetOwnerKey(id);
                friendList(id_own);
                float adist = llVecDist(llList2Vector(llGetObjectDetails(id_own,[OBJECT_POS]),0),llGetPos());
                if (adist < dist_near) {
                    //llOwnerSay("near()");
                    if (adist < dist_lolimit) {
                        fck_touch();
                        makeHoney(id_own);
                    } else if ((llFrand(1.0) < 0.45) && (sense < 2)) {
                        //llOwnerSay("My friend "+llKey2Name(id_own)+" is so near! ("+(string)adist+")");
                        myHoney();
                        set_led_state("senseled",1);
                    }
                }
            } else {
                list l = llParseString2List(msg,[" "],[]);
                string cmd = llList2String(l,0);
                //llOwnerSay("command "+cmd+" has been received");
                if ((cmd == "RESP") && (llList2Key(l,1) == owner)) myHoney();
                else if ((cmd == "COLOR") && (llGetOwnerKey(id) == owner)) setNewColor((vector)llGetSubString(msg,6,-1));
            }
        } else if (permId(id) == 0) return;
        if ( (ch == 8) && ((id == owner) || (llGetOwnerKey(id) == owner)) ) {
            if (msg == "on") power(1);
            else if (msg == "off") power(0);
            else if (msg == "lock") rcontrols(1);
            else if (msg == "unlock") rcontrols(0);
            else if (msg == "pee") llMessageLinked(LINK_ALL_OTHERS,1,"pee",NULL_KEY);
            else if (msg == "cum") llMessageLinked(LINK_ALL_OTHERS,1,"cum",NULL_KEY);
            else if (msg == "fire") llMessageLinked(LINK_ALL_OTHERS,1,"fire",NULL_KEY);
            else if (msg == "lreset") { llMessageLinked(LINK_ALL_OTHERS,0,"reset",NULL_KEY); llResetScript(); }
            else if (msg == "open") full_state(1);
            else if (msg == "close") full_state(0);
            else if (msg == "cycle") { f_cycle=1; vsf=30; }
            else if (msg == "hide") emrg_hide(1);
            else if (msg == "show") emrg_hide(0);
            else if (msg == "mem") llOwnerSay("Memory status: "+(string)llGetFreeMemory()+" bytes free.");
            else if (msg == "help") {
                llOwnerSay("Commands available:");
                llOwnerSay("on off lock unlock pee cum fire lreset open close cycle hide show mem");
            }
        } else if ((ch == GynoidIChan) && (llGetOwnerKey(id) == owner)) {
            c_last_charge = (integer)msg; // TODO: make this more stable and less ugly =)
        }
    }
}
