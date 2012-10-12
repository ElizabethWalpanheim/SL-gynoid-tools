// TX !
// 1 start bit
// 8 bits data
// 1 stop bit
// no parity
// 10 bits length

list printable = [" ","!","\"","#","$","%","&","'","(",")","*","+",",","-",".","/","0","1","2","3","4","5","6","7","8","9",":",";","<","=",">","?","@","A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z","[","\\","]","^","_","`","a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z","{","|","}","~"];
integer print_offset = 32;

integer baudrate = 600;
integer uart = -180;
string buf = ""; // BIT buffer
integer BL; // buf length, for speed reasons
string cbyte; // for visualizer
string FIFO = "";
string global_ch;

string reverse(string in)
{
    string out = "";
    integer i;
    for (i=llStringLength(in)-1; i>=0; i--)
        out += llGetSubString(in,i,i);
    return out;
}

prepare_byte(string byte)
{
    integer i;
    integer j = 128;
    if (BL > 0) {
        FIFO += byte;
        return;
    }
    llResetTime();
    buf = "";
    BL = 0;
    cbyte = byte;
    integer k = llListFindList(printable,[byte]);//llGetSubString(byte,0,0)]);
    //llOwnerSay("original k="+(string)k);
    if (k < 0) return;
    k += print_offset;
    for (i=7; i>=0; i--) {
        //llOwnerSay("k="+(string)k);
        //if (i == 0) j = 0;
        if (k-j >= 0) {
            buf += "1";
            k -= j;
        } else buf += "0";
        //llOwnerSay("j="+(string)j);
        j /= 2;
    }
    buf = "1" + buf + "0"; //  one stop, one start (reversed)
    BL = 10;
    llResetTime();
}

default
{
    state_entry()
    {
        llListen(0,"",llGetOwner(),"");
        float tau = 1.0 / ((float)baudrate / 10.0);
        llSetTimerEvent(tau);
        llSay(0,"Transmitter timer set to "+(string)tau+" sec.");
        llResetTime();
    }
    
    timer()
    {
        if (BL <= 0) return;
        BL--;
        global_ch = llGetSubString(buf,BL,BL);
        llSetText(cbyte+"\n"+global_ch,<1,1,1>,1);
        llWhisper(uart,global_ch);
        if ((BL == 0) && (FIFO != "")) {
            if (llStringLength(FIFO) == 1) {
                prepare_byte(FIFO);
                FIFO = "";
            } else {
                prepare_byte(llGetSubString(FIFO,0,0));
                FIFO = llGetSubString(FIFO,1,-1);
            }
        }
    }
    
    listen(integer ch, string name, key id, string msg)
    {
        integer i;
        integer l = llStringLength(msg);
        for (i=0; i<l; i++) prepare_byte(llGetSubString(msg,i,i));
    }

    touch_start(integer total_number)
    {
        prepare_byte("S");
    }
}

