# /etc/profile: system-wide .profile file for the Bourne shells

PATH=/bin:/sbin:/usr/bin
export PATH
echo "INSMOD ETH START......"
test -e /lib/extra/tc3162_dmt.ko && (echo "ethcmd eth0 lanchip enable";echo "ethcmd eth0 vlanpt enable")
#	test -e /lib/extra/bcm_enet.ko && insmod /lib/extra/bcm_enet.ko
#	test -e /lib/extra/bcmsw.ko && insmod /lib/extra/bcmsw.ko && ifconfig bcmsw up

echo "INSMOD ETH Done"


