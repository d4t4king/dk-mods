#!/usr/bin/perl 
# 
# 
# coded by MALEADt (2005) 
# 
# SmoothWall CGIs 
# 
# This code is distributed under the terms of the GPL 
# 
# (c) The SmoothWall Team 

my $debug = 1; 


# define location of rrdtool binary 
my $rrdtool = '/usr/bin/rrdtool'; 
# define location of rrdtool databases 
my $rrd = '/var/lib/rrd'; 
# define location of images 
my $img = '/httpd/html/rrdtool'; 


# stored preferences
my $swroot = '/var/smoothwall';
my $prefs_file = "${swroot}/mods/pgraphs/preferences/stored";
my $key = 'firewall';
my %pgraphsset;
$pgraphsset{"$key"."_collect"} = 'Y';
&read_prefs($prefs_file, \%pgraphsset);

if ( $pgraphsset{$key."_collect"} eq "Y" ) {

# Get current hits and previous hits 
my $current = `grep "kernel:\\( \\[.*\\..*\\]\\)*\\( Denied-by-filter:[^\s]*\\)* IN" /var/log/messages | wc -l`; 
#my $current = `grep "kernel: \\[.*\\..*\\] IN" /var/log/messages | wc -l`; 
#my $current = `grep "kernel: IN" /var/log/messages | wc -l`; 
my $previous = `cat /var/log/previous.var`; 

# Filter out trailing and ending spaces, caused by wc command 
for ($current) 
{ 
        s/^\s+//; 
        s/\s+$//; 
} 

# remove eol chars 
chomp($previous); 
chomp($current); 
my $amount = $current - $previous; 
chomp($amount); 

# Save current stats 

system("echo $current > /var/log/previous.var"); 

# if firewall rrdtool database doesn't exist, create it 
if (! -e "$rrd/firewall.rrd") 
{ 
   print "creating rrd database for firewall hits...\n"; 
   system("$rrdtool create $rrd/firewall.rrd -s 300" 
   ." DS:amount:GAUGE:600:0:U" 
   ." RRA:AVERAGE:0.5:1:576"
   ." RRA:AVERAGE:0.5:6:672"
   ." RRA:AVERAGE:0.5:24:732"
   ." RRA:AVERAGE:0.5:144:1460");
} 

if ($debug) 
   { 
      printf "Previous amount of amount: %.0f\n", $previous; 
      printf "Current amount of amount: %.0f\n", $current; 
      printf "Difference: %.0f\n", $amount; 
      system("echo $amount >> /var/log/debug.var") 
   } 

# insert values into firewall rrd 
`$rrdtool update $rrd/firewall.rrd N:$amount`; 

# create firewall graphs 
&CreateGraphFirewall("day"); 
&CreateGraphFirewall("week"); 
&CreateGraphFirewall("month"); 
&CreateGraphFirewall("year"); 

} else {
        print "$key is not collecting at present\n";
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

sub CreateGraphFirewall 
{ 
# creates graph 
# inputs: $_[0]: interval (ie, day, week, month, year) 

   system("$rrdtool graph $img/firewall-$_[0].png" 
      ." -s \"-1$_[0]\"" 
      ." -t \"firewall hits over the last $_[0]\"" 
      ." --lazy" 
      ." -h 100 -w 500" 
      ." -r --units-exponent 0" 
      ." -a PNG" 
      ." -v \"firewall hits\/min\"" 
      ." DEF:amount5=$rrd/firewall.rrd:amount:AVERAGE" 
      ." CDEF:amount=amount5,5,/" 
      ." AREA:amount#FF9900:\"firewall hits\""
      ." LINE1:amount#CC6600"
      ." GPRINT:amount:MAX:\"  Max\\: %5.2lf %S\"" 
      ." GPRINT:amount:AVERAGE:\" Avg\\: %5.2lf %S\"" 
      ." GPRINT:amount:LAST:\" Current\\: %5.2lf %Shits/min\""); 
}

