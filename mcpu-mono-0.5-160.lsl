integer digits = 14;
float frequency = 2.5;
integer drop_for_all = 0;
integer m_debug = 1;
string ver = "0.5 rev 160";
integer mem_local_top = 256; // 2^8 words (optimal value for main CPU object)
integer memory_channel = -423531;
integer cache_size = 8;

list memory;
list cache;
integer mem_top;
integer w_flag;
integer IP;
integer summ;
integer a_peak;
integer b_peak;
integer dbg_last_test;
integer no_reset = 0;
integer busy;
key owner;
string prog_cardname;
key kQuery;
integer notecardline;
integer prog_heap;
list prog_translate;
list temp_code;
integer prog_datapoint;
integer virtIP;
integer RAM_FLG;
integer RAM_adr;
integer RAM_rg;
integer one_shot;

debug(string msg)
{
    if (m_debug == 1) llOwnerSay("DEBUG: "+msg);
    else if (m_debug == 2) llWhisper(0,"DEBUG: "+msg);
}

integer circle(integer cval, integer max)
{
    integer r = cval + 1;
    if (r > max) r = 0;
    return r;
}

set_led_state(string name, integer on)
{
    integer i;
    for (i=1; i<=llGetNumberOfPrims(); i++)
        if (llGetLinkName(i) == name) {
            llSetLinkPrimitiveParamsFast(i,[PRIM_GLOW,ALL_SIDES,(float)on]);
            return;
        }
}

update_summator_leds()
{
    integer i;
    integer j;
    integer k = summ;
    for (i=digits-1; i>=0; i--) {
        j = (integer)llPow(2,i);
        if (k >= j) {
            set_led_state("ledbit"+(string)i,1);
            k -= j;
        } else {
            set_led_state("ledbit"+(string)i,0);
        }
    }
}

integer sign_bit(integer arg)
{
    integer a = arg;
    if (arg < 0) {
        a = -arg + b_peak;
        if (a > a_peak-1) a -= a_peak;
    }
    return a;
}

summator(integer arg)
{
    // this code is kindly ugly, but it gives comprehensive overview of MNC ;)
    integer a = sign_bit(arg);
    integer s = summ;
    integer r = 0;
    //convert both summ and arg to MNC
    if (summ >= b_peak) s = (a_peak-1) - (summ % b_peak);
    if (a >= b_peak) a = (a_peak-1) - (a % b_peak);
    //sum
    summ = s + a;
    //deconv
    if (summ >= a_peak) summ -= (a_peak-1);
    if (summ >= b_peak) summ = llAbs(summ-(a_peak-1)) + b_peak;
}

init_cache()
{
    integer i;
    cache = [];
    for (i=0; i<cache_size; i++) cache += [0,0,0]; // Address, Data(Value), Hits
    debug("CacheRESET");
}

poweron(integer flg)
{
    w_flag = flg;
    if (flg) {
        llSetTimerEvent(1/frequency);
        busy = 0;
        //init_cache();
    } else
        llSetTimerEvent(0);
    RAM_FLG = 0;
    RAM_rg = -1;
    RAM_adr = -1;
    llResetTime();
    set_led_state("powerled",flg);
}

integer find_notecard(string name)
{
    integer n = llGetInventoryNumber(INVENTORY_NOTECARD);
    while(n)
        if (llGetInventoryName(INVENTORY_NOTECARD,--n) == name)
            return 1;
    return 0;
}

nextnoteline()
{
    notecardline++;
    kQuery = llGetNotecardLine(prog_cardname,notecardline);
    debug("reading line "+(string)notecardline);
}

integer translate_lookup(string name)
{
    integer i;
    for (i=0; i<llGetListLength(prog_translate); i+=2)
        if (llList2String(prog_translate,i) == name)
            return (llList2Integer(prog_translate,i+1));
    return -1; // hmmm
}

card_read_err_handler(string reason)
{
    llSay(0,reason);
    no_reset = 0;
}

rawcache()
{
    debug("RAW:\n"+llDumpList2String(cache,", "));
    debug("Actual size is "+(string)llGetListLength(cache));
}

cache_sync()
{
    integer i;
    integer n;
    for (i=2; i<(cache_size*3); i+=3) {
        n = llList2Integer(cache,i) - 1;
        if (n < -1) n = -1;
        if (n > a_peak) n = a_peak-1;
        cache = llListReplaceList(cache,[n],i,i);
    }
    rawcache();
}

