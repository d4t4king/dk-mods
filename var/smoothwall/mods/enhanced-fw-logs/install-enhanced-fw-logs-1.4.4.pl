#!/usr/bin/perl
#
# This code is distributed under the terms of the GPL
#
# (c) The Smoothwall Team
#
# THIS MOD IS FOR SMOOTHWALL 3.0 (NOT 2.0)
#
# install script for [3.0] Enhanced Firewall Logs MOD V1.4.4
# Mod Author: KrisTof on smoothwall forums
# Release Date: 01/31/2011
#
# # # # # # # # # # # # # # # # # # #
# check for existing installations  #
# # # # # # # # # # # # # # # # # # #

if (&installed ("/usr/lib/smoothwall/langs/en.pl", "# Enhanced Firewall Logs MOD V1.0")) {
	print " \nEnhanced Firewall Logs MOD V1.0 found!\n";
	print " Please run /var/smoothwall/mods/enhanced-fw-logs/uninstall-enhanced-fw-logs-1.0.pl\n \n";
	print " Then rerun /tmp/install.sh\n";
	exit;
}

if (&installed ("/usr/lib/smoothwall/langs/en.pl", "# Enhanced Firewall Logs MOD V1.1")) {
	print " \nEnhanced Firewall Logs MOD V1.1 found!\n";
	print " Please run /var/smoothwall/mods/enhanced-fw-logs/uninstall-enhanced-fw-logs-1.1.pl\n \n";
	print " Then rerun /tmp/install.sh\n";
	exit;
}

if (&installed ("/usr/lib/smoothwall/langs/en.pl", "# Enhanced Firewall Logs MOD V1.2")) {
	print " \nEnhanced Firewall Logs MOD V1.2 found!\n";
	print " Please run /var/smoothwall/mods/enhanced-fw-logs/uninstall-enhanced-fw-logs-1.2.pl\n \n";
	print " Then rerun /tmp/install.sh\n";
	exit;
}

if (&installed ("/usr/lib/smoothwall/langs/en.pl", "# Enhanced Firewall Logs MOD V1.3")) {
	print " \nEnhanced Firewall Logs MOD V1.3 found!\n";
	print " Please run /var/smoothwall/mods/enhanced-fw-logs/uninstall-enhanced-fw-logs-1.3.pl\n \n";
	print " Then rerun /tmp/install.sh\n";
	exit;
}
if (&installed ("/usr/lib/smoothwall/langs/en.pl", "# Enhanced Firewall Logs MOD V1.4")) {
	print " \nEnhanced Firewall Logs MOD V1.4 found!\n";
	print " Please run /var/smoothwall/mods/enhanced-fw-logs/uninstall-enhanced-fw-logs-1.4.pl\n \n";
	print " Then rerun /tmp/install.sh\n";
	exit;
}
if (&installed ("/usr/lib/smoothwall/langs/en.pl", "# Enhanced Firewall Logs MOD V1.4.1")) {
	print " \nEnhanced Firewall Logs MOD V1.4.1 found!\n";
	print " Please run /var/smoothwall/mods/enhanced-fw-logs/uninstall-enhanced-fw-logs-1.4.1.pl\n \n";
	print " Then rerun /tmp/install.sh\n";
	exit;
}
if (&installed ("/usr/lib/smoothwall/langs/en.pl", "# Enhanced Firewall Logs MOD V1.4.2")) {
	print " \nEnhanced Firewall Logs MOD V1.4.2 found!\n";
	print " Please run /var/smoothwall/mods/enhanced-fw-logs/uninstall-enhanced-fw-logs-1.4.2.pl\n \n";
	print " Then rerun /tmp/install.sh\n";
	exit;
}

if (&installed ("/usr/lib/smoothwall/langs/en.pl", "# Enhanced Firewall Logs MOD V1.4.4")) {
	print " \nEnhanced Firewall Logs MOD V1.4.4 already found!\n \n";
	exit;
}

print "Installing Enhanced Firewall Logs V1.4.4...\n";

# # # # # # # # # # # #
# handle file copying #
# # # # # # # # # # # #

#	backupinstall ($file ,$wkdir ,$storebkp ,$moddir);
#	install ($file ,$wkdir ,$moddir);

my $bkp = '/var/smoothwall/mods/enhanced-fw-logs/backup';

my $mod = '/var/smoothwall/mods/enhanced-fw-logs/modfiles';

#install icons
$dir = '/httpd/html/ui/img';
&install ('activeipblocklock3.png', $dir, $mod);
&install ('activeipblocklock4.png', $dir, $mod);

# Backup and install stuff in /httpd/cgi-bin
$dir = '/httpd/cgi-bin/logs.cgi';
&backup ('firewalllog.dat' ,$dir ,$bkp ,$mod);
&install ('firewalllog.dat' ,$dir ,$mod);

