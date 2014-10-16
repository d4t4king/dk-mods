#!/usr/bin/perl
#
# This code is distributed under the terms of the GPL
#
# (c) Scott Knight 2004
# (c) Tiago Freitas Leal
use POSIX;

require '/var/smoothwall/mods/pgraphs/modlib.pl';

# # # # # # # # # # # # # # # # # # #
# check for existing installations  #
# # # # # # # # # # # # # # # # # # #

if (-e "/var/smoothwall/mods/pgraphs/installed") {
	if (&installed ("/var/smoothwall/mods/pgraphs/installed",
		       	"# Performance Graphs v1.6")) {
		print "\nPlease uninstall Performance Graphs v1.6 before reinstalling\n";
		print "Note - Run /var/smoothwall/mods/pgraphs/uninstall.pl script.\n \n";
		exit;
	}
	if (&installed ("/var/smoothwall/mods/pgraphs/installed",
		       	"# Performance Graphs v1.5")) {
		print "\nPlease uninstall Performance Graphs v1.5 before installing v1.6\n";
		print "Note - Run the v1.5 uninstall.pl script.\n \n";
		exit;
	}
	if (&installed ("/var/smoothwall/mods/pgraphs/installed",
		       	"# Performance Graphs v1.4")) {
		print "\nPlease uninstall Performance Graphs v1.4 before installing v1.6\n";
		print "Note - Run the v1.4 uninstall.pl script.\n \n";
		exit;
	}
	if (&installed ("/var/smoothwall/mods/pgraphs/installed",
		       	"# Performance Graphs v1.3")) {
		print "\nPlease uninstall Performance Graphs v1.3 before installing v1.6\n";
		print "Note - Run the v1.3 uninstall.pl script.\n \n";
		exit;
	}
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

my $mod = '/var/smoothwall/mods/pgraphs/modfiles';
my $storebkp = '/var/smoothwall/mods/pgraphs/backup';

print "Installing new files ...\n";

$dir = '/httpd/cgi-bin';
&install ('pgraphs.cgi', $dir, $mod);

$dir = '/httpd/html/help';
&install ('pgraphs.cgi.html.en', $dir, $mod);

$dir = '/usr/bin/smoothwall';
&install ('rrdtool_perf.pl', $dir, $mod);
&install ('rrdtool_conntrack.pl', $dir, $mod);
#&install ('conntrack-viewer.pl', $dir, $mod);
&install ('rrdtool_firewall.pl', $dir, $mod);
&install ('rrdtool_hddtemp.pl', $dir, $mod);
&install ('rrdtool_squid.pl', $dir, $mod);
&install ('rrdtool_squidx.pl', $dir, $mod);
&install ('rrdtool_temperature.pl', $dir, $mod);
&install ('rrdtool_voltage.pl', $dir, $mod);
&install ('rrdtool_disk.pl', $dir, $mod);
&install ('rrdtool_diskx.pl', $dir, $mod);
&install ('rrdtool_memoryx.pl', $dir, $mod);
&install ('rrdtool_uptime.pl', $dir, $mod);
&install ('rrdtool_ping.pl', $dir, $mod);
&install ('rrdtool_diskused.pl', $dir, $mod);
&install ('rrdtool_fan.pl', $dir, $mod);

$dir = '/usr/lib/smoothwall/menu/1000_About';
&install ('5420_pgraphs.list', $dir, $mod);

$dir = '/usr/bin';
&install ('fping', $dir, $mod);

# # # # # # # # # # # # # # # # #
# backup the preferences file   #
# and replace with an empty one #
# # # # # # # # # # # # # # # # #

$dir = '/var/smoothwall/mods/pgraphs/preferences';
&backup ('stored', $dir, $storebkp);

if ( (-e "$dir/stored" ) && (-r "$dir/stored" ) ) { 
	print "preferences/stored file already exists - leave it alone\n";
	print "If you are upgrading, you will need to configure any new graphs\n";
} else {
	`cp $dir/default_stored $dir/stored`;
}

# # # # # # # # # # # # # # #
# handle file permissions   #
# # # # # # # # # # # # # # #

print "Changing permissions on /httpd/cgi-bin/pgraphs.cgi to rwxr-xr-x\n";
`chmod 755 /httpd/cgi-bin/pgraphs.cgi`;

print "Changing permissions on /usr/bin/fping to rwxr-xr-x\n";
`chmod 755 /usr/bin/fping`;

print "Changing permissions on /var/smoothwall/mods/pgraphs/preferences/stored to rw-rw-rw-\n";
`chmod 666 /var/smoothwall/mods/pgraphs/preferences/stored`;
# # # # # # # # # # # #
# handle file editing #
# # # # # # # # # # # #

my $param = '/var/smoothwall/mods/pgraphs/params';

easymod("/usr/lib/smoothwall/langs/en.pl", "$param/base.pl-1.4-1.s", '0', "$param/base.pl-1.4-1.a");

easymod("/usr/lib/smoothwall/langs/en.pl", "$param/base.pl-1.4-2.s", '0', "$param/base.pl-1.4-2.a");

easymod("/usr/lib/smoothwall/langs/alertboxes.en.pl", "$param/alertboxes.base.pl-1.4-1.s", '0', "$param/alertboxes.base.pl-1.4-1.a");

easymod("/httpd/cgi-bin/logs.cgi/proxylog.dat", "$param/proxylog.dat-1.4-1.s", '0', "$param/proxylog.dat-1.4-1.a");

print "updating /etc/crontab\n";
`cat $param/crontab-1.5-1.a >> /etc/crontab`;

print "updating /httpd/cgi-bin/.htaccess\n";
`cat $param/htaccess-1.4-1.a >> /httpd/cgi-bin/.htaccess`;

# # # # # # # # # # # #
# handle file linking #
# # # # # # # # # # # #

# none

# # # # # # # # # # #
# wrapup and record #
# # # # # # # # # # #

$mod = '/var/smoothwall/mods/pgraphs/modfiles';
$dir = '/var/smoothwall/mods/pgraphs';
&install ('installed', $dir, $mod);

print "Done\n\n";

# # # #
# end #
# # # #