cache_put(integer addr, integer data)
{
    integer i;
    integer v;
    integer min = a_peak;
    integer min_adr = -1;
    if (addr < 0) {
        debug("CacheTable PUT() fired with addr = '"+(string)addr+"' !!");
        return;
    }
    for (i=0; i<cache_size; i++) {
        v = llList2Integer(cache,i*3+2);
        if (llList2Integer(cache,i*3) == addr) {
            debug("CacheTable PUT() hit for $"+(string)addr);
            if (v < 2) v = 2;
            else v += 2;
            cache = llListReplaceList(cache,[addr,data,v],(i*3),(i*3+2));
            return;
        } else if (v < min) {
            min = v;
            min_adr = i;
        }
    }
    if (min_adr < 0) {
        llSay(0,"CacheTable error: all hits values are incredibly high!\nCache reset.");
        init_cache();
        min_adr = 0;
    }
    cache = llListReplaceList(cache,[addr,data,1],(min_adr*3),(min_adr*3+2));
    debug("CacheTable value $"+(string)addr+" ["+(string)data+"] placed to #"+(string)min_adr+"\nlast_min_hits = "+(string)min);
    //rawcache();
}

integer cache_get(integer addr)
{
    integer i;
    integer v = -1;
    integer h;
    for (i=0; i<cache_size; i++) {
        if (llList2Integer(cache,i*3) == addr) {
            v = llList2Integer(cache,i*3+1);
            h = llList2Integer(cache,i*3+2);
            if (h < 2) h = 2;
            else h += 2;
            cache = llListReplaceList(cache,[addr,v,h],(i*3),(i*3+2));
            debug("CacheTable hit: #"+(string)i+" -> $"+(string)addr);
            i = cache_size;
        }
    }
    //rawcache();
    return v;
}

change_memory_word(integer addr, integer data)
{
    if (addr < mem_local_top) {
        memory = llListReplaceList(memory,[data],addr,addr);
    } else {
        llSay(memory_channel,"PUT "+(string)addr+" "+(string)data);
        cache_put(addr,data);
    }
}

integer request_memory_word(integer addr)
{
    if ((RAM_FLG % 2 > 0) && (RAM_rg < 0)) return -1; // deadlock blocker (or maybe spawner) ;-}
    else if (RAM_adr == addr) return RAM_rg; // get out asynchronously received value
    // is addr in the internal RAM?
    if (addr < mem_local_top) return (llList2Integer(memory,addr));
    // ...or maybe in cache?
    integer av = cache_get(addr);
    if (av >= 0) return av;
    // if nothing helped, ask to external memory
    RAM_FLG = 1;
    RAM_adr = addr;
    RAM_rg = -1;
    llSay(memory_channel,"GET "+(string)addr);
    return -1;
}

