#!/usr/bin/perl
#
# originally coded by Martin Pot 2003
# http://martybugs.net/smoothwall/rrdtool_mem.cgi
#
# SmoothWall CGIs
#
# This code is distributed under the terms of the GPL
#
# (c) The SmoothWall Team
# pgraphs.cgi

my $release = "Version 1.6";

use lib "/usr/lib/smoothwall";
use header qw( :standard );

my %cgiparams;
my @graphs;

my $title = "";
my $name = "";
my $dbname;
my $graphname;

my $rrddir = "/httpd/html/rrdtool";
my $dbdir = "/var/lib/rrd";
my $scriptdir = "/usr/bin/smoothwall";
# the prefs_file should be -rw-rw-rw- (666)
my $prefs_file = "${swroot}/mods/pgraphs/preferences/stored";

my %dnssettings;
my %ethersettings;
my %hop;

# preferences
my %pgraphsset;
my $bad_prefs="";
my $errormessage = "";

my %cron;
my %rrd;
my %desc;

&setup_cron_rrd_desc();

# get url parameters
my @values = split(/&/, $ENV{'QUERY_STRING'});
foreach my $i (@values) {
        ($varname, $mydata) = split(/=/, $i);
        if ($varname eq 'i') {
                $name = $mydata;
        }
}

# check if viewing detailed graphs only, if so change the title 
if ($name ne "") { 
	$title = " - ".$desc{$name};
}

&showhttpheaders();

#set some defaults for the preferences and then read the file
&set_prefs_default();
&read_prefs_file(); 

# check if viewing summary graphs and choose which graphs to show
if ($name ne "") {
	push (@graphs, ("$name-hour")); #for expansion?
	push (@graphs, ("$name-day"));
	push (@graphs, ("$name-week"));
	push (@graphs, ("$name-month"));
	push (@graphs, ("$name-year"));
} else {
	&set_graph_order();
}

$cgiparams{'ACTION'} = " " ;
&getcgihash(\%cgiparams);
&get_prefs_from_cgi();

# do not auto refresh if the customise box is open
if ($pgraphsset{'customise_open'} eq "N") {
	&openpage($tr{'performance graphs'}."$title", 1, ' <META HTTP-EQUIV="Refresh" CONTENT="300"> <META HTTP-EQUIV="Cache-Control" content="no-cache"> <META HTTP-EQUIV="Pragma" CONTENT="no-cache"> ', 'about your smoothie');
} else {
	&openpage($tr{'performance graphs'}."$title", 1, ' <META HTTP-EQUIV="Cache-Control" content="no-cache"> <META HTTP-EQUIV="Pragma" CONTENT="no-cache"> ', 'about your smoothie');
}

&openbigbox('100%', 'LEFT');
&alertbox($errormessage);

if ($pgraphsset{'customise_open'} eq "N") {
   &openbox($tr{'performance graphsc'}." $release");
} else {
   &openbox($tr{'performance graphsc'}." $release - Customise is open");
}
if ($pgraphsset{'showupdatedtime'} eq "Y" ) {
  if ( $name ne "" ) {
    $dbname = $name;
    if (-e "$dbdir/$rrd{$dbname}.rrd") {
      my $lastdata = scalar localtime(`rrdtool last $dbdir/$rrd{$dbname}.rrd`);
      my $lastupdate = scalar localtime((stat("$dbdir/$rrd{$dbname}.rrd"))[9]);
      print "Last updated $lastupdate, with data to $lastdata";
    }	   
  } else {
    foreach $graphname (@graphs) {
      if (-e "$rrddir/$graphname.png") {
        $dbname = substr($graphname,0,index($graphname,"-"));
	my $lastdata = scalar localtime(`rrdtool last $dbdir/$rrd{$dbname}.rrd`);
        my $lastupdate = scalar localtime((stat("$dbdir/$rrd{$dbname}.rrd"))[9]);
	if ($pgraphsset{$dbname.'_show'} ne "N") {   
	  print $desc{$dbname} . " last updated $lastupdate, with data to $lastdata<br>";
        }
      }
    }
  } 
}
  &closebox();

&openbox('');

if ($name ne "") { 
	print "<b>Detailed graphs of ".$desc{$name}.":</b><br>\n";
} else { 
	print "<b>Summary graphs:</b><br>\n";
}

print qq| <div align="center"> |;

my $found = 0;

if ( $name ne "" ) {
	print qq|&laquo; <a href="?">return to graph summary</a><br><br>|;
}

