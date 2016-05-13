#!/bin/bash
#
# version 0.1
# - uses timestamp from computer
# - records every second
#
# todo:
# - record values to variable
# - if vars unchanged from last record, make no record
# - if time is one second after previous, then don't record time
# - ie, only record time if more than 1 second has elapsed between
#   this record and the previous record

# nip = neurio IP address, change to be the same as your neurio ip

nip=192.168.178.158
D1=`date +"%Y-%m-%d"`
T1=`date +"%T"`
Labels=`curl -s http://$nip/current-sample | jq '.channels[1,2].label'`
echo "$D1 Start Power Logging: time timezone" | tee -a $D1.power.log
T0=""
LS="" #last sample
while true
	do
		T1=`date +"%T"`
		if [[ $T0 = $T1 ]] ; then
			#echo sleeping
			sleep .2
		else
			D1=`date +"%Y-%m-%d"`
			T0=`date +"%T"`
			#TS=`curl -s http://$nip/current-sample | jq '.timestamp'`
			#PW=`curl -s http://$nip/current-sample | jq '.channels[].p_W'`
			#TS=`curl -s http://$nip/current-sample | jq '.timestamp'`
			PW=`curl -s http://$nip/current-sample | jq '.timestamp,.channels[].p_W'`
			#echo $T1 $TS $PW $SECONDS>> $D1.power.log
			echo $T1 $TS $PW $SECONDS | tee -a $D1.power.log
			if [ "$SECONDS" -ge 1 ]; then
				SECONDS=0
			fi
			#echo "."
		fi
	done
