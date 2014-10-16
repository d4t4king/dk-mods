#!/bin/sh
set -x on
cp /usr/bin/smoothwall/rrdtool_perf.pl        /var/smoothwall/mods/pgraphs/modfiles/rrdtool_perf.pl
cp /usr/bin/smoothwall/rrdtool_conntrack.pl   /var/smoothwall/mods/pgraphs/modfiles/rrdtool_conntrack.pl
cp /usr/bin/smoothwall/rrdtool_firewall.pl    /var/smoothwall/mods/pgraphs/modfiles/rrdtool_firewall.pl
cp /usr/bin/smoothwall/rrdtool_hddtemp.pl     /var/smoothwall/mods/pgraphs/modfiles/rrdtool_hddtemp.pl
cp /usr/bin/smoothwall/rrdtool_squid.pl       /var/smoothwall/mods/pgraphs/modfiles/rrdtool_squid.pl
cp /usr/bin/smoothwall/rrdtool_squidx.pl      /var/smoothwall/mods/pgraphs/modfiles/rrdtool_squidx.pl
cp /usr/bin/smoothwall/rrdtool_temperature.pl /var/smoothwall/mods/pgraphs/modfiles/rrdtool_temperature.pl
cp /usr/bin/smoothwall/rrdtool_voltage.pl     /var/smoothwall/mods/pgraphs/modfiles/rrdtool_voltage.pl
cp /usr/bin/smoothwall/rrdtool_disk.pl        /var/smoothwall/mods/pgraphs/modfiles/rrdtool_disk.pl
cp /usr/bin/smoothwall/rrdtool_diskx.pl       /var/smoothwall/mods/pgraphs/modfiles/rrdtool_diskx.pl
cp /usr/bin/smoothwall/rrdtool_memoryx.pl     /var/smoothwall/mods/pgraphs/modfiles/rrdtool_memoryx.pl
cp /usr/bin/smoothwall/rrdtool_uptime.pl      /var/smoothwall/mods/pgraphs/modfiles/rrdtool_uptime.pl
cp /usr/bin/smoothwall/rrdtool_ping.pl        /var/smoothwall/mods/pgraphs/modfiles/rrdtool_ping.pl
cp /usr/bin/smoothwall/rrdtool_diskused.pl    /var/smoothwall/mods/pgraphs/modfiles/rrdtool_diskused.pl
cp /usr/bin/smoothwall/rrdtool_fan.pl         /var/smoothwall/mods/pgraphs/modfiles/rrdtool_fan.pl
#cp /usr/bin/smoothwall/conntrack-viewer.pl    /var/smoothwall/mods/pgraphs/modfiles/conntrack-viewer.pl
cp /var/smoothwall/mods/pgraphs/httpd/cgi-bin/pgraphs.cgi \
   /var/smoothwall/mods/pgraphs/modfiles/pgraphs.cgi
cp /var/smoothwall/mods/pgraphs/httpd/cgi-bin/.htaccess \
   /var/smoothwall/mods/pgraphs/modfiles/.htaccess
cp /var/smoothwall/mods/pgraphs/httpd/html/help/pgraphs.cgi.html.en \
   /var/smoothwall/mods/pgraphs/modfiles/pgraphs.cgi.html.en
cp /var/smoothwall/mods/pgraphs/usr/lib/smoothwall/langs/en.pl \
   /var/smoothwall/mods/pgraphs/modfiles/en.pl
cp /var/smoothwall/mods/pgraphs/usr/lib/smoothwall/langs/alertboxes.en.pl \
   /var/smoothwall/mods/pgraphs/modfiles/alertboxes.en.pl
cp /var/smoothwall/mods/pgraphs/usr/lib/smoothwall/langs/glossary.en.pl \
   /var/smoothwall/mods/pgraphs/modfiles/glossary.en.pl
cp /usr/bin/fping \
   /var/smoothwall/mods/pgraphs/modfiles/fping
