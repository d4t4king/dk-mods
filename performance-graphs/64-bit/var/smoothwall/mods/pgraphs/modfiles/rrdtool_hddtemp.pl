#!/usr/bin/perl
#
# original coded by Martin Pot 2003
# http://martybugs.net/smoothwall/rrdtool_mem.cgi
#
# SmoothWall scripts
#
# This code is distributed under the terms of the GPL
#
# (c) The SmoothWall Team
# rrdtool_hddtemp.pl
use Scalar::Util 'looks_like_number';

# define location of hddtemp binary
my $hddtempex= '/usr/sbin/hddtemp';

# define location of hddtemp database
my $hddtempdb = '/usr/share/misc/hddtemp.db';

# define location of rrdtool binary
my $rrdtool = '/usr/bin/rrdtool';

# define location of rrdtool databases
my $rrd = '/var/lib/rrd';

# define location of images
my $img = '/httpd/html/rrdtool';

my $dev_1_name  = '/dev/hda';
my $dev_1_regex = '\/dev\/hda';
my $dev_2_name  = '/dev/sda';
my $dev_2_regex = '\/dev\/sda';

# stored preferences
my $swroot = '/var/smoothwall';
my $prefs_file = "${swroot}/mods/pgraphs/preferences/stored";
my $key = 'hddtemp';
my %pgraphsset;

#did hddtemp guess
my $guessed_1 = 0;
my $guessed_2 = 0;
my $disktype_1 = '';
my $disktype_2 = '';

$pgraphsset{"$key"."_collect"} = 'Y';
&read_prefs($prefs_file, \%pgraphsset);

if ( $pgraphsset{$key."_collect"} eq "Y" ) {

# get usage 
my $dev_1_val = `$hddtempex -n -f $hddtempdb $dev_1_name`;
print "$dev_1_val";
chomp($dev_1_val);
# we expect a single number but hddtemp might get verbose
if ( (!( looks_like_number($dev_1_val))) or ("$dev_1_val" eq "0") ) {  
	if ($dev_1_val =~ /^$dev_1_regex:(.*):.* ([0-9]*) C.*$/ ) {
		print "HDD Temp guessed $2\n";
		$dev_1_val = $2;
		$guessed_1 = 1;
		$disktype_1 = $1;
	}
}
printf "HDD Temp for $dev_1_name: %.0f\n", $dev_1_val;

my $dev_2_val = `$hddtempex -n -f $hddtempdb $dev_2_name`;
print "$dev_2_val";
chomp($dev_2_val);
# we expect a single number but hddtemp might get verbose
if ( (!( looks_like_number($dev_2_val))) or ("$dev_2_val" eq "0") ) {  
	if ($dev_2_val =~ /^$dev_2_regex:(.*):.* ([0-9]*) C.*$/ ) {
		print "HDD Temp guessed $2\n";
		$dev_2_val = $2;
		$guessed_2 = 1;
		$disktype_2 = $1;
	}
}
printf "HDD Temp for $dev_2_name: %.0f\n", $dev_2_val;

# does what we got back from /dev/hda not look like a number
# or is it zero, if so then use the /dev/sda value if better
if ( (!( looks_like_number($dev_1_val))) or ("$dev_1_val" eq "0") ) {  
   if ( looks_like_number($dev_2_val)) {  
      print "Using value from $dev_2_name\n";
      $dev_1_val = $dev_2_val;
      $dev_1_name = $dev_2_name;
      $guessed_1 = $guessed_2;
      $disktype_1 = $disktype_2;
   }  
}

printf "Storing $dev_1_name: %.0f\n", $dev_1_val;

# if hddtemp rrdtool database doesn't exist, create it
if (! -e "$rrd/hddtemp.rrd")
{
        print "creating rrd database for hddtemp...\n";
        system("$rrdtool create $rrd/hddtemp.rrd -s 300"
                ." DS:dev_1_temp:GAUGE:600:0:U"
                ." RRA:AVERAGE:0.5:1:576"
                ." RRA:AVERAGE:0.5:6:672"
                ." RRA:AVERAGE:0.5:24:732"
                ." RRA:AVERAGE:0.5:144:1460");
}

# insert values into hddtemp rrd
`$rrdtool update $rrd/hddtemp.rrd -t dev_1_temp N:$dev_1_val`;
print "$rrdtool update $rrd/hddtemp.rrd -t dev_1_temp N:$dev_1_val\n";

# create connections graphs
&CreateGraphHddtemp("day");
&CreateGraphHddtemp("week");
&CreateGraphHddtemp("month");
&CreateGraphHddtemp("year");

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

sub CreateGraphHddtemp
{
# creates graph
# inputs: $_[0]: interval (ie, day, week, month, year)

my $warnmess = "";
	if ( $guessed_1 == 1 ) {
		$warnmess = " COMMENT:\"$disktype_1 not found in hddtemp.db" .
		            " - temperature could be wrong\"";
	}
	system("$rrdtool graph $img/hddtemp-$_[0].png"
                ." -s \"-1$_[0]\""
                ." -t \"Hard Disk temperature over the last $_[0]\""
		." --lazy"
                ." -h 100 -w 500"
                ." -a PNG"
		." -v \"degrees C\""
		." DEF:dev_1_temp=$rrd/hddtemp.rrd:dev_1_temp:AVERAGE"
                ." LINE1:dev_1_temp#FF7000:\"$dev_1_name\""
                ." GPRINT:dev_1_temp:MAX:\"        Max\\: %.1lf\""
                ." GPRINT:dev_1_temp:AVERAGE:\"Avg\\: %.1lf\""
                ." GPRINT:dev_1_temp:LAST:\"Current\\: %.1lf\\n\""
                . $warnmess
	);
}
