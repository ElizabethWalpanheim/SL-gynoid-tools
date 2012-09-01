integer mdebug = 0;
integer revw = 42;

integer GynoidIChan = -257776;
integer CyberVaginaChannel = -76616769;
integer IntChatChan = -283751;
string WomSignature = "VGWCHT00021";

vector clr_black = <0.05, 0.05, 0.05>;
vector clr_honey = <0.5, 0.0, 0.5>;
vector clr_red = <0.9, 0.0, 0.0>;
vector clr_aqua = <0.0, 0.9, 0.9>;
vector clr_clear = <1, 1, 1>;
float mDelta = 0.21;
integer leds_qnty = 8;

//vector fullsize = <1.0, 2.0, 0.2>;
//vector minsize = <0.01, 0.01, 0.2>;
float a_hollow = 0.73;
float glow_power = 0.87;
integer flash_length = 11;
float maxalpha = 0.91;

integer f_cyc = 0;
integer flash;
key owner;
integer cnt;
vector color_delta;
float glow_delta;
float alpha_delta;
vector cur_color;
float cur_glow;
float cur_alpha;
integer busy;
list m_lst;
integer lst_upd_cyc;
integer list_update;
integer f_locked;

debug(string msg)
{
    if (mdebug) llOwnerSay("DEBUG: "+msg);
}

make_flash(vector color)
{
    cnt = 0;
    cur_color = color;
    color_delta = color / flash_length;
    debug("color delta is "+(string)color_delta);
    cur_glow = glow_power;
    cur_alpha = maxalpha;
    flash = 1;
    llResetTime();
}

mstate(integer p)
{
    float hlw = 0.95;
    float alp = 0.0;
    integer shp = PRIM_HOLE_SQUARE;
    if (p == 1) {
        hlw = a_hollow;
        shp = PRIM_HOLE_CIRCLE;
    } else if (p == 2) {
        hlw = 0.0;
        alp = maxalpha;
    } else f_locked = 0;
    debug("hollow := "+(string)hlw);
    llSetLinkPrimitiveParamsFast(1,[PRIM_TYPE,PRIM_TYPE_BOX,shp,<0,1,0>,hlw,ZERO_VECTOR,<1,1,1>,ZERO_VECTOR]);
    if (p != 1) llSetLinkPrimitiveParamsFast(1,[PRIM_COLOR,ALL_SIDES,clr_clear,alp]);
}

append(key id)
{
    if (id == llGetOwner()) return;
    integer i;
    integer n = llGetListLength(m_lst);
    integer f = 0;
    for (i=0; i<n; i++) {
        if (llList2Key(m_lst,i) == id) {
            f = 1;
            i = n;
        }
    }
    if (f) return;
    m_lst += [id];
    debug((string)id+" detected!");
}

womchat(string msg)
{
    llRegionSay(IntChatChan,WomSignature+"|"+llKey2Name(owner)+"|"+msg);
}

setled(integer n, vector c, float alpha)
{
    integer m = llGetNumberOfPrims();
    integer i;
    string vs;
    for (i=1; i<=m; i++) {
        vs = llGetLinkName(i);
        if (llGetSubString(vs,0,2) == "LED") {
            if ((integer)(llGetSubString(vs,3,-1)) == n) {
                llSetLinkPrimitiveParamsFast(i,[PRIM_COLOR,ALL_SIDES,c,alpha]);
                return;
            }
        }
    }
}

full_leds(vector color)
{
    integer i;
    for (i=0; i<leds_qnty; i++) setled(i,color,0.1);
}

