#!/bin/bash
volume_stat()
{
	#Run disk utilization
	echo " " > /monitoring/files/vol_breakup.txt 
	A=( $(df -Th | wc -l) - 1 )
	df -Th | awk 'NR>=2{print $1}' > /monitoring/files/vol_name.txt
	df -Th | awk 'NR>=2{print $6}' > /monitoring/files/vol_usage.txt
	df -Th | awk 'NR>=2{print $7}' > /monitoring/files/vol_mount.txt

	#Convert to array
	mapfile -t array1 < /monitoring/files/vol_name.txt
	mapfile -t array2 < /monitoring/files/vol_usage.txt
	mapfile -t array3 < /monitoring/files/vol_mount.txt

	#Pull metadata
	instance_id=$(curl http://169.254.169.254/latest/meta-data/instance-id)
	instance_type=$(curl http://169.254.169.254/latest/meta-data/instance-type)
	priv_ip=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)
	mac_address=$(curl http://169.254.169.254/latest/meta-data/mac)
	pub_hostname=$(curl http://169.254.169.254/latest/meta-data/public-hostname)
	pub_ip=$(curl http://169.254.169.254/latest/meta-data/public-ipv4)
	pem_key_field=$(curl http://169.254.169.254/latest/meta-data/public-keys/)
	pem_key_rev="$(echo $pem_key_field | rev)"
	pem_key_rev_1=${pem_key_rev::-2}
	pem_key="$(echo $pem_key_rev_1 | rev)"
	
	for (( i=0 ; i<$A ; i++))
	do
		if [ "${array1[$i]}" != null ]
		then
			excl="$excl --exclude=${array3[$i]}"
		fi
	done
	for (( i=0 ; i<$A ; i++))
	do
		flttr="$(echo ${array1[$i]} | head -c 1)"
		if [ "$flttr" == / ]
		then
			C=${array2[$i]}
			D=${C::-1}
			if [ "$D" -gt 10 ]
			then
				#Store metadata
				echo "Resource Details:" > /monitoring/files/vol_breakup.txt
				echo "~~~~~~~~~~~~~~~" >> /monitoring/files/vol_breakup.txt
				echo "Customer Name: PierianDX" >> /monitoring/files/vol_breakup.txt
				echo "INSTANCE ID: $instance_id" >> /monitoring/files/vol_breakup.txt
				echo "INSTANCE TYPE: $instance_type" >> /monitoring/files/vol_breakup.txt
				echo "PRIVATE IP: $priv_ip" >> /monitoring/files/vol_breakup.txt
				echo "MAC ADDRESS: $mac_address" >> /monitoring/files/vol_breakup.txt
				echo "PUBLIC IP(If any): $pub_ip" >> /monitoring/files/vol_breakup.txt
				echo "PUBLIC HOSTNAME(If any): $pub_hostname" >> /monitoring/files/vol_breakup.txt
				echo "SSH PEM FILE NAME: $pem_key" >> /monitoring/files/vol_breakup.txt
				echo "Breakup details for ${array1[$i]} volume mounted in ${array3[$i]} directory as it went to ${array2[$i]} usage" >> /monitoring/files/vol_breakup.txt
				du -ach ${array3[$i]}/* $excl --exclude=/proc | sort -hr | head -n 200 >> /monitoring/files/vol_breakup.txt
				sendmail safuvan.kotakuthmatayil@reancloud.com < /monitoring/files/vol_breakup.txt
			fi
		fi
	done
}
volume_stat