default
{
    state_entry()
    {
        integer i;
        owner = llGetOwner();
        if (no_reset == 0) {
            llSay(0,"MCPU ver. "+ver+"\nPrepare...");
            memory = [];
            mem_top = (integer)llPow(2,(digits-3));
            if (mem_top > mem_local_top) {
                llSay(0,"MCPU configured to use asynchronous external RAM!\nOperation will be slow!");
                llSay(memory_channel,"FULLRESET");
                for (i=0; i<mem_local_top; i++) memory += [0];
            } else {
                for (i=0; i<mem_top; i++) memory += [0];
            }
            a_peak = (integer)llPow(2,digits);
            b_peak = (integer)llPow(2,(digits-1));
            init_cache();
            llSay(0,"L1+2 CacheTable of size "+(string)cache_size+" initialized!");
            one_shot = 0;
        }
        w_flag = 0;
        IP = 0;
        summ = 0;
        busy = 1;
        RAM_FLG = 0;
        update_summator_leds();
        llAllowInventoryDrop(drop_for_all);
        llListen(0,"","","");
        llListen(memory_channel,"","","");
        if (m_debug > 0) llListen(1,"","","");
        if (no_reset == 0)
            llSay(0,"Ready!\n"+(string)digits+" bits\n"+(string)frequency+" Hz speed\nHighest possible value is "+(string)a_peak+"\nMemory top at $"+(string)mem_top);
        no_reset = 1;
        prog_translate = [];
        temp_code = [];
        llOwnerSay((string)llGetFreeMemory()+" bytes free.");
    }
    
    timer()
    {
        if (busy) return;
        if (!w_flag) {
            poweron(0);
            llSay(0,"Halted.");
            return;
        }
        // get the command
        integer wcmd = request_memory_word(IP);
        if (wcmd < 0) return;
        // split it
        integer cmd = wcmd % 8;
        integer adr = (integer)(wcmd / 8);
        debug("\nIP = "+(string)IP+"\nsumm = "+(string)summ+"\ncmd = "+(string)cmd+"\narg = "+(string)adr);
        // get value by address
        integer adr_val;
        if ((cmd < 2) || (cmd == 6)) {
            adr_val = request_memory_word(adr);
            if (adr_val < 0) return;
            else debug("VAL = "+(string)adr_val);
        }
        busy = 1;
        RAM_FLG = 0;
        // decode & do
        if (cmd == 0) {
            // ADD
            summator(adr_val);
            IP += 1;
        } else if (cmd == 1) {
            // SUB
            summator(-adr_val);
            IP += 1;
        } else if (cmd == 2) {
            // E1 (jump if abs(summ)==0)
            if ((summ==0) || (summ==b_peak)) IP = adr;
            else IP += 1;
        } else if (cmd == 3) {
            // E2 (jump if negative)
            if (summ >= b_peak) IP = adr;
            else IP += 1;
        } else if (cmd == 4) {
            // E3 (absolute jump)
            IP = adr;
        } else if (cmd == 5) {
            // OUT (send to memory)
            change_memory_word(adr,summ);
            IP += 1;
        } else if (cmd == 6) {
            // IN (copy from memory)
            summ = adr_val;
            IP += 1;
        } else if (cmd == 7) {
            // HALT
            IP += 1;
            w_flag = 0;
            llResetTime();
        } else {
            llSay(0,"Fatal error on command decoding!");
            w_flag = 0;
            return;
        }
        // update
        update_summator_leds();
        cache_sync();
        if (one_shot) {
            llSay(0,"One shot.");
            poweron(0);
        }
        busy = 0;
    }

    touch_start(integer total_number)
    {
        if (w_flag) {
            poweron(0);
            llSay(0,"Stopped.");
        } else {
            poweron(1);
            llSay(0,"Started.");
        }
    }
    
    on_rez(integer p)
    {
        llResetScript();
    }
    
    listen(integer _ch, string _nm, key _id, string _msg)
    {
//        if (_id == llGetKey()) return;
        // ** RAM channel **
        if ((RAM_FLG > 0) && (_ch == memory_channel) && (llGetOwnerKey(_id) == owner)) {
            list tml = llParseString2List(_msg,[" "],[]);
            string vs = llList2String(tml,0);
            if (vs == "VAL") {
                RAM_rg = llList2Integer(tml,1);
                if (RAM_rg < 0) {
                    RAM_rg = a_peak; // strange situation, but can cause deadlock if RAM_rg is below zero
                    llSay(0,"Possible memory error at $"+(string)RAM_adr);
                }
                cache_put(RAM_adr,RAM_rg);
                debug("Value get for $"+(string)RAM_adr+" = "+(string)RAM_rg+" @ flag "+(string)RAM_FLG);
                RAM_FLG++;
            } else if (vs == "CAC") {
                integer aval = llList2Integer(tml,1);
                cache_put(aval,llList2Integer(tml,2));
                debug("Cache value received for $"+(string)aval);
            }
            return;
        }
        // ** local chat **
        if (_id != owner) return;
        integer tst;
        if (_msg=="reset") llResetScript();
        else if (_msg=="help") {
            // TODO: write some :)
        } else if (_msg == "debug") {
            m_debug = circle(m_debug,2);
            llSay(0,"Debugging level now set to "+(string)m_debug);
        } else if (_msg == "getsum") {
            tst = summ;
            if (summ >= b_peak) tst -= b_peak;
            llSay(0,"summator = "+(string)summ+"\nuMNC = "+(string)tst+" D");
        } else if (_msg == "vcache") {
            string str;
            llSay(0,"Cache table dump:");
            for (tst=0; tst<(cache_size*3); tst+=3) {
                str = "$"+(string)llList2Integer(cache,tst) + " :: ";
                str += (string)llList2Integer(cache,tst+1) + " || ";
                str += (string)llList2Integer(cache,tst+2) + " hits";
                llSay(0,str);
            }
            llSay(0,"End of cache table.");
        } else if (_msg == "rawcache") {
            rawcache();
        } else if (_msg == "cache reset") {
            init_cache();
        } else if (_msg == "oneshot") {
            one_shot = 1 - one_shot;
            if (one_shot) llSay(0,"OneShot mode active");
        } else if ((_ch == 0) && (llGetSubString(_msg,0,0)=="!")) {
            tst = (integer)llGetSubString(_msg,1,-1);
            if (tst >= a_peak) {
                llSay(0,"Wrong number given to "+(string)digits+" bits machine!");
                return;
            }
            summ = sign_bit(tst);
            update_summator_leds();
        } else if ((_ch == 0) && (find_notecard(_msg))) {
            prog_cardname = _msg;
            init_cache();
            state readthecard;
        } else if (m_debug > 0 ) {
            tst = (integer)_msg;
            if ((_ch == 0) && ((tst>=0) && (tst<mem_top))) {
                llSay(0,"MEM["+(string)tst+"] = "+(string)request_memory_word(tst));
                dbg_last_test = tst;
            } else if ((_ch == 1) && ((tst>=0) && (tst<a_peak))) {
                change_memory_word(dbg_last_test,tst);
                llSay(0,"MEM["+(string)dbg_last_test+"] := "+(string)tst);
            }
        }
    }
}

