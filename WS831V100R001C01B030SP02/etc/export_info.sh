iwpriv wl1 set_mib rssi_dump=1
iwpriv wl1 set_mib mlog_rssi_dump_enable=1
iwpriv wl0 set_mib rssi_dump=1
iwpriv wl0 set_mib mlog_rssi_dump_enable=1
ps > /var/exportinfo/ps
cat /proc/meminfo >/var/exportinfo/meminfo
ifconfig >/var/exportinfo/ifconfig
netstat -a >/var/exportinfo/netstat
top -n 1 >/var/exportinfo/cpuinfo
cat /proc/version > /var/exportinfo/version
ip maddr > /var/exportinfo/ip_maddr
ip tunnel > /var/exportinfo/ip_tunnel
ip mroute > /var/exportinfo/ip_mroute
arp -a > /var/exportinfo/arp_a
cat proc/net/nf_conntrack >/var/exportinfo/nf_connstrack
brctl show >/var/exportinfo/brctl_show
brctl showmacs br0 >/var/exportinfo/brctl_showmacs_br0
brctl showstp br0 >/var/exportinfo/brctl_showstp
debug mic all info >/var/exportinfo/mic_debug_info
top -n 1 >>/var/exportinfo/cpuinfo
ip rule > /var/exportinfo/ip_rule
ip route  > /var/exportinfo/ip_route
ip route show table 200 > /var/exportinfo/ip_route_200
debug dns test server > /var/exportinfo/dns_test_server
debug dns test cache > /var/exportinfo/dns_test_cache
debug dns test resident > /var/exportinfo/dns_test_resident
debug dns test redirect > /var/exportinfo/dns_test_redirect
cat /var/hotainfo > /var/exportinfo/hotainfo
cat /proc/partitions >/var/exportinfo/partitions
cat /proc/proc_user_usbdevs >/var/exportinfo/proc_user_usbdevs
cat /var/samba/smb.conf >/var/exportinfo/smb.conf
debug dhcps test show > /var/exportinfo/dhcps_test_show
ls var/dhcp/dhcps/ > /var/exportinfo/ls_var_dhcps
ls var/wan/ > /var/exportinfo/ls_var_wan
cat var/dhcp/dhcps/neighbors_new  > /var/exportinfo/neighbors_new
debug ipcheck test show  > /var/exportinfo/ipcheck_test_show
iptables -nvL >/var/exportinfo/iptables
iptables -t nat -nvL>/var/exportinfo/iptables_nat
iptables -t mangle -nvL>/var/exportinfo/iptables_mangle
ebtables -L --Lc >/var/exportinfo/ebtables
ebtables -t broute -L --Lc >/var/exportinfo/ebtables_broute
ebtables -t nat -L --Lc >/var/exportinfo/ebtables_nat
brctl showigmpsnooping >/var/exportinfo/brctl_showigmpsnooping
tc -s qdisc show dev imq0 >/var/exportinfo/qos_qdisc_imq0
tc -s qdisc show dev imq1 >/var/exportinfo/qos_qdisc_imq1
tc -s qdisc show dev imq2 >/var/exportinfo/qos_qdisc_imq2
tc -s qdisc show dev imq4 >/var/exportinfo/qos_qdisc_imq4
tc class show dev imq0 >/var/exportinfo/qos_class_imq0
tc class show dev imq2 >/var/exportinfo/qos_class_imq2
tc class show dev imq4 >/var/exportinfo/qos_class_imq4
cat proc/sys/net/ipv4/netfilter/downqos_enable >/var/exportinfo/downqos_enable
cat proc/sys/net/ipv4/netfilter/qos_enable >/var/exportinfo/qos_enable
cat proc/sys/net/ipv4/netfilter/smartqos_enable >/var/exportinfo/smartqos_enable
cat proc/mobilelog > /var/exportinfo/mlog
cat proc/mobilelog_1 > /var/exportinfo/mlog1
cat proc/atp_proc/panicinfo > /var/exportinfo/panicinfo
wget -g -l /var/exportinfo/xunleiinfo -r ./getsysinfo?v=2 127.0.0.1 -P 9000
debug ntwksync ntwksync info > /var/exportinfo/ntwksync_info
hi_cli home/cli/debug/app/res/getcap > var/exportinfo/getcap
hi_cli home/cli/debug/app/res/getcap -v srvname napt > /var/exportinfo/srvname_napt
hi_cli home/cli/debug/app/res/getcap -v srvname br > /var/exportinfo/srvname_br
echo "ethcmd eth0 status:" > /var/exportinfo/lan_info
ethcmd eth0 status >> /var/exportinfo/lan_info
echo "ethcmd eth0 media-type port 0:" >> /var/exportinfo/lan_info
(ethcmd eth0 media-type port 0) 2>> /var/exportinfo/lan_info
echo "ethcmd eth0 media-type port 1:" >> /var/exportinfo/lan_info
(ethcmd eth0 media-type port 1) 2>> /var/exportinfo/lan_info
iwpriv wl1 set_mib rssi_dump=0
iwpriv wl1 set_mib mlog_rssi_dump_enable=0
iwpriv wl0 set_mib rssi_dump=0
iwpriv wl0 set_mib mlog_rssi_dump_enable=0
top -n 1 >>/var/exportinfo/cpuinfo
wifitest