# Backup and install stuff in /httpd/html/help
$dir = '/httpd/html/help';
&backup ('firewalllog.dat.html.en' ,$dir ,$bkp ,$mod);
&install ('firewalllog.dat.html.en' ,$dir ,$mod);

# This step may not be needed since the newer version 
# of perl installed with 3.1-RC5 already has it.
# Install CIDR.pm
# $dir = '/usr/lib/perl5/site_perl/5.14.4/Net';
# &install ('CIDR.pm', $dir, $mod);

# Backup base (in case)
$dir = '/usr/lib/smoothwall/langs';
&backup ('en.pl', $dir, $bkp, $mod);

# # # # # # # # # # # #
# handle permissions  #
# # # # # # # # # # # #

system ("chmod 755 /httpd/cgi-bin/logs.cgi/firewalllog.dat");
system ("chmod 1777 /tmp");

# # # # # # # # # # # #
# handle file editing #
# # # # # # # # # # # #

my $param = '/var/smoothwall/mods/enhanced-fw-logs/params';

&easymod ("/usr/lib/smoothwall/langs/en.pl", "$param/en.pl.8.s",'0',"$param/en.pl.8.r");

print "Done.\n";

# # # # # # # # # # # #
# handle file linking #
# # # # # # # # # # # #

# # # #
# end #
# # # #

#
# This code is distributed under the terms of the GPL
#
# (c) Tiago Freitas Leal

$version = '2.1';

#	$storebkp =	where to store backup of the files that are changed by your mod
#	$moddir =	where your mod files are
#	$wkdir =	where you are changing files (backup from and copy to)
#
#	backupinstall ($file ,$wkdir ,$storebkp ,$moddir);
#	backup ($file ,$wkdir ,$storebkp);
#	install ($file ,$wkdir ,$moddir);
#	uninstallrestore ($file ,$wkdir ,$storebkp);
#	uninstall ($file  ,$wkdir);
#
#	installed ($file, $string);
#
#	search for $string into $file => 1 found / 0 not found

sub backupinstall
{
	my $file = $_[0];
	my $wkdir = $_[1];
	my $storebkp = $_[2];
	my $moddir = $_[3];
#	system "/bin/cp -p $wkdir/$file $storebkp/$file";
	system "/bin/cp $moddir/$file $wkdir/$file";
}

sub backup
{
	my $file = $_[0];
	my $wkdir = $_[1];
	my $storebkp = $_[2];
	system "/bin/cp -p $wkdir/$file $storebkp/$file";
}

sub install
{
	my $file = $_[0];
	my $wkdir = $_[1];
	my $moddir = $_[2];
	system "/bin/cp -p $moddir/$file $wkdir/$file";
}

sub uninstallrestore
{
	my $file = $_[0];
	my $wkdir = $_[1];
	my $storebkp = $_[2];
	system "/bin/cp -p $storebkp/$file $wkdir/$file";
#	system "/bin/rm -f $storebkp/$file";
}

sub uninstall
{
	my $file = $_[0];
	my $wkdir = $_[1];
	system "/bin/rm -f $wkdir/$file";
}

sub easymod
{
	my $targetfile = $_[0];
	my $searchfile = $_[1];
	my $linestodelete = $_[2];
	my $replacefile = $_[3];

	open(TARGET, "$targetfile") or die 'Unable to open target file.';
	my @target = <TARGET>;
	close(TARGET);

	open(SEARCH, "$searchfile") or die 'Unable to open search file';
	my @search = <SEARCH>;
	close(SEARCH);

	open(REPLACE, "$replacefile") or die 'Unable to open replace file.';
	my @replace = <REPLACE>;
	close(REPLACE);

	open(TEMP, ">/tmp/temp") or die 'Unable to open temporary file.';
	flock TEMP, 2;

	my $found = 0;
	my $line;
	foreach $line (@target)
	{
		if ($found == 0)
		{
			if ($line eq "@search")
			{
				$found = 1;
				if ($linestodelete > 0)
				{
					$linestodelete--;
				}
				else {print TEMP "$line"; }
				my $repline;
				foreach $repline (@replace) {print TEMP $repline; }
			}
			else {print TEMP "$line"; }
		}
		else
		{
			if ($linestodelete > 0)
			{
				$linestodelete--;
			}
			else {print TEMP "$line"; }
		}
	}	
	close(TEMP);
	system "/bin/cp /tmp/temp $targetfile";
	system "/bin/rm -f /tmp/temp";
}

sub installed
{
	my $targetfile = $_[0];
	my $searchstring = $_[1];

	open(TARGET, "$targetfile") or die 'Unable to open target file.';
	my @target = <TARGET>;
	close(TARGET);

	my $line;
	foreach $line (@target)
	{
		if ($line eq "$searchstring\n")
		{
			return 1;
		}
	}	
	return 0;
}
