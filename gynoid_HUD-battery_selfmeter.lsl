integer GynoidIChan = -257776; // internal channel
string battery = "g-battery";
vector color = <1.0,0.8,0.7>;

integer isbat(string name)
{
    integer r = llListFindList(llParseString2List(name,[],[battery]),[battery]);
    if (r < 0) return 0;
    else return 1;
}

default
{
    state_entry()
    {
        llSetText("Init",color,1.0);
        llListen(GynoidIChan,"","","");
        llSetLinkColor(LINK_THIS,ZERO_VECTOR,ALL_SIDES);
    }

    listen(integer _chan, string _name, key _id, string _msg)
    {
        if ((_chan == GynoidIChan) && (llGetOwnerKey(_id)==llGetOwner()) && (isbat(_name))) {
            integer bat = (integer)_msg; // conversion to make sure the value will be integer
            if (bat == 0) llSetText("FAIL",color,0.9);
            else llSetText("Your battery's current level is "+(string)bat,color,1.0);
            if (bat < 5) llSetLinkColor(LINK_THIS,<1,0,0>,ALL_SIDES);
            else if (bat < 20) llSetLinkColor(LINK_THIS,<1,1,0>,ALL_SIDES);
            else llSetLinkColor(LINK_THIS,<0,1,0>,ALL_SIDES);
        }
    }

    link_message(integer sndr, integer num, string str, key id)
    {
        if (str == "reset") llResetScript();
    }
}

