# /etc/profile: system-wide .profile file for the Bourne shells

PATH=/bin:/sbin:/usr/bin
export PATH
echo -l "INSMOD base START......"
 test -e /lib/extra/bcm_ingqos.ko && insmod /lib/extra/bcm_ingqos.ko
 test -e /lib/extra/bcm_bpm.ko && insmod /lib/extra/bcm_bpm.ko
 test -e /lib/extra/pktflow.ko && insmod /lib/extra/pktflow.ko
 test -e /lib/extra/bcmfap.ko && insmod /lib/extra/bcmfap.ko
 test -e /lib/extra/pktcmf.ko && insmod /lib/extra/pktcmf.ko
 test -e /lib/extra/profdrvdd.ko && insmod /lib/extra/profdrvdd.ko
 test -e /lib/extra/bcmxtmcfg.ko && insmod /lib/extra/bcmxtmcfg.ko
 test -e /lib/extra/atmapi.ko && insmod /lib/extra/atmapi.ko
 
 test -e /lib/extra/atmbonding.ko && insmod /lib/extra/atmbonding.ko
 test -e /lib/extra/atmbondingeth.ko && insmod /lib/extra/atmbondingeth.ko
 test -e /lib/extra/adsldd.ko && insmod /lib/extra/adsldd.ko
 test -e /lib/extra/blaa_dd.ko && insmod /lib/extra/blaa_dd.ko
 test -e /lib/extra/bcmprocfs.ko && insmod /lib/extra/bcmprocfs.ko
 test -e /lib/kernel/net/ipv6/ipv6.ko && insmod /lib/kernel/net/ipv6/ipv6.ko
 test -e /lib/kernel/net/atm/br2684.ko && insmod /lib/kernel/net/atm/br2684.ko
 test -e /lib/extra/bcm_enet.ko && insmod /lib/extra/bcm_enet.ko
 test -e /lib/extra/nciTMSkmod.ko && insmod /lib/extra/nciTMSkmod.ko
 test -e /lib/extra/bcmsw.ko && insmod /lib/extra/bcmsw.ko && ifconfig bcmsw up

 test -e /lib/kernel/drivers/usb/core/usbcore.ko && insmod /lib/kernel/drivers/usb/core/usbcore.ko
 test -e /lib/kernel/drivers/usb/host/xhci-hcd.ko && insmod /lib/kernel/drivers/usb/host/xhci-hcd.ko 
 test -e /lib/kernel/drivers/usb/host/ehci-hcd.ko && insmod /lib/kernel/drivers/usb/host/ehci-hcd.ko	
 
 #判断WS880 针对USB3.0 u盘识别问题做特殊操作
 echo "retry xhci"
 test -e /bin/emfconf && rmmod xhci-hcd.ko && insmod /lib/kernel/drivers/usb/host/xhci-hcd.ko	
 echo "retry xhci done"
 test -e /lib/kernel/drivers/usb/host/ohci-hcd.ko && insmod /lib/kernel/drivers/usb/host/ohci-hcd.ko
 test -e /lib/kernel/drivers/usb/host/uhci-hcd.ko && insmod /lib/kernel/drivers/usb/host/uhci-hcd.ko
 test -e /lib/kernel/drivers/usb/serial/usbserial.ko && insmod /lib/kernel/drivers/usb/serial/usbserial.ko
 test -e /lib/kernel/drivers/usb/serial/usb_wwan.ko && insmod /lib/kernel/drivers/usb/serial/usb_wwan.ko
 test -e /lib/kernel/drivers/usb/serial/option.ko && insmod /lib/kernel/drivers/usb/serial/option.ko
 test -e /lib/kernel/drivers/usb/class/usblp.ko && insmod /lib/kernel/drivers/usb/class/usblp.ko
 test -e /lib/kernel/drivers/scsi/scsi_mod.ko && insmod /lib/kernel/drivers/scsi/scsi_mod.ko
 test -e /lib/kernel/drivers/scsi/sd_mod.ko && insmod /lib/kernel/drivers/scsi/sd_mod.ko
 test -e /lib/kernel/drivers/scsi/scsi_wait_scan.ko && insmod /lib/kernel/drivers/scsi/scsi_wait_scan.ko
 test -e /lib/kernel/drivers/usb/storage/usb-storage.ko && insmod /lib/kernel/drivers/usb/storage/usb-storage.ko
 test -e /lib/kernel/drivers/net/usb/qmitty.ko && insmod /lib/kernel/drivers/net/usb/qmitty.ko
 test -e /lib/kernel/drivers/net/usb/usbnet.ko && insmod /lib/kernel/drivers/net/usb/usbnet.ko
 test -e /lib/kernel/drivers/net/usb/rmnet_ethernet.ko && insmod /lib/kernel/drivers/net/usb/rmnet_ethernet.ko
 
 test -e /lib//extra/bcm_usb.ko && insmod /lib/extra/bcm_usb.ko
# test -e /lib/extra/wl.ko && insmod /lib/extra/wl.ko
#test -e /lib/extra/dspdd.ko && insmod /lib/extra/dspdd.ko
 test -e /lib/extra/endpointdd.ko && insmod /lib/extra/endpointdd.ko
 test -e /lib/extra/bcmvlan.ko && insmod /lib/extra/bcmvlan.ko
 test -e /lib/extra/p8021ag.ko && insmod /lib/extra/p8021ag.ko
 test -e /lib/extra/pwrmngtd.ko && insmod /lib/extra/pwrmngtd.ko
 test -e /lib/kernel/drivers/net/ctf/ctf.ko && insmod /lib/kernel/drivers/net/ctf/ctf.ko
 test -e /lib/extra/emf.ko && insmod /lib/extra/emf.ko
 test -e /lib/extra/igs.ko && insmod /lib/extra/igs.ko
 test -e /lib/kernel/drivers/net/et/et.ko && insmod /lib/kernel/drivers/net/et/et.ko
 test -e /lib/kernel/drivers/net/proxyarp/proxyarp.ko && insmod /lib/kernel/drivers/net/proxyarp/proxyarp.ko
# test -e /lib/kernel/drivers/net/wl/wl.ko && insmod /lib/kernel/drivers/net/wl/wl.ko

 test -e /lib/extra/ndistty.ko && insmod /lib/extra/ndistty.ko
 test -e /lib/extra/hw_cdc_driver.ko && insmod /lib/extra/hw_cdc_driver.ko

echo -l "INSMOD base Done"

atpsync post base

echo -l "INSMOD wlan START......"
test -e /lib/extra/wl.ko && insmod /lib/extra/wl.ko
test -e /lib/kernel/drivers/net/wl/wl.ko && insmod /lib/kernel/drivers/net/wl/wl.ko

atpsync dynapp console true
atpsync dynapp telnetd true

atpsync post wlan
echo -l "INSMOD wlan Done"
test -e /lib/extra/dsf.ko && insmod /lib/extra/dsf.ko