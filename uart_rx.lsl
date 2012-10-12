integer uart = -180;
integer baudrate = 600;

list printable = [" ","!","\"","#","$","%","&","'","(",")","*","+",",","-",".","/","0","1","2","3","4","5","6","7","8","9",":",";","<","=",">","?","@","A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z","[","\\","]","^","_","`","a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z","{","|","}","~"];
integer print_offset = 32;

string buf = "";
string bitbuf = "1";
integer bitcnt = 0;
string text_buffer = "";

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
        float tau = 1.0 / ((float)baudrate / 10.0);
        llSetTimerEvent(tau);
        llSay(0,"UART Receiver timer set to "+(string)tau+" sec.");
        llResetTime();
    }
    
    timer()
    {
        if ((bitcnt == 0) && (bitbuf != "0")) return; // detect start bit
        buf += bitbuf;
        bitcnt++;
        llSetText(buf,<1,1,1>,1);
        if (bitcnt == 10) {
            if (bitbuf != "1")
                llSetText("error: no stop bit",<1,1,1>,1);
            else {
                integer k = decode(llGetSubString(buf,1,8));
                string cur = llList2String(printable,k-print_offset);
                llSetText(buf+"\ncode: "+(string)k+"\ndecode: "+cur,<1,1,1>,1);
                text_buffer += cur;
            }
            buf = "";
            bitcnt = 0;
        }
    }
    
    listen(integer ch, string name, key id, string msg)
    {
        if ((msg != "0") && (msg != "1")) return;
        bitbuf = llGetSubString(msg,0,0);
    }

    touch_start(integer total_number)
    {
        llSay(0,"Previous text buffer:\n"+text_buffer);
        llSetText("",ZERO_VECTOR,0);
        llSay(0,"soft reset");
        buf = "";
        bitcnt = 0;
        bitbuf =  "1";
        text_buffer = "";
    }
}