chmod 755 /var/smoothwall/mods/pgraphs/modfiles/rrdtool_perf.pl
chmod 755 /var/smoothwall/mods/pgraphs/modfiles/rrdtool_conntrack.pl
chmod 755 /var/smoothwall/mods/pgraphs/modfiles/rrdtool_firewall.pl
chmod 755 /var/smoothwall/mods/pgraphs/modfiles/rrdtool_hddtemp.pl
chmod 755 /var/smoothwall/mods/pgraphs/modfiles/rrdtool_squid.pl
chmod 755 /var/smoothwall/mods/pgraphs/modfiles/rrdtool_squidx.pl
chmod 755 /var/smoothwall/mods/pgraphs/modfiles/rrdtool_temperature.pl
chmod 755 /var/smoothwall/mods/pgraphs/modfiles/rrdtool_voltage.pl
chmod 755 /var/smoothwall/mods/pgraphs/modfiles/rrdtool_disk.pl
chmod 755 /var/smoothwall/mods/pgraphs/modfiles/rrdtool_diskx.pl
chmod 755 /var/smoothwall/mods/pgraphs/modfiles/rrdtool_memoryx.pl
chmod 755 /var/smoothwall/mods/pgraphs/modfiles/rrdtool_uptime.pl
chmod 755 /var/smoothwall/mods/pgraphs/modfiles/rrdtool_ping.pl
chmod 755 /var/smoothwall/mods/pgraphs/modfiles/rrdtool_diskused.pl
chmod 755 /var/smoothwall/mods/pgraphs/modfiles/rrdtool_fan.pl
#chmod 755 /var/smoothwall/mods/pgraphs/modfiles/conntrack-viewer.pl
chmod 755 /var/smoothwall/mods/pgraphs/modfiles/pgraphs.cgi
chmod 755 /var/smoothwall/mods/pgraphs/modfiles/fping
chmod 755 /var/smoothwall/mods/pgraphs/modlib.pl
chmod 755 /var/smoothwall/mods/pgraphs/install.pl
chmod 755 /var/smoothwall/mods/pgraphs/uninstall.pl

tar -czvf pgraphs_31_16_03.tgz \
/var/smoothwall/mods/pgraphs/modlib.pl \
/var/smoothwall/mods/pgraphs/backup/afile \
/var/smoothwall/mods/pgraphs/params/proxylog.dat-1.4-1.a \
/var/smoothwall/mods/pgraphs/params/proxylog.dat-1.4-1.s \
/var/smoothwall/mods/pgraphs/params/crontab-1.5-1.a \
/var/smoothwall/mods/pgraphs/modfiles/5420_pgraphs.list \
/var/smoothwall/mods/pgraphs/modfiles/.htaccess \
/var/smoothwall/mods/pgraphs/modfiles/alertboxes.en.pl \
/var/smoothwall/mods/pgraphs/modfiles/en.pl \
/var/smoothwall/mods/pgraphs/modfiles/fping \
/var/smoothwall/mods/pgraphs/modfiles/glossary.en.pl \
/var/smoothwall/mods/pgraphs/modfiles/installed \
/var/smoothwall/mods/pgraphs/modfiles/pgraphs.cgi \
/var/smoothwall/mods/pgraphs/modfiles/pgraphs.cgi.html.en \
/var/smoothwall/mods/pgraphs/modfiles/rrdtool_conntrack.pl \
/var/smoothwall/mods/pgraphs/modfiles/rrdtool_firewall.pl \
/var/smoothwall/mods/pgraphs/modfiles/rrdtool_hddtemp.pl \
/var/smoothwall/mods/pgraphs/modfiles/rrdtool_perf.pl \
/var/smoothwall/mods/pgraphs/modfiles/rrdtool_squid.pl \
/var/smoothwall/mods/pgraphs/modfiles/rrdtool_squidx.pl \
/var/smoothwall/mods/pgraphs/modfiles/rrdtool_temperature.pl \
/var/smoothwall/mods/pgraphs/modfiles/rrdtool_voltage.pl \
/var/smoothwall/mods/pgraphs/modfiles/rrdtool_disk.pl \
/var/smoothwall/mods/pgraphs/modfiles/rrdtool_diskx.pl \
/var/smoothwall/mods/pgraphs/modfiles/rrdtool_memoryx.pl \
/var/smoothwall/mods/pgraphs/modfiles/rrdtool_uptime.pl \
/var/smoothwall/mods/pgraphs/modfiles/rrdtool_uptime.pl \
/var/smoothwall/mods/pgraphs/modfiles/rrdtool_ping.pl \
/var/smoothwall/mods/pgraphs/modfiles/rrdtool_diskused.pl \
/var/smoothwall/mods/pgraphs/modfiles/rrdtool_fan.pl \
/var/smoothwall/mods/pgraphs/modfiles/removespikes.pl \
/var/smoothwall/mods/pgraphs/preferences/default_stored \
/var/smoothwall/mods/pgraphs/install.pl \
/var/smoothwall/mods/pgraphs/uninstall.pl  \
/var/smoothwall/mods/pgraphs/CHANGES \
/tmp/pack_pgraphs_31_16_03.sh \
/tmp/install-pgraphs.sh \
;

echo finished;
