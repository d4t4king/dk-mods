#!/usr/bin/perl
# use strict 
# 
# SmoothWall  
# 
# This code is distributed under the terms of the GPL 
# 
# (c) The SmoothWall Team 
#
# this code can take a parameter - pass 1 to trace matches, 2 for full debug
#
 
use IO::Socket::INET; 

#require '/var/smoothwall/header.pl';
use lib "/usr/lib/smoothwall";
use header qw( :standard );
my $debug =  (scalar @ARGV > 0);
my $diskmax;

# define location of rrdtool binary
my $rrdtool = '/usr/bin/rrdtool';

# define location of rrdtool databases
my $rrd = '/var/lib/rrd';
my $dbname1 = 'squid_cache';
my $dbname2 = 'squid_response';
my $dbname3 = 'squid_memory';
my $dbname4 = 'squid_paging';

# define location of images
my $img = '/httpd/html/rrdtool';
my $imgname11 = 'squid_cache';
my $imgname12 = 'squid_cache2';
my $imgname13 = 'squid_cache3';
my $imgname21 = 'squid_response';
my $imgname31 = 'squid_memory';
my $imgname41 = 'squid_paging';

# stored preferences
my $swroot = '/var/smoothwall';
my $prefs_file = "${swroot}/mods/pgraphs/preferences/stored";
my %pgraphsset;
$pgraphsset{"squid_cache_collect"} = 'Y';
$pgraphsset{"squid_cache2_collect"} = 'Y';
$pgraphsset{"squid_cache3_collect"} = 'Y';
$pgraphsset{"squid_memory_collect"} = 'Y';
$pgraphsset{"squid_paging_collect"} = 'Y';
$pgraphsset{"squid_response_collect"} = 'Y';
&read_prefs($prefs_file, \%pgraphsset);

