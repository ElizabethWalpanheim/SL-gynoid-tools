default
{
    state_entry()
    {
        llListen(3,"",llGetOwner(),"");
    }
    listen(integer ch, string nm, key id, string msg)
    {
        list p = llParseString2List(msg,[","],[]);
        llOwnerSay(llDumpList2String(p,","));
        integer i;
        integer k;
        integer r = 0;
        for (i=0; i<4; i++) {
            k = (integer)llList2String(p,i);
            if ((k<0) || (k>255)) k = 0;
            r = r | k;
            if (i<3) r = r << 8;
        }
        llOwnerSay("packed = "+(string)r);
        for (i=0; i<4; i++) {
            if (i>0) r = r >> 8;
            k = r & 255;
            llOwnerSay("Unpack: "+(string)i+")  "+(string)k);
        }
    }
}

