#!/bin/bash

segments=('192.168.1')

for segment in "${segments[@]}"
do

	# Scanning live hosts in a segment
	echo "[*] Scanning live hosts in  $segment.0/24 segment ..."
	nmap -PR -sn $segment.0/24 -oG liveHosts_$segment.txt
	cat liveHosts_$segment.txt | awk '{print $2}' | grep -v ^N > liveHosts_$segment.filtered
	#cat liveHosts_$segment.txt | awk '{print $2}' > liveHosts_$segment.txt

	# For each live host make a port discovery
	numberIPs=$(wc -l liveHosts_$segment.filtered | awk '{print $1}')
	echo $numberIPs
	if [ $numberIPs = "0" ]
	then
		rm liveHosts_$segment.txt
		liveHosts_$segment.filtered
	else
		mkdir liveHosts_$segment
		cd liveHosts_$segment
		mv ../liveHosts_$segment.filtered .
		rm ../liveHosts_$segment.txt
		
		# For each live hosts make a port scan
		while read liveHost; do
			echo "$liveHost"
			nmap -p- --open -T5 -v -n $liveHost -oG allPorts_$liveHost.txt
		done <liveHosts_$segment.filtered
		cd ..
	fi
done
