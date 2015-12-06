#!/bin/sh +x
ulimit -m 10240
ulimit -v 27648
ulimit -c 0
exec su xunlei -c "sh /etc/etm_monitor.sh $1 &"