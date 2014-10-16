#!/usr/bin/perl
#
# This code is distributed under the terms of the GPL
#
# (c) Scott Knight 2004
# (c) Tiago Freitas Leal

require '/var/smoothwall/mods/pgraphs/modlib.pl';

# # # # # # # # # # # # # # # # # # #
# check for existing installations  #
# # # # # # # # # # # # # # # # # # #

if (-e "/var/smoothwall/mods/pgraphs/installed") {
	if (! &installed ("/var/smoothwall/mods/pgraphs/installed", "# Performance Graphs v1.6")) {
		print "\nPerformance Graphs is installed but not version 1.6\n";
		print "Please run the matching uninstall.pl script.\n \n";
		exit;
	}
} else {
	print "\n*** Performance Graphs does not seem to be installed\n";
	print "\n*** Attempting cleanup of failed install\n";
}

# # # # # # # # # # # #
# handle file copying #
# # # # # # # # # # # #

#	$storebkp =	where to store backup of the files that are changed by your mod
#	$moddir =	where your mod files are
#	$wkdir =	where you are changing files (backup from and copy to)
#
#	backupinstall ($file, $wkdir, $storebkp, $moddir);
#	backup ($file, $wkdir, $storebkp);
#	install ($file, $wkdir, $moddir);
#	uninstallrestore ($file, $wkdir, $storebkp);
#	uninstall ($file , $wkdir);
#
#	installed ($file, $string);
#
#	search for $string into $file => 1 found / 0 not found

print "Uninstalling files ...\n";

$dir = '/httpd/cgi-bin';
&uninstall ('pgraphs.cgi', $dir);

$dir = '/httpd/html/help';
&uninstall ('pgraphs.cgi.html.en', $dir);

$dir = '/usr/bin/smoothwall';
&uninstall ('rrdtool_perf.pl', $dir);
&uninstall ('rrdtool_conntrack.pl', $dir);
#&uninstall ('conntrack-viewer.pl', $dir);
&uninstall ('rrdtool_firewall.pl', $dir);
&uninstall ('rrdtool_hddtemp.pl', $dir);
&uninstall ('rrdtool_squid.pl', $dir);
&uninstall ('rrdtool_squidx.pl', $dir);
&uninstall ('rrdtool_temperature.pl', $dir);
&uninstall ('rrdtool_voltage.pl', $dir);
&uninstall ('rrdtool_disk.pl', $dir);
&uninstall ('rrdtool_diskx.pl', $dir);
&uninstall ('rrdtool_memoryx.pl', $dir);
&uninstall ('rrdtool_uptime.pl', $dir);
&uninstall ('rrdtool_ping.pl', $dir);
&uninstall ('rrdtool_diskused.pl', $dir);
&uninstall ('rrdtool_fan.pl', $dir);

$dir = '/usr/lib/smoothwall/menu/1000_About';
&uninstall ('5420_pgraphs.list', $dir);

# # # # # # # # # # # #
# handle file editing #
# # # # # # # # # # # #

###############################################################################
# third parameter is num of lines to remove - make SURE it matches the .a file#
###############################################################################

my $param = '/var/smoothwall/mods/pgraphs/params';

# do the crontab first to avoid missing / extra files 
easymod("/etc/crontab", "$param/crontab-1.5-1.a", '16', "/dev/null");

easymod("/usr/lib/smoothwall/langs/en.pl", "$param/base.pl-1.4-1.a", '1', "/dev/null");

easymod("/usr/lib/smoothwall/langs/en.pl", "$param/base.pl-1.4-2.a", '4', "/dev/null");

easymod("/usr/lib/smoothwall/langs/alertboxes.en.pl", "$param/alertboxes.base.pl-1.4-1.a", '1', "/dev/null");

easymod("/httpd/cgi-bin/logs.cgi/proxylog.dat", "$param/proxylog.dat-1.4-1.a", '1', "/dev/null");

easymod("/httpd/cgi-bin/.htaccess", "$param/htaccess-1.4-1.a", '4', "/dev/null");

# # # # # # # # # # # # # #
# delete the graph files  #
# # # # # # # # # # # # # #

$dir = '/httpd/html/rrdtool';
print "Removing the .png graphs from $dir\n";
`rm -f $dir/connections-*.png`;
`rm -f $dir/cpu-*.png`;
`rm -f $dir/disk_*-*.png`;
`rm -f $dir/diskx_*-*.png`;
`rm -f $dir/fan-*.png`;
`rm -f $dir/firewall-*.png`;
`rm -f $dir/hddtemp-*.png`;
`rm -f $dir/inodes_*-*.png`;
`rm -f $dir/load-*.png`;
`rm -f $dir/mem-*.png`;
`rm -f $dir/memoryx-*.png`;
`rm -f $dir/ping-*.png`;
`rm -f $dir/red_avail-*.png`;
`rm -f $dir/squid-*.png`;
`rm -f $dir/squid_*-*.png`;
`rm -f $dir/temperature-*.png`;
`rm -f $dir/uptime-*.png`;
`rm -f $dir/uptimemax-*.png`;
`rm -f $dir/voltage-*.png`;

# # # # # # # # # # # #
# handle file removal #
# # # # # # # # # # # #

$dir = '/var/lib/rrd';
print "    NOT removing any .rrd files from $dir\n";
print "    You may wish to do this manually if you need the space\n";
#&uninstall ('cpu.rrd', $dir);
#&uninstall ('mem.rrd', $dir);
#&uninstall ('load.rrd', $dir);
#&uninstall ('connections.rrd', $dir);
#&uninstall ('firewall.rrd', $dir);
#&uninstall ('hddtemp.rrd', $dir);
#&uninstall ('squid.rrd', $dir);
#&uninstall ('squid_cache.rrd', $dir);
#&uninstall ('squid_memory.rrd', $dir);
#&uninstall ('squid_paging.rrd', $dir);
#&uninstall ('squid_response.rrd', $dir);
#&uninstall ('temperature.rrd', $dir);
#&uninstall ('voltage.rrd', $dir);
#&uninstall ('disk.rrd', $dir);
#&uninstall ('diskx.rrd', $dir);
#&uninstall ('memoryx.rrd', $dir);
#&uninstall ('uptime2.rrd', $dir);
#&uninstall ('ping.rrd', $dir);
#&uninstall ('diskused.rrd', $dir);
#&uninstall ('fan.rrd', $dir);

my $check = `cat /etc/crontab | egrep "/usr/bin/smoothwall/rrdtool_" | wc -l`;
chomp($check);
if ("$check" ne "0") {
	print "\n*** Some entries may still remain in /etc/crontab\n";
	print "*** Please remove them manually.\n\n";
}

$dir = "/var/smoothwall/mods/pgraphs";
&uninstall ("installed", $dir);

print "Done\n\n";

# # # #
# end #
# # # #