default
{
    state_entry()
    {
        llListen(CyberVaginaChannel,"","","");
        llListen(GynoidIChan,"","","");
        owner = llGetOwner();
        glow_delta = glow_power / flash_length;
        debug("glowDelta="+(string)glow_delta);
        alpha_delta = maxalpha / flash_length;
        debug("alphaDelta="+(string)alpha_delta);
        mstate(0);
        flash = 0;
        busy = 0;
        lst_upd_cyc = 0;
        list_update = (integer)(1.0 / mDelta) * 10;
        debug("list update time = "+(string)list_update);
        m_lst = [];
        llMessageLinked(LINK_ALL_OTHERS,0,"reset",llGetKey());
        llOwnerSay("HUD Activated\nbuild "+(string)revw);
        womchat("I'm activated my HUD!");
        full_leds(<0,1,0>);
        llSetTimerEvent(mDelta);
        llResetTime();
    }
    
    attach(key k)
    {
        if (k) {
            womchat("I'm attached my HUD...");
            llResetScript();
        } else {
            womchat("I'm detached my HUD!");
        }
    }
    
    timer()
    {
        // ***
        if (flash) {
            if ((cnt > flash_length) && (f_cyc < 1)) {
                cur_color = clr_clear;
                cur_glow = 0.0;
                cur_alpha = 0.0;
                flash = 0;
                debug("-> end of flash *");
            } else {
                cur_glow -= glow_delta;
                cur_alpha -= alpha_delta;
                if (f_cyc < 1) {
                    cur_color += color_delta;
                    if (cur_glow < 0) cur_glow = 0;
                    if (cur_alpha < 0) cur_alpha = 0;
                } else {
                    cur_color = <(llFrand(1)),0,(llFrand(1))>;
                    if (cur_glow < 0.1) cur_glow = 0.1;
                    if (cur_alpha < 0.1) cur_alpha = 0.1;
                }
                cnt++;
            }
            llSetLinkPrimitiveParamsFast(1,[PRIM_GLOW,ALL_SIDES,cur_glow]);
            llSetLinkPrimitiveParamsFast(1,[PRIM_COLOR,ALL_SIDES,cur_color,cur_alpha]);
            full_leds(cur_color);
            llResetTime();
        }
        // ***
        lst_upd_cyc++;
        if (lst_upd_cyc >= list_update) {
            lst_upd_cyc = 0;
            integer n = llGetListLength(m_lst);
            debug("sending gynoids updates: "+(string)n);
            if (n > 0) {
                busy = 1;
                integer i;
                for (i=0; i<n; i++)
                    llMessageLinked(LINK_ALL_OTHERS,i+1,"SET",llList2Key(m_lst,i));
                m_lst = [];
            }
            full_leds(<0,1,0>);
            debug("Gynoids Radar list updated!");
            busy = 0;
            llResetTime();
        }
        // ***
        if (lst_upd_cyc % 2) {
            integer _vn = llFloor(llFrand((float)leds_qnty));
            if ((f_locked == 0) && (!flash)) setled(_vn,<0,1,0>,llFrand(1.0));
            else if (f_locked == 1) setled(_vn,<1,0,0>,llFrand(1.0));
            else if (f_locked == 2) setled(_vn,<1,0,1>,llFrand(1.0));
            llResetTime();
        }
    }
    
    listen(integer ch, string nm, key id, string msg)
    {
        if (ch == GynoidIChan) {
            if (busy == 0) append(llGetOwnerKey(id));
            return;
        }
        if ((id != owner) && (llGetOwnerKey(id) != owner)) return;
        list l = llParseString2List(msg,[" "],[]);
        if ((llGetListLength(l) < 2) || (llList2String(l,0) != "HUD")) return;
        debug((string)l);
        string a = llList2String(l,1);
        if (a == "reset") {
            mstate(0);
            llMessageLinked(LINK_ALL_OTHERS,0,"reset",llGetKey());
        } else if (a == "honey") {
            mstate(1);
            make_flash(clr_honey);
        } else if ((a == "begin") || (a == "end")) {
            string b = llList2String(l,2);
            if (b == "lock") {
                if (a == "end") mstate(0);
                else {
                    mstate(2);
                    make_flash(clr_black);
                    f_locked = 1;
                }
            } else if (b == "sense") {
                if (a == "end") mstate(0);
                else {
                    mstate(1);
                    make_flash(clr_honey);
                }
            } else if (b == "orgazm") {
                if (a == "end") {
                    mstate(1);
                    f_cyc = 0;
                    make_flash(clr_aqua);
                    f_locked = 0;
                } else {
                    mstate(2);
                    f_cyc = 1;
                    make_flash(clr_red);
                    f_locked = 2;
                }
            }
        }
    }
    
    link_message(integer sndr, integer num, string str, key id)
    {
        if (str == "reset") llResetScript();
    }
    
/*    on_rez(integer p)
    {
        llMessageLinked(LINK_ALL_OTHERS,0,"reset",llGetKey());
        state dummy;
    }
}

state dummy
{
    state_entry()
    {
        llOwnerSay("Dummy state\nPlease attach me!!!");
    }
    attach(key id)
    {
        llResetScript();
    }*/
}
