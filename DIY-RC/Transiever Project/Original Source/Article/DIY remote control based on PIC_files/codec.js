function up(button)
{
  // var msg = document.getElementById("msg");
  var txtype = document.form1.txtype.value;
  var rxtype = document.form1.rxtype.value;
  if (txtype == 4) { if (button<5) { channel = button; sendcmd="on"; } else { channel = button-4; sendcmd="off"; }}
  if (txtype == 8) { channel = button; sendcmd="toggle"; }

  var outtype = "L"; if (document.getElementById("l"+channel).checked == "") { outtype="M"; }
  var outfield = document.getElementById("r" + channel);
  // msg.innerHTML="RELEASE: txtype="+txtype +" rxtype="+rxtype + "<br> channel=" + channel + " sendcmd="+sendcmd + " outtype=" + outtype;

  if ((rxtype == 4) && (channel > 4)) return; //invalid channel

  if (outtype == "M") outfield.style.display = "none";

  if (rxtype == 4)
  { // handle additional momentary outputs
    document.getElementById("r"+(channel+4)).style.display="none";
  }

}

function down(button)
{
  // var msg = document.getElementById("msg");
  var txtype = document.form1.txtype.value;
  var rxtype = document.form1.rxtype.value;
  if (txtype == 4) { if (button<5) { channel = button; sendcmd="on"; } else { channel = button-4; sendcmd="off"; }}
  if (txtype == 8) { channel = button; sendcmd="toggle"; }

  var outtype = "L"; if (document.getElementById("l"+channel).checked == "") { outtype="M"; }
  var outfield = document.getElementById("r" + channel);
  // msg.innerHTML="PUSH: txtype="+txtype +" rxtype="+rxtype + "<br> channel=" + channel + " sendcmd="+sendcmd + " outtype=" + outtype;

  if ((rxtype == 4) && (channel > 4)) return; //invalid channel

  if (outtype == "M") outfield.style.display = "";

  if (outtype == "L")
  {
    if (sendcmd == "toggle")
    {
      if (outfield.style.display == "none") outfield.style.display=""; else outfield.style.display="none";
    }
    if (sendcmd == "on") outfield.style.display="";
    if (sendcmd == "off") outfield.style.display="none";
  }

  if (rxtype == 4)
  { // handle additional momentary outputs
    document.getElementById("r"+(channel+4)).style.display="";
  }

}

function settxtype(s)
{
   // var msg = document.getElementById("msg");
   // msg.innerHTML = "value=" + s.value;
   if (s.value == 4)
   {
     for (i = 1; i<5; i++)
     {
       document.getElementById("t"+i).innerHTML="on"+i;
       document.getElementById("t"+(i+4)).innerHTML="off"+i;
     }
   }
   if (s.value == 8)
   {
     for (i = 1; i<9; i++)
       document.getElementById("t"+i).innerHTML="ch"+i;
   }
}

function setrxtype(s)
{
   // var msg = document.getElementById("msg");
   // msg.innerHTML = "value=" + s.value;

   if (s.value == 4)
   {
     for (i = 1; i<5; i++)
     {
       document.getElementById("n"+i).innerHTML="ch"+i;
       document.getElementById("n"+(i+4)).innerHTML="ch"+i;
       l=document.getElementById("l"+i); l.checked="checked"; l.disabled=true;
       m=document.getElementById("m"+i); m.checked=""; m.disabled=true;
       l=document.getElementById("l"+(i+4)); l.checked=""; l.disabled=true;
       m=document.getElementById("m"+(i+4)); m.checked="checked"; m.disabled=true;

       document.getElementById("r"+i).style.display="none";
       document.getElementById("r"+(i+4)).style.display="none";
     }
   }

  if (s.value == 8)
  {
    for (i = 1; i<9; i++)
    {
      document.getElementById("n"+i).innerHTML="ch"+i;
      l=document.getElementById("l"+i); l.checked=l.defaultChecked; l.disabled=false;
      m=document.getElementById("m"+i); m.checked=m.defaultChecked; m.disabled=false;

      document.getElementById("r"+i).style.display="none";
    }
  }

}

function load()
{
  // initalize
  settxtype(document.form1.txtype);
  setrxtype(document.form1.rxtype);
}
