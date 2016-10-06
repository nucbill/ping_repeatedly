#!/bin/bash
# version 1.0.1
# copyright nucbill

sleeptime=30
#action=start
website="www.google.com"
website2="bt.neu6.edu.cn"
ping_wait_time=8
ping_times=8
pidfile="/tmp/pding-google-repeatedly.pid"
exe="ping6"

USAGE="USAGE: ping-google-repeatedly [start|stop] [timeperiod] [-s2 website2] [-s website] [-c how_many_times_of_everyping] [-w wait_time_of_everyping] [-exe ping_or_ping6]"

if [[ "$#" = 0 ]]; then
	echo "$USAGE"
	exit 1
fi
while (( "$#" ));do
	if [[ $1 =~ ^[0-9]+$ ]];then
		sleeptime=$1
	elif [[ $1 =~ ^[a-z]+$ ]];then
		action=$1
	elif [[ $1 = "-s" ]];then
		website=$2
		shift
	elif [[ $1 = "-s2" ]];then
		website2=$2
		shift
	elif [[ $1 = "-c" ]];then
		ping_times=$2
		shift
	elif [[ $1 = "-w" ]];then
		ping_wait_time=$2
		shift
	elif [[ $1 = "-exe" ]];then
		exe=$2
		shift
	fi
	shift
done
pingwork(){
	count=0
	errorcount=0
	while true;do
		$exe -c $ping_times -w $ping_wait_time $website > /dev/null 2>&1
		error1=$?
		$exe -c $ping_times -w $ping_wait_time $website2 > /dev/null 2>&1
		error2=$?
		sleep $sleeptime
		count=$((count+1))
		if ! [ $error1 = 0 -o $error2 = 0 ];then
			errorcount=$((errorcount+1))
			status="failed"
			$exe -c 500 -w 501 $website > /dev/null 2>&1 &	#ping more
			$exe -c 500 -w 501 $website2 > /dev/null 2>&1 &	#ping more
		else
			status="succeed"
		fi
		echo "error:	$errorcount"	>   /tmp/ping_repeatedly_errors
		echo "total:	$count"			>>  /tmp/ping_repeatedly_errors
		echo "LastPing:	$status"		>>  /tmp/ping_repeatedly_errors
	done
}

if [ $action = "start" ];then
	if [ -f $pidfile ];then
		echo "$pidfile already exist, program is running, use \"ping-google-repeatedly stop\" to stop"
		exit 1
	fi
	if ! [[ $exe = ping6 || $exe = ping ]];then
		echo "unsupported instruction: $exe"
		exit 1
	fi
	echo "$exe -c $ping_times -w $ping_wait_time $website, every $sleeptime (s) "$action"ed"
	if [ -n "$website2" ];then
		echo "$exe -c $ping_times -w $ping_wait_time $website2, every $sleeptime (s) "$action"ed"
	fi
	pingwork &
	echo $! > $pidfile 
elif [ $action = "stop" ];then
	if [ -f $pidfile ];then
		pid=`cat $pidfile`
	else
		echo "Is not running, and $pidfile do not exist."
		exit 1
	fi
	if [ -z `ps -e | grep $pid |grep -v "grep "|awk '{print $1}'` ]; then
		echo "Is not running, the progress $pid pidfile do not exist. So deleted staled pidfile: $pidfile"
		rm $pidfile
		exit 1
	else
		if kill $pid;then
			echo "Killed Successfully"
		else
			echo "something gone wrong"
			exit 1
		fi
	fi
	rm $pidfile
	exit 0
fi
