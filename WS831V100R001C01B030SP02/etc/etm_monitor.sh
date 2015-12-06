#!/bin/sh +x

# 该脚本所在的目录
SELF_DIR="/bin"

# ETM 工作目录
ETM_SYSTEM_PATH=""

# ETM 磁盘检测配置文件
ETM_DISK_CFG_PATH=""

# ETM 配置文件路径
ETM_CFG_PATH=""

# 日志配置文件路径
LOG_CFG_PATH=""

# 指定ETM使用的deviceid，主要用于远程控制
ETM_DEVICEID=""

# 指定ETM使用的硬件ID，主要用于license验证
ETM_HARDWAREID=""

# ETM 进程的pid文件
ETM_PID_FILE_PATH=""

# ETM 使用的license
ETM_LICENSE=""

# ETM 启动的参数
ETM_ARGS=""

set_etm_system_path()
{
	ETM_SYSTEM_PATH="/var/xunlei"
}

set_disk_cfg_path()
{
	ETM_DISK_CFG_PATH="/var/xunlei/thunder_mounts.cfg"
}

set_etm_cfg_path()
{
	ETM_CFG_PATH="/var/xunlei/etm.ini"
}

set_log_cfg_path()
{
	LOG_CFG_PATH="/var/xunlei/log.ini"
}

set_etm_deviceid()
{
	ETM_DEVICEID=`/sbin/uci get /etc/config/messaging.deviceInfo.DEVICE_ID`
}

set_etm_hardwareid()
{
	ETM_HARDWAREID=`/usr/bin/matool --method idForVendor --params adaccf1f-8b8c-edcb-d533-770099d2ef20`
}

set_etm_pid_file_path()
{
	ETM_PID_FILE_PATH="/var/xunlei/xunlei.pid"
}

set_etm_license()
{
	if [ $1 == "624X" ]
	then
		ETM_LICENSE="1411260001000003p000624lcubiwszdi3fs2og66q"
	elif [ $1 == "626" ]
	then
		ETM_LICENSE="1504230001000004c000626jw8lqaiytvtsa61pog1"
	fi
}

assemble_etm_args()
{
	if [ -n "$ETM_SYSTEM_PATH" ]; then
		ETM_ARGS="$ETM_ARGS --system_path=$ETM_SYSTEM_PATH"
	fi
	if [ -n "$ETM_DISK_CFG_PATH" ]; then
		ETM_ARGS="$ETM_ARGS --disk_cfg=$ETM_DISK_CFG_PATH"
	fi
	if [ -n "$ETM_CFG_PATH" ]; then
		ETM_ARGS="$ETM_ARGS --etm_cfg=$ETM_CFG_PATH"
	fi
	if [ -n "$LOG_CFG_PATH" ]; then
		ETM_ARGS="$ETM_ARGS --log_cfg=$LOG_CFG_PATH"
	fi
#	if [ -n "$ETM_DEVICEID" ]; then
#		ETM_ARGS="$ETM_ARGS --deviceid=$ETM_DEVICEID"
#	fi
#	if [ -n "$ETM_HARDWAREID" ]; then
#		ETM_ARGS="$ETM_ARGS --hardwareid=$ETM_HARDWAREID"
#	fi
	if [ -n "$ETM_PID_FILE_PATH" ]; then
		ETM_ARGS="$ETM_ARGS --pid_file=$ETM_PID_FILE_PATH"
	fi
	
	if [ "$1" = "626" ]
	then
		ETM_ARGS="$ETM_ARGS --partnerid=626"
		ETM_ARGS="$ETM_ARGS --platformid=20"
	fi
	
	if [ -n "$ETM_LICENSE" ]; then
		ETM_ARGS="$ETM_ARGS --license=$ETM_LICENSE"
	fi
}

start_etm()
{
	#echo "executing ${SELF_DIR}/etm $ETM_ARGS"
	( ${SELF_DIR}/etm $ETM_ARGS & )
}

stop_etm()
{
	pid=`cat $ETM_PID_FILE_PATH`
	#echo "stopping etm pid=$pid"
	kill -9 $pid
	killall -9 etm
}

stop_vod()
{
	#echo "stopping vod_httpserver"
	pkill vod_httpserver
}

#限制迅雷下载的速度，最大下载速度为5210
check_limit_speed()
{
	PARA_FILE="/var/xunlei/parameter"
	parainfo="null"
	speed=0

	wget -g -l $PARA_FILE -r /settings? 127.0.0.1 -P 9000
	parainfo=$(awk -F, '{print $2}' $PARA_FILE)
	speed=${parainfo#*:}
	#echo "$parainfo $speed"
	
	if [ $speed -gt 5120 ]; then
		wget -g -l $PARA_FILE -r /settings?downloadSpeedLimit=5120 127.0.0.1 -P 9000
	elif [ $speed -le -1 ]; then
		wget -g -l $PARA_FILE -r /settings?downloadSpeedLimit=5120 127.0.0.1 -P 9000
	fi
}

check_etm_status()
{
	RET_FILE="/var/xunlei/etm_info"
	time_begin=`date +%s`
	wget -g -l /var/xunlei/httpdiag.txt -r / 127.0.0.1 -P 9000
	if [ $? -ne 0 ]; then
		time_end=`date +%s`
		time_elapsed=$((time_end-time_begin))
		if [ $time_elapsed -ge 60 ]; then 
			#echo "[`date`] service timeout!!!!"
			return 2 # service timeout
   		fi
		#echo "[`date`] sevice not avaliable!!!!"
		return 1 #service not avaliable
	fi
	check_limit_speed
	pid=`cat $ETM_PID_FILE_PATH`
	renice 19 $pid
	#echo "[`date`] service OK!!!"
	return 0 #service OK
}

etm_monitor()
{
	timeout_count=0
	while [ 1 -gt 0 ]; do
		sleep 3
		check_etm_status
		check_ret=$?
		if [ $check_ret -eq 1 ]; then
			stop_etm
			start_etm
			timeout_count=0
		elif [ $check_ret -eq 2 ]; then
			timeout_count=$((++timeout_count))
			if [ $timeout_count -ge 5 ]; then
				stop_etm
				start_etm
				timeout_count=0
			fi
		else
			timeout_count=0
		fi
	done
}

set_etm_system_path
set_disk_cfg_path
set_etm_cfg_path
set_log_cfg_path
#set_etm_deviceid
#set_etm_hardwareid
set_etm_pid_file_path
set_etm_license $1
assemble_etm_args $1
start_etm
etm_monitor