foreach $graphname (@graphs) {
	if (-e "$rrddir/$graphname.png") {
	    # check if displaying summary graphs
	    $dbname = (substr($graphname,0,index($graphname,"-")));
            if ($pgraphsset{$dbname.'_show'} ne "N") {   
		if ($name eq "") { 
		   print "<a href='".$ENV{'SCRIPT_NAME'}."?i=".$dbname."'";
		   print " title='click for detailed graphs of ".$desc{$dbname}."'>";
		   print "<img";
		} else {
		   print "<img alt='$graphname'";
		}
		print " border='0' src='/rrdtool/$graphname.png'>";
		if ($name eq "") { 
		   print "</a><br><a href=\"?i=$dbname\"";
		   print ">click for detailed graphs of ".$desc{$dbname}."</a> &raquo";
		}
		print "<br><br>\n";
		$found = 1;
	    }
	}
}

if (!$found) {
	print "<B><CLASS='boldbase'>$tr{'no graphs available'}</CLASS></B>";
}

print "<br>\n";
print "</div>";

&closebox();

if ( $name eq "" ) {
	&openbox('');
        if ("$bad_prefs" ne "") {
           print "<table class='warning'><tr>";
	   print "<td class='warningimg'><img src='/ui/img/warning.jpg' alt=''></td>";
	   print "<td class='warning'>$bad_prefs</td>";
	   print "</tr></table>\n";
	}
   	if ($pgraphsset{'customise_open'} eq "N") {
	   print "<form method='post'><table class='blank'><tr>";
	   print "<td style='text-align: center; width: 50%;'><input type='submit' name='ACTION' value='Customise'></td>";
	   print "</tr></table></form>";
	} else {
#original code for swaps is GPLv3 from http://forgottoattach.com/
#much modified to -
#preserve top header row of the table
#and stop top to bottom leaps and vice versa
#and to preserve checkbox states as elementn.innerHTML = element.innerHTML 
#doesn't work for <tr> elements - fix IE bug
#and to produce a list of the order of the rows
#and to keep the focus on the moved button so <return> will repeat the move
#NEEDS each element to be tweaked to be named as per the value of 
#the last (hidden) <input> of the last <td> - see "which" below
# I hope I have kept this pretty browser independent...
	   print <<JVS
<script type="text/javascript">
    function moveElementDown(element){
	var elementp = element.parentNode;
	var elements = elementp.getElementsByTagName(element.nodeName);
	var newlist  = "";
	for(i=0;i<(elements.length-1);i++){
            if(elements[i]==element){
		var elementn = element.cloneNode(true);
		var which = element.lastChild.lastChild.value;
                var ns = document.getElementById(which+"_show").checked;
                var nc = document.getElementById(which+"_collect").checked;
		elementp.insertBefore(elementn,elements[i+1].nextSibling); 
		elementp.removeChild(element);
                document.getElementById(which+"_show").checked = ns;
                document.getElementById(which+"_collect").checked = nc;
                document.getElementById(which+"_down").focus();
            }
	}
	elements = elementp.getElementsByTagName(element.nodeName);
	for(i=1;i<elements.length;i++){
	    newlist += (elements[i].lastChild.lastChild.value) + ":";
	}
	document.getElementById('graphorder').value = newlist;
    }

    function moveElementUp(element){
	var elementp = element.parentNode;
	var elements = elementp.getElementsByTagName(element.nodeName);
	var newlist  = "";
	for(i=2;i<elements.length;i++){
            if(elements[i]==element){
		var elementn = element.cloneNode(true);
		var which = element.lastChild.lastChild.value;
                var ns = document.getElementById(which+"_show").checked;
                var nc = document.getElementById(which+"_collect").checked;
		elementp.insertBefore(elementn,elements[i-1]); 
            	elementp.removeChild(element);
                document.getElementById(which+"_show").checked = ns;
                document.getElementById(which+"_collect").checked = nc;
                document.getElementById(which+"_up").focus();
	    }
	}
	elements = elementp.getElementsByTagName(element.nodeName);
	for(i=1;i<elements.length;i++){
	    newlist += (elements[i].lastChild.lastChild.value) + ":";
	}
	document.getElementById('graphorder').value = newlist;
    }
</script>
JVS
	   ;
	   print "<b>Customise:</b>&nbsp;&nbsp;(this page will not auto refresh while this box is open)\n";
	   print "<form method='post'>";
	   print "<input id ='showupdatedtime' type='checkbox' name='showupdatedtime' ";
	   if ($pgraphsset{'showupdatedtime'} ne "N") {
	   	print " checked ";
	   }
	   print ">&nbsp;Show the Performance Graphs: <span style=\"font-style: italic\">&lt;graph name&gt;</span> last updated <span style=\"font-style: italic\">&lt;timestamp&gt;</span>, with data to <span style=\"font-style: italic\">&lt;timestamp&gt;</span> information<br><br>";
	   print "<table>";
	   print "<tr><th>crontab entry</th><th>Collect data in</th><th>Graph name</th><th>Show graph</th><th>Move</th></tr>";
	   
	   my %cronseen;
	   open INFILE, "</etc/crontab";
	   foreach $cronline (<INFILE>) {
	      if ( $cronline =~ /\/usr\/bin\/smoothwall\/rrdtool_/ ) { 
	         foreach $graphname (@graphs) {
                    my $dbname = (substr($graphname,0,index($graphname,"-")));
                    if ( $cronline =~ /rrdtool_$cron{$dbname}\.pl/ ) { 
                       if (!( $cronline =~ /#/ )) {
		         $cronseen{$dbname} = "checked";
		       }	 
		    }
	         }
              }
	   }
	   close INFILE;
	   
	   my $namelist;
	   foreach $graphname (@graphs) {
         	my $dbname = (substr($graphname,0,index($graphname,"-")));
		$namelist=$namelist.$dbname.":";
		print "<tr><td><input type='checkbox' "; 
		print " $cronseen{$dbname} ";
		print "disabled >&nbsp;rrdtool_$cron{$dbname}.pl</td>";
	 	print "<td><input id='$dbname" . "_collect' type='checkbox' name='$dbname" . "_collect' "; 
	 	if ($pgraphsset{$dbname.'_collect'} ne "N") {   
	    		print " checked "; 
         	}	
    		print ">&nbsp;$rrd{$dbname}.rrd</td><td>$dbname-day.png</td>";
	 	print "<td><input id='$dbname" . "_show' type='checkbox' name='$dbname" . "_show' "; 
	 	if ($pgraphsset{$dbname.'_show'} ne "N") {
	    		print " checked "; 
         	}	
    		print ">&nbsp;$desc{$dbname}</td>";
		print "<td>";
		print "<input type='button' id='$dbname" . "_up' onClick=\"moveElementUp(this.parentNode.parentNode);\" value=\"&uarr;\">";
		print "<input type='button' id='$dbname" . "_down' onClick=\"moveElementDown(this.parentNode.parentNode);\" value=\"&darr;\">";
		print "<input type='hidden' value='$dbname'>";
		print "</td></tr>\n";
    	   }
    	   print "</table>";
	   print "<input type='hidden' value='$namelist' id='graphorder' name='graphorder'>\n";
	   &get_dns_settings;
	   &get_traceroute;
           print <<STUFF
<br>If you are collecting red_avail or ping, please fill in 4 Red side IP addresses or hostnames to ping<br>
<table>
<tr><td rowspan=2>
<INPUT TYPE='text' NAME='target1' VALUE='$pgraphsset{"target_1"}' id='target1'  
onKeyUp="validregex('target1','^[a-zA-Z_0-9-\.]+\$', false)"  
onFocus="validregex('target1','^[a-zA-Z_0-9-\.]+\$', false)"  
onBlur="validregex('target1','^[a-zA-Z_0-9-\.]+\$', false)"  
onChange="validregex('target1','^[a-zA-Z_0-9-\.]+\$', false)" >
e.g. www.google.com<br>
<INPUT TYPE='text' NAME='target2' VALUE='$pgraphsset{"target_2"}' id='target2'  
onKeyUp="validregex('target2','^[a-zA-Z_0-9-\.]+\$', false)"  
onFocus="validregex('target2','^[a-zA-Z_0-9-\.]+\$', false)"  
onBlur="validregex('target2','^[a-zA-Z_0-9-\.]+\$', false)"  
onChange="validregex('target2','^[a-zA-Z_0-9-\.]+\$', false)" >
e.g. www.yahoo.com<br>
<INPUT TYPE='text' NAME='target3' VALUE='$pgraphsset{"target_3"}' id='target3'  
onKeyUp="validregex('target3','^[a-zA-Z_0-9-\.]+\$', false)"  
onFocus="validregex('target3','^[a-zA-Z_0-9-\.]+\$', false)"  
onBlur="validregex('target3','^[a-zA-Z_0-9-\.]+\$', false)"  
onChange="validregex('target3','^[a-zA-Z_0-9-\.]+\$', false)" >
e.g. your Red DNS server<br>
<INPUT TYPE='text' NAME='target4' VALUE='$pgraphsset{"target_4"}' id='target4' 
onKeyUp="validregex('target4','^[a-zA-Z_0-9-\.]+\$', false)"  
onFocus="validregex('target4','^[a-zA-Z_0-9-\.]+\$', false)"  
onBlur="validregex('target4','^[a-zA-Z_0-9-\.]+\$', false)"  
onChange="validregex('target4','^[a-zA-Z_0-9-\.]+\$', false)" >
e.g. your nearest ISP hop<br>
</td><td valign=top>
STUFF
	  ;
	print "Your Red DNS Servers are: </td><td> $dnssettings{'DNS1'} <br> $dnssettings{'DNS2'} <br></td></tr>\n"; 
	print "<tr><td valign=top>Your first 5 hops in traceroute are: </td><td> $hop{1} <br> $hop{2} <br> $hop{3} <br> $hop{4} <br> $hop{5} </td></tr></table>\n";
	print <<ENDX
<br>
<table >
<tr>
<td colspan=10>select and name sensors - this will take a while to update the graphs</td>
</tr>
<tr>
<td>Fans</td>
<td align='center'>fan1</td>
<td align='center'>fan2</td>
<td align='center'>fan3</td>
<td align='center'>fan4</td>
<td align='center'>fan5</td>
<td align='center'>fan6</td>
<td align='center'>fan7</td>
</tr>
<tr>
<td align='right'>find:</td>
<td><INPUT TYPE='text' NAME='ffan1' VALUE='$pgraphsset{"sensors_fan1_find"}'
 id='ffan1' size='8' ></td>
<td><INPUT TYPE='text' NAME='ffan2' VALUE='$pgraphsset{"sensors_fan2_find"}'
 id='ffan2' size='8' ></td>
<td><INPUT TYPE='text' NAME='ffan3' VALUE='$pgraphsset{"sensors_fan3_find"}'
 id='ffan3' size='8' ></td>
<td><INPUT TYPE='text' NAME='ffan4' VALUE='$pgraphsset{"sensors_fan4_find"}'
 id='ffan4' size='8' ></td>
<td><INPUT TYPE='text' NAME='ffan5' VALUE='$pgraphsset{"sensors_fan5_find"}'
 id='ffan5' size='8' ></td>
<td><INPUT TYPE='text' NAME='ffan6' VALUE='$pgraphsset{"sensors_fan6_find"}'
 id='ffan6' size='8' ></td>
<td><INPUT TYPE='text' NAME='ffan7' VALUE='$pgraphsset{"sensors_fan7_find"}'
 id='ffan7' size='8' ></td>
</tr>
<tr>
<td align='right'>show:</td>
<td><INPUT TYPE='text' NAME='sfan1' VALUE='$pgraphsset{"sensors_fan1_show"}'
 id='sfan1' size='8' ></td>
<td><INPUT TYPE='text' NAME='sfan2' VALUE='$pgraphsset{"sensors_fan2_show"}'
 id='sfan2' size='8' ></td>
<td><INPUT TYPE='text' NAME='sfan3' VALUE='$pgraphsset{"sensors_fan3_show"}'
 id='sfan3' size='8' ></td>
<td><INPUT TYPE='text' NAME='sfan4' VALUE='$pgraphsset{"sensors_fan4_show"}'
 id='sfan4' size='8' ></td>
<td><INPUT TYPE='text' NAME='sfan5' VALUE='$pgraphsset{"sensors_fan5_show"}'
 id='sfan5' size='8' ></td>
<td><INPUT TYPE='text' NAME='sfan6' VALUE='$pgraphsset{"sensors_fan6_show"}'
 id='sfan6' size='8' ></td>
<td><INPUT TYPE='text' NAME='sfan7' VALUE='$pgraphsset{"sensors_fan7_show"}'
 id='sfan7' size='8' ></td>
</tr>
<tr>
<td>Temperatures</td>
<td align='center'>temp1</td>
<td align='center'>temp2</td>
<td align='center'>temp3</td>
<td align='center'>temp4</td>
<td align='center'>temp5</td>
<td align='center'>temp6</td>
<td align='center'>temp7</td>
</tr>
<tr>
<td align='right'>find:</td>
<td><INPUT TYPE='text' NAME='ftemp1' VALUE='$pgraphsset{"sensors_temp1_find"}'
 id='ftemp1' size='8' ></td>
<td><INPUT TYPE='text' NAME='ftemp2' VALUE='$pgraphsset{"sensors_temp2_find"}'
 id='ftemp2' size='8' ></td>
<td><INPUT TYPE='text' NAME='ftemp3' VALUE='$pgraphsset{"sensors_temp3_find"}'
 id='ftemp3' size='8' ></td>
<td><INPUT TYPE='text' NAME='ftemp4' VALUE='$pgraphsset{"sensors_temp4_find"}'
 id='ftemp4' size='8' ></td>
<td><INPUT TYPE='text' NAME='ftemp5' VALUE='$pgraphsset{"sensors_temp5_find"}'
 id='ftemp5' size='8' ></td>
<td><INPUT TYPE='text' NAME='ftemp6' VALUE='$pgraphsset{"sensors_temp6_find"}'
 id='ftemp6' size='8' ></td>
<td><INPUT TYPE='text' NAME='ftemp7' VALUE='$pgraphsset{"sensors_temp7_find"}'
 id='ftemp7' size='8' ></td>
</tr>
<tr>
<td align='right'>show:</td>
<td><INPUT TYPE='text' NAME='stemp1' VALUE='$pgraphsset{"sensors_temp1_show"}'
 id='stemp1' size='8' ></td>
<td><INPUT TYPE='text' NAME='stemp2' VALUE='$pgraphsset{"sensors_temp2_show"}'
 id='stemp2' size='8' ></td>
<td><INPUT TYPE='text' NAME='stemp3' VALUE='$pgraphsset{"sensors_temp3_show"}'
 id='stemp3' size='8' ></td>
<td><INPUT TYPE='text' NAME='stemp4' VALUE='$pgraphsset{"sensors_temp4_show"}'
 id='stemp4' size='8' ></td>
<td><INPUT TYPE='text' NAME='stemp5' VALUE='$pgraphsset{"sensors_temp5_show"}'
 id='stemp5' size='8' ></td>
<td><INPUT TYPE='text' NAME='stemp6' VALUE='$pgraphsset{"sensors_temp6_show"}'
 id='stemp6' size='8' ></td>
<td><INPUT TYPE='text' NAME='stemp7' VALUE='$pgraphsset{"sensors_temp7_show"}'
 id='stemp7' size='8' ></td>
</tr>
<tr>
<td>Voltages</td>
<td align='center'>volt1</td>
<td align='center'>volt2</td>
<td align='center'>volt3</td>
<td align='center'>volt4</td>
<td align='center'>volt5</td>
<td align='center'>volt6</td>
<td align='center'>volt7</td>
<td align='center'>volt8</td>
<td align='center'>volt9</td>
</tr>
<tr>
<td align='right'>find:</td>
<td><INPUT TYPE='text' NAME='fvolt1' VALUE='$pgraphsset{"sensors_volt1_find"}'
 id='fvolt1' size='8' ></td>
<td><INPUT TYPE='text' NAME='fvolt2' VALUE='$pgraphsset{"sensors_volt2_find"}'
 id='fvolt2' size='8' ></td>
<td><INPUT TYPE='text' NAME='fvolt3' VALUE='$pgraphsset{"sensors_volt3_find"}'
 id='fvolt3' size='8' ></td>
<td><INPUT TYPE='text' NAME='fvolt4' VALUE='$pgraphsset{"sensors_volt4_find"}'
 id='fvolt4' size='8' ></td>
<td><INPUT TYPE='text' NAME='fvolt5' VALUE='$pgraphsset{"sensors_volt5_find"}'
 id='fvolt5' size='8' ></td>
<td><INPUT TYPE='text' NAME='fvolt6' VALUE='$pgraphsset{"sensors_volt6_find"}'
 id='fvolt6' size='8' ></td>
<td><INPUT TYPE='text' NAME='fvolt7' VALUE='$pgraphsset{"sensors_volt7_find"}'
 id='fvolt7' size='8' ></td>
<td><INPUT TYPE='text' NAME='fvolt8' VALUE='$pgraphsset{"sensors_volt8_find"}'
 id='fvolt8' size='8' ></td>
<td><INPUT TYPE='text' NAME='fvolt9' VALUE='$pgraphsset{"sensors_volt9_find"}'
 id='fvolt9' size='8' ></td>
</tr>
<tr>
<td align='right'>show:</td>
<td><INPUT TYPE='text' NAME='svolt1' VALUE='$pgraphsset{"sensors_volt1_show"}'
 id='svolt1' size='8' ></td>
<td><INPUT TYPE='text' NAME='svolt2' VALUE='$pgraphsset{"sensors_volt2_show"}'
 id='svolt2' size='8' ></td>
<td><INPUT TYPE='text' NAME='svolt3' VALUE='$pgraphsset{"sensors_volt3_show"}'
 id='svolt3' size='8' ></td>
<td><INPUT TYPE='text' NAME='svolt4' VALUE='$pgraphsset{"sensors_volt4_show"}'
 id='svolt4' size='8' ></td>
<td><INPUT TYPE='text' NAME='svolt5' VALUE='$pgraphsset{"sensors_volt5_show"}'
 id='svolt5' size='8' ></td>
<td><INPUT TYPE='text' NAME='svolt6' VALUE='$pgraphsset{"sensors_volt6_show"}'
 id='svolt6' size='8' ></td>
<td><INPUT TYPE='text' NAME='svolt7' VALUE='$pgraphsset{"sensors_volt7_show"}'
 id='svolt7' size='8' ></td>
<td><INPUT TYPE='text' NAME='svolt8' VALUE='$pgraphsset{"sensors_volt8_show"}'
 id='svolt8' size='8' ></td>
<td><INPUT TYPE='text' NAME='svolt9' VALUE='$pgraphsset{"sensors_volt9_show"}'
 id='svolt9' size='8' ></td>
</tr>
</table>
ENDX
           ;
	print <<END
<table class='blank'>
<tr>
<td style='text-align: center; width: 50%;'><input type='submit' name='ACTION' value='Save'></td>
<td style='text-align: center; width: 50%;'><input type='submit' name='ACTION' value='Save and Hide'></td>
</tr>
</table>
</form>
END
	   ;
	}	
	&closebox();
}

&alertbox('add','add');
&closebigbox();
&closepage();

sub get_dns_settings {
        $dnssettings{'DNS1'} = '';
        $dnssettings{'DNS2'} = '';
        $dnssettings{'DNS3'} = '';
        $dnssettings{'DNS4'} = '';

        &readhash("${swroot}/ethernet/settings", \%ethersettings );

	# Try to find dns addresses using dhcpd red settings file 
	# (seems to only work with cable)
        &red_dhcp_red;
        # Try to find dns addresses using PPPoE
        if ($ethersettings{'RED_TYPE'} eq "PPPOE") {
		&read_pppoe;
	}
	# Try to find dns addresses using ethernet settings 
	# (haven't seen this work with cable)
        if ($dnssettings{'DNS1'} eq "" && $dnssettings{'DNS2'} eq "") {
		&read_ethernet_dns;
	}
	#Try to find dns addresses using red dir
	#(seems to work with everything)
        if ($dnssettings{'DNS1'} eq "" && $dnssettings{'DNS2'} eq "") {
                &read_red_dns;
        }
}

sub red_dhcp_red {
        my %dhcpinfo;
	if ( -r "/var/lib/dhcpc/dhcpcd-$ethersettings{'RED_DEV'}.info" ) {
        	&readhash("/var/lib/dhcpc/dhcpcd-$ethersettings{'RED_DEV'}.info", \%dhcpinfo);
	}
	if ($mydns[0]) {
	       $dnssettings{'DNS1'} = $mydns[0];
	       $dnssettings{'DNS2'} = $mydns[1];
	       $dnssettings{'DNS3'} = $mydns[2];
	       $dnssettings{'DNS4'} = $mydns[3];
	}
}

sub read_pppoe {
	my %pppsettings;
	if ( -r "${swroot}/ppp/settings-1" ) {
		&readhash("${swroot}/ppp/settings-1", \%pppsettings);
	}
	$dnssettings{'DNS1'} = $pppsettings{'DNS1'};
	$dnssettings{'DNS2'} = $pppsettings{'DNS2'};
}

sub read_ethernet_dns {
	$dnssettings{'DNS1'} = $ethersettings{'DNS1'};
	$dnssettings{'DNS2'} = $ethersettings{'DNS2'};
}


sub read_red_dns {
	if ( -r "${swroot}/red/dns1" ) {
		open(FILE, "${swroot}/red/dns1");
		$dnssettings{'DNS1'} = <FILE>;
		close(FILE);
	}
	if ( -r "${swroot}/red/dns2" ) {
		open(FILE, "${swroot}/red/dns2");
		$dnssettings{'DNS2'} = <FILE>;
		close(FILE);
	}	
}	

sub get_traceroute {
   if (-e "${swroot}/red/active") {
	# I use one of www.opendns.com nameservers here as it should be
	# available at all times and they encourage free access
	# we have to do a ping first in case there is no routing from red
	# or we hang here for ages. Can't use fping as not root so we ping
	# fping -C1 -t2000 -q -e 208.67.222.222
	my $doit = 0;
	open(PING, "ping -n -q -c1 -W3 208.67.222.222 2>&1 | ");
	while(<PING>) {
	        my $reply = $_;
		chomp($reply);
		if ( $reply =~ /packet loss/ ) {
			my @fields = split(/ +/,$reply);
			if ( $fields[5] eq "0%" ) { $doit = 1 }
		}
	}
	close(PING);	
	if ( $doit == 1 ) {
		open(ROUT,"/bin/traceroute -n -m 5 -q 2 -w 2 208.67.222.222 2>/dev/null |");
		my $n=0;
		while(<ROUT>) {
			$n++;
			chomp;
			my ($hopn,$ip,$r1,$ms1,$r2,$ms2,$r3,$ms3) = split;
			$hop{$n}=$ip;
		}   
		close(ROUT);
	}
   }
}

sub xpush() {
	# push the graph name onto the graphs array if it is not already there
	my $yes = 0;
	for ($count=0; $count < (scalar @graphs) ; $count++) {
		if ( $_[0] eq $graphs[$count] ) {
			$yes = 1;
		}
	}	
    	if ($yes == 0 ) {
		push(@graphs,$_[0]);
	}
}

sub read_prefs_file() {
	if ( -r $prefs_file ) {
		&readhash($prefs_file, \%pgraphsset);
	} else { 
		$bad_prefs = "Unable to open $prefs_file for reading";
	}
}

sub write_prefs_file() {
	if ( -w $prefs_file ) {
		open(FILE, ">${prefs_file}");
		flock FILE, 2;
		foreach $var (sort keys %pgraphsset) {
			$val = $pgraphsset{$var};
			$val = "\'$val\'";
			print FILE "${var}=${val}\n";
		}
		close FILE;
	} else { 
		$bad_prefs = "Unable to open $prefs_file for writing";
	}
}

sub get_prefs_from_cgi() {
     if (($cgiparams{'ACTION'} eq "Save and Hide" ) or
	    ($cgiparams{'ACTION'} eq "Save" )          ) {
	    if ($cgiparams{'showupdatedtime'} eq "on" ) {
	         $pgraphsset{'showupdatedtime'} = "Y";   
	    } else {
	         $pgraphsset{'showupdatedtime'} = "N";   
	   }
           foreach $graphname (@graphs) {
              my $dbname = (substr($graphname,0,index($graphname,"-")));
	      if ($cgiparams{$dbname.'_collect'} eq "on" ) {
	         $pgraphsset{$dbname.'_collect'} = "Y";   
      	      } else {
	         $pgraphsset{$dbname.'_collect'} = "N";   
	      }
	      if ($cgiparams{$dbname.'_show'} eq "on" ) {
	         $pgraphsset{$dbname.'_show'} = "Y";   
      	      } else {
	         $pgraphsset{$dbname.'_show'} = "N";   
	      }
	   }
	   
	   $pgraphsset{'target_1'} = $cgiparams{'target1'};
	   $pgraphsset{'target_2'} = $cgiparams{'target2'};
	   $pgraphsset{'target_3'} = $cgiparams{'target3'};
	   $pgraphsset{'target_4'} = $cgiparams{'target4'};

	   $pgraphsset{'graphorder'} = $cgiparams{'graphorder'};

	   &set_graph_order;
	   
	   if ($cgiparams{'ACTION'} eq "Save and Hide" ) {
		$pgraphsset{'customise_open'} = "N";
	   }	

	   foreach $sen (
   'fan1','fan2','fan3','fan4','fan5','fan6','fan7',
   'temp1','temp2','temp3','temp4','temp5','temp6','temp7',
   'volt1','volt2','volt3','volt4','volt5','volt6','volt7','volt8','volt9'
	                ) {
	      if ("$cgiparams{'f'.$sen}" eq "") {
	         delete $pgraphsset{'sensors_'.$sen.'_find'}; 
	      } else {
	     	 $pgraphsset{'sensors_'.$sen.'_find'} = $cgiparams{'f'.$sen};
	      }
	      if ("$cgiparams{'s'.$sen}" eq "") {
	         delete $pgraphsset{'sensors_'.$sen.'_show'}; 
	      } else {
	     	 $pgraphsset{'sensors_'.$sen.'_show'} = $cgiparams{'s'.$sen};
	      }
	   }
	   &write_prefs_file() ;
     }
     if ($cgiparams{'ACTION'} eq "Customise" ) {
	   $pgraphsset{'customise_open'} = "Y";
	   &write_prefs_file() ;
     }
}	


sub set_prefs_default() {
	# customise is closed by default
	$pgraphsset{'customise_open'} = 'N';
        
	# no graph order defined so will revert to defaults
	$pgraphsset{'graphorder'} = '';

	# show the list of timestamps of the .png and rrd files 
	$pgraphsset{'showupdatedtime'} = 'Y';

	# turn all collection and graphs on 
	while ( my ($key, $value) = each(%cron) ) {
		# the keys are the graphnames
		$pgraphsset{$key."_collect"} = 'Y';
		$pgraphsset{$key."_show"} = 'Y';
    	}
	# but some graphs are off by default and are not collected 
        $pgraphsset{'mem_collect'} = 'N';
        $pgraphsset{'mem_show'} = 'N';
        $pgraphsset{'squid_collect'} = 'N';
        $pgraphsset{'squid_show'} = 'N';
        $pgraphsset{'ping_collect'} = 'N';
        $pgraphsset{'ping_show'} = 'N';
        $pgraphsset{'red_avail_collect'} = 'N';
        $pgraphsset{'red_avail_show'} = 'N';
        $pgraphsset{'uptimemax_collect'} = 'N';
        $pgraphsset{'uptimemax_show'} = 'N';
        $pgraphsset{'disk_used_collect'} = 'N';
        $pgraphsset{'disk_used_show'} = 'N';
        $pgraphsset{'inodes_used_collect'} = 'N';
        $pgraphsset{'inodes_used_show'} = 'N';
}

sub setup_cron_rrd_desc() {
# adding a new graph requires 
# an entry in the configa array below 
# an entry in set_graph_order to say where it appears
# an entry in set_prefs_default to set it on or off by default
#
# in the array below data is in groups of 4 and the columns refer to
#  graph          cronscript    rrd              description
#  =====          ====          ===              ====
	@configa = (
'connections'   ,'conntrack'  ,'connections'   ,'Masqueraded and Direct connections',
'cpu'           ,'perf'       ,'cpu'           ,'CPU load',
'disk_bytes'    ,'disk'       ,'disk_bytes'    ,'Disk activity bytes',
'disk_io'       ,'disk'       ,'disk_io'       ,'Disk activity ios',
'disk_used'     ,'diskused'   ,'disk_used'     ,'Filesystem space usage',
'diskx_bytes'   ,'diskx'      ,'diskx_bytes'   ,'Disk filesystem bytes',
'diskx_io'      ,'diskx'      ,'diskx_io'      ,'Disk filesystem ios',
'fan'           ,'fan'        ,'fan'           ,'Fan Speed',
'firewall'      ,'firewall'   ,'firewall'      ,'Firewall hits',
'hddtemp'       ,'hddtemp'    ,'hddtemp'       ,'Hard Disk temperature',
'inodes_used'   ,'diskused'   ,'inodes_used'   ,'Filesystem inodes usage',
'load'          ,'perf'       ,'load'          ,'Load average',
'mem'           ,'perf'       ,'mem'           ,'Memory usage',
'memoryx'       ,'memoryx'    ,'memoryx'       ,'Detailed memory usage', 
'ping'          ,'ping'       ,'ping'          ,'Ping times', 
'red_avail'     ,'ping'       ,'red_avail'     ,'Red side availability',
'squid'         ,'squid'      ,'squid'         ,'Squid Web Proxy cache', 
'squid_cache'   ,'squidx'     ,'squid_cache'   ,'Squid activity',
'squid_cache2'  ,'squidx'     ,'squid_cache'   ,'Squid requests',
'squid_cache3'  ,'squidx'     ,'squid_cache'   ,'Squid bytes', 
'squid_memory'  ,'squidx'     ,'squid_memory'  ,'Squid memory', 
'squid_paging'  ,'squidx'     ,'squid_paging'  ,'Squid paging', 
'squid_response','squidx'     ,'squid_response','Squid response',
'temperature'   ,'temperature','temperature'   ,'System temperatures',
'uptime'        ,'uptime'     ,'uptime2'       ,'System uptime',
'uptimemax'     ,'uptime'     ,'uptimemax'     ,'Max System uptime',
'voltage'       ,'voltage'    ,'voltage'       ,'System voltages',
);

for ($count=0; $count < ((scalar @configa)/4) ; $count++) {
	$cron{$configa[$count*4]}    = $configa[$count*4+1] ;
        $rrd{ $configa[$count*4]}    = $configa[$count*4+2] ;
        $desc{$configa[$count*4]}    = $configa[$count*4+3] ;
}

sub set_graph_order() {
	my $xx =  $pgraphsset{'graphorder'};
	undef (@graphs);
	while($xx =~ /([^:]+):?/g) {
     		push(@graphs,$1."-day");
	}
# This sets the default order in which the graphs appear on the main page
# rearrange this if needed
	&xpush ( 'firewall-day'       );
	&xpush ( 'connections-day'    );
	&xpush ( 'mem-day'            );
	&xpush ( 'memoryx-day'        );
	&xpush ( 'load-day'           );
	&xpush ( 'cpu-day'            );
	&xpush ( 'disk_io-day'        );
	&xpush ( 'disk_bytes-day'     );
	&xpush ( 'diskx_io-day'       );
	&xpush ( 'diskx_bytes-day'    );
	&xpush ( 'disk_used-day'      );
	&xpush ( 'inodes_used-day'    );
	&xpush ( 'hddtemp-day'        );
	&xpush ( 'temperature-day'    );
	&xpush ( 'voltage-day'        );
	&xpush ( 'fan-day'            );
	&xpush ( 'squid-day'          );
	&xpush ( 'squid_cache-day'    );
	&xpush ( 'squid_cache2-day'   );
	&xpush ( 'squid_cache3-day'   );
	&xpush ( 'squid_response-day' );
	&xpush ( 'squid_memory-day'   );
	&xpush ( 'squid_paging-day'   );
	&xpush ( 'uptime-day'         );
	&xpush ( 'uptimemax-day'      );
	&xpush ( 'red_avail-day'      );
	&xpush ( 'ping-day'           );
}

}