if (
     ( $pgraphsset{"squid_cache_collect"} eq "Y" ) ||
     ( $pgraphsset{"squid_cache2_collect"} eq "Y" ) ||
     ( $pgraphsset{"squid_cache3_collect"} eq "Y" ) ||
     ( $pgraphsset{"squid_response_collect"} eq "Y" ) ||
     ( $pgraphsset{"squid_memory_collect"} eq "Y" ) ||
     ( $pgraphsset{"squid_paging_collect"} eq "Y" ) 
                                                       )  {

#define the port that squid uses, Smoothwall defaults to 800
my $host;
my $port; 

my %netsettings;
my $sock; 
my ($reqtot, $reqhit, $bytetot, $bytehit, $disku, $bytesrv);
my ($allmedsvc, $dnsmedsvc);
my ($memacc, $memtot,  $pagef );

&readhash("${swroot}/ethernet/settings", \%netsettings);
$host = $netsettings{'GREEN_ADDRESS'};

my $proxy_conf=`cat /var/smoothwall/proxy/squid.conf | grep 'http_port'`;
print "squid.conf says - ".$proxy_conf;
# ignore that for now - always use 800
$port = '800' ; 

print "Trying to connect to Squid on $host:$port\n"; 

if ( ( $pgraphsset{"squid_cache_collect"} eq "Y" ) ||
     ( $pgraphsset{"squid_cache2_collect"} eq "Y" ) ||
     ( $pgraphsset{"squid_cache3_collect"} eq "Y" ) ) {
#counters
if ( ! ($sock = new IO::Socket::INET (PeerAddr => "$host", PeerPort => "$port", Proto => 'tcp', Timeout => 5))) { 
   print "Unable to connect to Squid\n"; 
} else { 
   print $sock "GET cache_object://$host/counters HTTP/1.0\r\n\r\n"; 
   while (<$sock>) 
   { 
      &debugprint(2, "raw:" .$_); 
      &check_for($_, "client_http\.requests",       "=\ ", "\$", \$reqtot);
      &check_for($_, "client_http\.hits",           "=\ ", "\$", \$reqhit );
      &check_for($_, "client_http\.kbytes_out",     "=\ ", "\$", \$bytetot);
      &check_for($_, "client_http\.hit_kbytes_out", "=\ ", "\$", \$bytehit );
      &check_for($_, "server\.all\.kbytes_in",      "=\ ", "\$", \$bytesrv );
   } 
   print "Requests total = $reqtot\n";
   print "Request from cache = $reqhit\n";
   print "kBytes total = $bytetot\n";
   print "kBytes from cache = $bytehit\n";
   print "kBytes from server = $bytesrv\n";
}

#storedir
if ( ! ($sock = new IO::Socket::INET (PeerAddr => "$host", PeerPort => "$port", Proto => 'tcp', Timeout => 5))) { 
   print "Unable to connect to Squid\n"; 
} else {
   print $sock "GET cache_object://$host/storedir HTTP/1.0\r\n\r\n";
   while (<$sock>) 
   { 
      &debugprint(2, "raw:" .$_); 
      &check_for($_, "Current Capacity",  ":\ ", "\%",   \$disku   );
      &check_for($_, "Maximum Swap Size", ":\ ", "\ KB", \$diskmax );
   } 
   $diskmax = $diskmax / 1024;
   print "Disk Cache use percent = $disku\n";
   print "Disk Cache size = $diskmax\n";
}

# if rrdtool databases don't exist, create them
if (! -e "$rrd/$dbname1.rrd")
{
        print "creating rrd database $rrd/$dbname1.rrd for squid...\n";
        system("$rrdtool create $rrd/$dbname1.rrd -s 300"
                ." DS:reqtot:DERIVE:600:0:100000"
                ." DS:bytetot:DERIVE:600:0:100000"
                ." DS:reqhit:DERIVE:600:0:100000"
                ." DS:bytehit:DERIVE:600:0:100000"
                ." DS:bytesrv:DERIVE:600:0:100000"
                ." DS:vdisku:GAUGE:600:0:100"
                ." RRA:AVERAGE:0.5:1:576"
                ." RRA:AVERAGE:0.5:6:672"
                ." RRA:AVERAGE:0.5:24:732"
                ." RRA:AVERAGE:0.5:144:1460");
}

if ($reqtot < 0) {$reqtot = 0}
if ($reqhit < 0) {$reqhit = 0}
if ($bytetot < 0) {$bytetot = 0}
if ($bytehit < 0) {$bytehit = 0}
if ($bytesrv < 0) {$bytesrv = 0}

# insert values into rrd
`$rrdtool update $rrd/$dbname1.rrd -t reqtot:reqhit:bytetot:bytehit:bytesrv:vdisku N:$reqtot:$reqhit:$bytetot:$bytehit:$bytesrv:$disku`;
&debugprint(2, "$rrdtool update $rrd/$dbname1.rrd -t reqtot:reqhit:bytetot:bytehit:bytesrv:vdisku N:$reqtot:$reqhit:$bytetot:$bytehit:$bytesrv:$disku\n"); 

}

if ( $pgraphsset{"squid_response_collect"} eq "Y" ) {
#5min
if ( ! ($sock = new IO::Socket::INET (PeerAddr => "$host", PeerPort => "$port", Proto => 'tcp', Timeout => 5))) { 
   print "Unable to connect to Squid\n"; 
} else {
   print $sock "GET cache_object://$host/5min HTTP/1.0\r\n\r\n";
   while (<$sock>) 
   { 
      &debugprint(2, "raw:" .$_); 
      &check_for($_, "client_http\.all_median_svc_time", "=\ ", "\ seconds", \$allmedsvc );
      &check_for($_, "dns\.median_svc_time", "=\ ", "\ seconds", \$dnsmedsvc );
   } 
   print "All median service time = $allmedsvc\n";
   print "DNS median service time = $dnsmedsvc\n";
}

# if rrdtool databases don't exist, create them
if (! -e "$rrd/$dbname2.rrd")
{
        print "creating rrd database $rrd/$dbname2.rrd for squid...\n";
        system("$rrdtool create $rrd/$dbname2.rrd -s 300"
                ." DS:allmedsvc:GAUGE:600:0:10"
                ." DS:dnsmedsvc:GAUGE:600:0:10"
                ." RRA:AVERAGE:0.5:1:576"
                ." RRA:AVERAGE:0.5:6:672"
                ." RRA:AVERAGE:0.5:24:732"
                ." RRA:AVERAGE:0.5:144:1460");
}
# insert values into rrd
`$rrdtool update $rrd/$dbname1.rrd -t reqtot:reqhit:bytetot:bytehit:bytesrv:vdisku N:$reqtot:$reqhit:$bytetot:$bytehit:$bytesrv:$disku`;
`$rrdtool update $rrd/$dbname2.rrd -t allmedsvc:dnsmedsvc N:$allmedsvc:$dnsmedsvc`;
&debugprint(2, "$rrdtool update $rrd/$dbname2.rrd -t allmedsvc:dnsmedsvc N:$allmedsvc:$dnsmedsvc\n"); 
}

if ( ( $pgraphsset{"squid_memory_collect"} eq "Y" ) ||
     ( $pgraphsset{"squid_paging_collect"} eq "Y" ) ) {
#info
if ( ! ($sock = new IO::Socket::INET (PeerAddr => "$host", PeerPort => "$port", Proto => 'tcp', Timeout => 5))) { 
   print "Unable to connect to Squid\n"; 
} else {
   print $sock "GET cache_object://$host/info HTTP/1.0\r\n\r\n";
   while (<$sock>) 
   { 
      &debugprint(2, "raw:" .$_); 
      &check_for($_, "Total accounted:", ":\ ", "\ KB", \$memacc );
      &check_for($_, "Total space in arena:", ":\ ", "\ KB", \$memtot );
      &check_for($_, "Page faults with physical i\/o:", ":\ ", "\$", \$pagef );
   } 
   $memacc = $memacc / 1024;
   $memtot = $memtot / 1024;
   print "Total Accounted Memory = $memacc\n";
   print "Total space in arena = $memtot\n";
   print "Page faults with physical io = $pagef\n";
}

if ( $pgraphsset{"squid_memory_collect"} eq "Y" ) { 
# if rrdtool databases don't exist, create them
if (! -e "$rrd/$dbname3.rrd")
{
        print "creating rrd database $rrd/$dbname3.rrd for squid...\n";
        system("$rrdtool create $rrd/$dbname3.rrd -s 300"
                ." DS:memacc:GAUGE:600:0:10000"
                ." DS:memtot:GAUGE:600:0:10000"
                ." RRA:AVERAGE:0.5:1:576"
                ." RRA:AVERAGE:0.5:6:672"
                ." RRA:AVERAGE:0.5:24:732"
                ." RRA:AVERAGE:0.5:144:1460");
}
# insert values into rrd
`$rrdtool update $rrd/$dbname1.rrd -t reqtot:reqhit:bytetot:bytehit:bytesrv:vdisku N:$reqtot:$reqhit:$bytetot:$bytehit:$bytesrv:$disku`;
`$rrdtool update $rrd/$dbname3.rrd -t memacc:memtot N:$memacc:$memtot`;
&debugprint(2, "$rrdtool update $rrd/$dbname3.rrd -t memacc:memtot N:$memacc:$memtot\n"); 
}

if ( $pgraphsset{"squid_response_collect"} eq "Y" ) { 
if (! -e "$rrd/$dbname4.rrd")
{
        print "creating rrd database $rrd/$dbname4.rrd for squid...\n";
        system("$rrdtool create $rrd/$dbname4.rrd -s 300"
                ." DS:pagef:DERIVE:600:0:100000"
                ." RRA:AVERAGE:0.5:1:576"
                ." RRA:AVERAGE:0.5:6:672"
                ." RRA:AVERAGE:0.5:24:732"
                ." RRA:AVERAGE:0.5:144:1460");
}
`$rrdtool update $rrd/$dbname4.rrd -t pagef N:$pagef`;
# insert values into rrd
`$rrdtool update $rrd/$dbname1.rrd -t reqtot:reqhit:bytetot:bytehit:bytesrv:vdisku N:$reqtot:$reqhit:$bytetot:$bytehit:$bytesrv:$disku`;
&debugprint(2, "$rrdtool update $rrd/$dbname4.rrd -t pagef N:$pagef\n");
}

}

close($sock);   

# create squid graphs
&CreateGraphSquid("day");
&CreateGraphSquid("week");
&CreateGraphSquid("month");
&CreateGraphSquid("year");

} else {
        print "squidx is not collecting anything at present\n";
}