state readthecard
{
    state_entry()
    {
        llSay(0,"Reading the card ["+prog_cardname+"]...");
        prog_heap = mem_top; // just for now
        prog_translate = [];
        temp_code = [];
        IP = 0;
        virtIP = 0;
        prog_datapoint = prog_heap - 1;
        // begin reading
        notecardline = -1;
        nextnoteline();
    }
    
    dataserver(key query_id, string data)
    {
        if (query_id != kQuery) return;
        string tmp;
        integer aar;
        integer itr;
        integer ii;
        list lex;
        if (data == EOF) {
            // second pass
            debug("SECOND PASS BEGINS");
            for (ii=0; ii<llGetListLength(temp_code); ii++) {
                lex = llParseString2List(llList2String(temp_code,ii),[" "],[]);
                tmp = llList2String(lex,0);
                if (tmp == "ADD") itr = 0;
                else if (tmp == "SUB") itr = 1;
                else if (tmp == "E1") itr = 2;
                else if (tmp == "E2") itr = 3;
                else if (tmp == "E3") itr = 4;
                else if (tmp == "OUT") itr = 5;
                else if (tmp == "IN") itr = 6;
                else if (tmp == "HALT") itr = 7;
                else {
                    card_read_err_handler("Unknown instruction on line "+(string)notecardline);
                    state default;
                }
                tmp = llList2String(lex,1);
                aar = translate_lookup(tmp);
                debug("addr of '"+tmp+"' translated as "+(string)aar);
                if (aar < 0) {
                    card_read_err_handler("Unknown data label '"+tmp+"' detected on line "+(string)notecardline);
                    state default;
                }
                aar = aar * 8 + itr;
                lex = [aar];
                debug("["+(string)IP+"]: "+(string)lex);
                change_memory_word(IP,aar);
//                memory = llListReplaceList(memory,lex,IP,IP);
                IP++;
                if (prog_datapoint < IP) /* COLLIDE! */ {
                    card_read_err_handler("Memory space collision detected @ "+(string)IP);
                    state default;
                }
            }
            llSay(0,"Card readed and translated!");
            llOwnerSay((string)llGetFreeMemory()+" bytes left in script's heap.");
            state default;
            return;
        } else if (llStringLength(data)>1) {
            if (llGetSubString(data,0,1) == "//") {
                debug("comment '"+data+"'");
            } else if (llGetSubString(data,0,0) == ":") {
                tmp = llGetSubString(data,1,-1);
                debug("label '"+tmp+"' ptr = "+(string)virtIP);
                prog_translate += [tmp];
                prog_translate += [virtIP];
            } else {
                // first pass
                lex = llParseString2List(data,[" "],[]);
                if (llGetListLength(lex) < 2) {
                    card_read_err_handler("Invalid expression on line "+(string)notecardline);
                    state default;
                }
                tmp = llList2String(lex,0);
                if (tmp == "DB") {
                    tmp = llList2String(lex,1);
                    aar = sign_bit(llList2Integer(lex,2));
                    debug("db ["+tmp+"] = "+(string)aar+" @ "+(string)prog_datapoint);
                    prog_translate += [tmp];
                    prog_translate += [prog_datapoint];
                    // is the data part of DB record is pointer?
                    tmp = llList2String(lex,2);
                    if (llGetSubString(tmp,0,0) == "^") {
                        tmp = llGetSubString(tmp,1,-1);
                        aar = translate_lookup(tmp);
                        if (aar < 0) {
                            card_read_err_handler("Line "+(string)notecardline+" contains pointer reference to unknown variable or label");
                            state default;
                        } else debug("db pointer '"+tmp+"' resolved as address "+(string)aar);
                    }
                    // place the data to memory map
                    change_memory_word(prog_datapoint,aar);
//                    lex = [aar];
//                    memory = llListReplaceList(memory,lex,prog_datapoint,prog_datapoint);
                    prog_datapoint--;
                } else {
                    temp_code += [data];
                    virtIP++;
                }
            }
        }
        nextnoteline();
    }
}
