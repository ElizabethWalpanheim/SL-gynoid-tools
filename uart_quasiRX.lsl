integer uart = -180;
string buf = "";

list printable = [" ","!","\"","#","$","%","&","'","(",")","*","+",",","-",".","/","0","1","2","3","4","5","6","7","8","9",":",";","<","=",">","?","@","A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z","[","\\","]","^","_","`","a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z","{","|","}","~"];
integer print_offset = 32;

integer bitcnt = 0;

string reverse(string in)
{
    string out = "";
    integer i;
    for (i=llStringLength(in)-1; i>=0; i--)
        out += llGetSubString(in,i,i);
    return out;
}

integer decode(string in)
{
    integer i;
    integer y = 0;
    integer k = 1;
    for (i=0; i<8; i++) {
        if (llGetSubString(in,i,i) == "1") y += k;
        k *= 2;
    }
    return y;
}

default
{
    state_entry()
    {
        llListen(uart,"","","");
        llSay(0,"rd");
    }
    
    listen(integer ch, string name, key id, string msg)
    {
        msg = llGetSubString(msg,0,0);
        if ((msg != "0") && (msg != "1")) return; // binary only
        if ((bitcnt == 0) && (msg != "0")) return; // detect start bit
        buf += msg;
        bitcnt++;
        llSetText(buf,<1,1,1>,1);
        if (bitcnt == 10) {
            if (msg != "1")
                llSetText("error: no stop bit",<1,1,1>,1);
            else {
                integer k = decode(llGetSubString(buf,1,8));
                llSetText(buf+"\ncode: "+(string)k+"\ndecode: "+llList2String(printable,k-print_offset),<1,1,1>,1);
            }
            buf = "";
            bitcnt = 0;
        }
    }

    touch_start(integer total_number)
    {
        llSay(0, "Touched.");
        buf = "";
        bitcnt = 0;
    }
}