sub read_prefs
{
        my $filename = $_[0];
        my $hash = $_[1];
        my ($var, $val);
        if ( -r $filename ) {
                open(FILE, $filename);
                while (<FILE>) {
                        chomp;
                        ($var, $val) = split /=/, $_, 2;
                        if ($var) {
                                $val =~ s/^\'//g;
                                $val =~ s/\'$//g;
                                $hash->{$var} = $val;
                        }
                }
                close FILE;
        }
}

sub CreateGraphSquid
{
# creates graph
# inputs: $_[0]: interval (ie, day, week, month, year)

     if ( $pgraphsset{"squid_cache_collect"} eq "Y" ) {
        &debugprint(3, "$img/$imgname11-$_[0]\n");
        system("$rrdtool graph $img/$imgname11-$_[0].png"
                ." -s \"-1$_[0]\""
                ." -t \"Squid activity over the last $_[0]\""
                ." --lazy"
                ." -h 100 -w 500"
                ." -l 0 -u 100 -r --units-exponent 0"
                ." -a PNG"
                ." -v \"percent\""
                ." DEF:vreqtot=$rrd/$dbname1.rrd:reqtot:AVERAGE"
                ." DEF:vbytetot=$rrd/$dbname1.rrd:bytetot:AVERAGE"
                ." DEF:vreqhit=$rrd/$dbname1.rrd:reqhit:AVERAGE"
                ." DEF:vbytehit=$rrd/$dbname1.rrd:bytehit:AVERAGE"
                ." DEF:vbytesrv=$rrd/$dbname1.rrd:bytesrv:AVERAGE"
                ." DEF:vdisku=$rrd/$dbname1.rrd:vdisku:AVERAGE"
                ." CDEF:reqhit=vreqhit,vreqtot,/,100,*"
                ." CDEF:byterat=vbytehit,vbytehit,vbytesrv,+,/,100,*"
                ." CDEF:bytegra=vbytehit,vbytesrv,+,"
		      ."vbytehit,vbytehit,vbytesrv,+,/,"
                      ."0,IF,100,*"
                ." LINE2:vdisku#5447A2:\"% Disk cache in use  \""
                ." GPRINT:vdisku:MAX:\" Max\\: %5.1lf\""
                ." GPRINT:vdisku:AVERAGE:\" Avg\\: %5.1lf\""
                ." GPRINT:vdisku:LAST:\" Current\\: %5.1lf %% of $diskmax"
                        ."MB\\n\""
                ." LINE2:reqhit#FFCC66:\"% Requests from cache\""
                ." GPRINT:reqhit:MAX:\" Max\\: %5.1lf\""
                ." GPRINT:reqhit:AVERAGE:\" Avg\\: %5.1lf\""
                ." GPRINT:reqhit:LAST:\" Current\\: %5.1lf %%\\n\""
                ." LINE2:bytegra#FF9900:\"% Bytes from cache   \""
                ." GPRINT:byterat:MAX:\" Max\\: %5.1lf\""
                ." GPRINT:byterat:AVERAGE:\" Avg\\: %5.1lf\""
                ." GPRINT:byterat:LAST:\" Current\\: %5.1lf %%\""
                );
     }

     if ( $pgraphsset{"squid_cache2_collect"} eq "Y" ) {
        &debugprint(3, "$img/$imgname12-$_[0]\n");
        system("$rrdtool graph $img/$imgname12-$_[0].png"
                ." -s \"-1$_[0]\""
                ." -t \"Squid requests served over the last $_[0]\""
                ." --lazy"
                ." -h 100 -w 500"
                ." -l 0"
                ." -a PNG"
                ." -v \"requests/sec\""
                ." DEF:vreqtot=$rrd/$dbname1.rrd:reqtot:AVERAGE"
                ." DEF:vreqhit=$rrd/$dbname1.rrd:reqhit:AVERAGE"
                ." CDEF:reqtot=vreqtot"
                ." CDEF:reqhit=vreqhit"
                ." LINE2:reqtot#FF9900:\"Requests total     \""
                ." GPRINT:reqtot:MAX:\" Max\\: %6.1lf\""
                ." GPRINT:reqtot:AVERAGE:\" Avg\\: %6.1lf\""
                ." GPRINT:reqtot:LAST:\" Current\\: %6.1lf /sec\\n\""
                ." LINE2:reqhit#FFCC66:\"Requests from cache\""
                ." GPRINT:reqhit:MAX:\" Max\\: %6.1lf\""
                ." GPRINT:reqhit:AVERAGE:\" Avg\\: %6.1lf\""
                ." GPRINT:reqhit:LAST:\" Current\\: %6.1lf /sec\""
                );
     }

     if ( $pgraphsset{"squid_cache3_collect"} eq "Y" ) {
	&debugprint(3, "$img/$imgname13-$_[0]\n");
        system("$rrdtool graph $img/$imgname13-$_[0].png"
                ." -s \"-1$_[0]\""
                ." -t \"Squid bytes served over the last $_[0]\""
                ." --lazy"
                ." -h 100 -w 500"
                ." -l 0"
                ." -a PNG"
                ." -v \"bytes/sec\""
                ." DEF:vbytetot=$rrd/$dbname1.rrd:bytetot:AVERAGE"
                ." DEF:vbytehit=$rrd/$dbname1.rrd:bytehit:AVERAGE"
                ." DEF:vbytesrv=$rrd/$dbname1.rrd:bytesrv:AVERAGE"
                ." CDEF:bytetot=vbytetot,1024,*"
                ." CDEF:bytehit=vbytehit,1024,*"
                ." CDEF:bytesrv=vbytesrv,1024,*"
#               ." CDEF:bytesum=vbytesrv,vbytehit,+,1024,*"
                ." LINE2:bytetot#006600:\"bytes to clients \""
                ." GPRINT:bytetot:MAX:\" Max\\: %5.1lf %s\""
                ." GPRINT:bytetot:AVERAGE:\" Avg\\: %5.1lf %S\""
                ." GPRINT:bytetot:LAST:\" Current\\: %5.1lf %Sbytes/sec\\n\""
                ." LINE2:bytesrv#FF9900:\"bytes from red   \""
                ." GPRINT:bytesrv:MAX:\" Max\\: %5.1lf %s\""
                ." GPRINT:bytesrv:AVERAGE:\" Avg\\: %5.1lf %S\""
                ." GPRINT:bytesrv:LAST:\" Current\\: %5.1lf %Sbytes/sec\\n\""
                ." LINE2:bytehit#FFCC66:\"bytes from cache \""
                ." GPRINT:bytehit:MAX:\" Max\\: %5.1lf %s\""
                ." GPRINT:bytehit:AVERAGE:\" Avg\\: %5.1lf %S\""
                ." GPRINT:bytehit:LAST:\" Current\\: %5.1lf %Sbytes/sec\""
                );
     }

     if ( $pgraphsset{"squid_response_collect"} eq "Y" ) {
	&debugprint(3, "$img/$imgname21-$_[0]\n");
        system("$rrdtool graph $img/$imgname21-$_[0].png"
                ." -s \"-1$_[0]\""
                ." -t \"Squid response over the last $_[0]\""
                ." --lazy"
                ." -h 100 -w 500"
                ." -l 0"
                ." -a PNG"
                ." -v \"seconds\""
                ." DEF:all=$rrd/$dbname2.rrd:allmedsvc:AVERAGE"
                ." DEF:dns=$rrd/$dbname2.rrd:dnsmedsvc:AVERAGE"
                ." AREA:all#FFCC66:\"All median service time\""
                ." GPRINT:all:MAX:\" Max\\: %5.1lf %s\""
                ." GPRINT:all:AVERAGE:\" Avg\\: %5.1lf %S\""
                ." GPRINT:all:LAST:\" Current\\: %5.1lf %Ssec\\n\""
                ." AREA:dns#FF9900:\"DNS median service time\""
                ." GPRINT:dns:MAX:\" Max\\: %5.1lf %s\""
                ." GPRINT:dns:AVERAGE:\" Avg\\: %5.1lf %S\""
                ." GPRINT:dns:LAST:\" Current\\: %5.1lf %Ssec\""
                ." LINE1:all#CC9966"
                ." LINE1:dns#CC6600"
                );
     }

     if ( $pgraphsset{"squid_memory_collect"} eq "Y" ) {
	&debugprint(3, "$img/$imgname31-$_[0]\n");
        system("$rrdtool graph $img/$imgname31-$_[0].png"
                ." -s \"-1$_[0]\""
                ." -t \"Squid memory over the last $_[0]\""
                ." --lazy"
                ." -h 100 -w 500"
                ." -l 0"
                ." -a PNG"
                ." -v \"Megabytes\""
                ." DEF:acc=$rrd/$dbname3.rrd:memacc:AVERAGE"
                ." DEF:tot=$rrd/$dbname3.rrd:memtot:AVERAGE"
                ." CDEF:base=tot,acc,-"
                ." AREA:base#FF9900:\"Overhead \""
                ." GPRINT:base:MAX:\" Max\\: %5.1lf %s\""
                ." GPRINT:base:AVERAGE:\" Avg\\: %5.1lf %S\""
                ." GPRINT:base:LAST:\" Current\\: %5.1lf %SMB\\n\""
                ." STACK:acc#FFCC66:\"Accounted\""
                ." GPRINT:acc:MAX:\" Max\\: %5.1lf %s\""
                ." GPRINT:acc:AVERAGE:\" Avg\\: %5.1lf %S\""
                ." GPRINT:acc:LAST:\" Current\\: %5.1lf %SMB\\n\""
                ." GPRINT:tot:MAX:\"  Total    "
                ."   Max\\: %5.1lf %s\""
                ." GPRINT:tot:AVERAGE:\" Avg\\: %5.1lf %S\""
                ." GPRINT:tot:LAST:\" Current\\: %5.1lf %SMB\""
                ." LINE1:tot#CC9966"
                ." LINE1:base#CC6600"
                );
     }

     if ( $pgraphsset{"squid_paging_collect"} eq "Y" ) {
	&debugprint(3, "$img/$imgname41-$_[0]\n");
        system("$rrdtool graph $img/$imgname41-$_[0].png"
                ." -s \"-1$_[0]\""
                ." -t \"Squid paging over the last $_[0]\""
                ." --lazy"
                ." -h 100 -w 500"
                ." -l 0"
                ." -a PNG"
                ." -v \"rate\/min\""
                ." DEF:pagef=$rrd/$dbname4.rrd:pagef:AVERAGE"
                ." CDEF:pageh=pagef,60,*"
                ." AREA:pageh#FF9900:\"Page faults with io\""
                ." GPRINT:pageh:MAX:\" Max\\: %5.1lf %s\""
                ." GPRINT:pageh:AVERAGE:\" Avg\\: %5.1lf %S\""
                ." GPRINT:pageh:LAST:\" Current\\: %5.1lf %S/min\""
                );
     }

}

sub check_for {
      my $poss = shift;
      my $lookfor = shift;
      my $tags = shift;
      my $tage = shift;
      my $splat = shift;
      if ( $poss =~ m/($lookfor)/ ) 
      { 
         &debugprint(1, "matched:" .$poss); 
         my $upl = $poss;
         $upl = substr($upl, index($upl, $tags)+length($tags));
         $upl = substr($upl, 0, index($upl, $tage));
         $$splat = $upl;
      } 
}

sub debugprint {
  if ($debug) {
    if ($ARGV[0] >= $_[0]) {
        print $_[1];
    }
  }
}

