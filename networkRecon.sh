#!/bin/bash

segments=('192.168.1')

for segment in "${segments[@]}"
do

	# Scanning live hosts in a segment
	echo "[*] Scanning live hosts in  $segment.0/24 segment ..."
	nmap -PR -sn $segment.0/24 -oG liveHosts_$segment.txt
	cat liveHosts_$segment.txt | awk '{print $2}' | grep -v ^N > liveHosts_$segment.filtered

	# For each live host make a port discovery
	numberIPs=$(wc -l liveHosts_$segment.filtered | awk '{print $1}')
	echo $numberIPs
	if [ $numberIPs = "0" ]
	then
		echo "Nothing found ..." 
		rm liveHosts_$segment.txt
		liveHosts_$segment.filtered
	else
		mkdir liveHosts_$segment
		cd liveHosts_$segment
		mv ../liveHosts_$segment.filtered .
		rm ../liveHosts_$segment.txt
		
		# For each live hosts make a port scan
		while read liveHost; do
			echo "Searching services and possibles vulns in: $liveHost"

			nmap -p- --open -T5 -v -n $liveHost -oG allPorts_$liveHost.grep

			ports="$(cat allPorts_$liveHost.grep | grep -oP '\d{1,5}/open' | awk '{print $1}' FS='/' | xargs | tr ' ' ',')"
			ip_address="$(cat $1 | grep -oP '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}' | sort -u | head -n 1)"
			echo -e "\n[*] Extracting information...\n" > extractPorts.tmp
			echo -e "\t[*] IP Address: $ip_address"  >> extractPorts.tmp
			echo -e "\t[*] Open ports: $ports\n"  >> extractPorts.tmp
			portsForNmap=$(echo $ports | tr -d '\n')
			cat extractPorts.tmp; rm extractPorts.tmp

			nmap -sT -sV -p$portsForNmap $liveHost -oX allPorts_$liveHost.xml

			searchsploit --nmap allPorts_$liveHost.xml > allPorts_$liveHost.searchsploit

		done <liveHosts_$segment.filtered
		cd ..
	fi
done