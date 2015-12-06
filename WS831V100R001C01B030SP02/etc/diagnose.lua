require ('sys')

sys.exec('sh /etc/export_info.sh')


sys.exec('tar cvf /var/crash.tar /var/exportinfo/ /var/dhcp/dhcpc/')