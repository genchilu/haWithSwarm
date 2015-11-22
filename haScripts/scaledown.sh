#!/bin/bash
show_help() {
	cat << EOF
	Usage: ${0##*/} [-h] [-s swarm] [-i image] [-c consul] [-p path]
	kill a running container and update info to consul
	-h	display this help and exit
	-s	swarm master ip & port. ex: "192.168.99.104:2376"
	-i	image name. ex: "genchilu/helloweb"
	-c	consul. ex: "http://192.168.99.104:8500"
	-p	path. ex: "helloweb"
EOF
}

OPTIND=1
swarm=""
targetImage=""
consult=""
consulPath=""

while getopts "h?s:i:c:p:" opt; do
	case "$opt" in
		h|\?)
			show_help
			exit 0
			;;
		s)	swarm=$OPTARG
			;;
		i)	targetImage=$OPTARG
			;;
		c)	consul=$OPTARG
			;;
		p)	consulPath=$OPTARG
			;;
	esac
done

shift $((OPTIND-1))

[ "$1" = "--" ] && shift

if [ "$swarm" == "" ] || [ "$targetImage" == "" ] || [ "$consulPath" == "" ] || [ "$consulPath" == "" ]; then
	show_help
	exit 0
fi
containers=$(curl -s http://$swarm/containers/json)
len=$(echo $containers | jq '. | length')
for (( i=0; i<$len; i++ ))
do
	container=$(echo $containers | jq '.['$i']')
	image=$(echo $container | jq '.Image')
	image="${image//\"/""}"
	if [ "$targetImage" == "$image" ]; then
		id=$(echo $container | jq '.Id')
		id="${id//\"/""}"
		ip=$(echo $container | jq '.Ports[0].IP')
		ip="${ip//\"/""}"
		port=$(echo $container | jq '.Ports[0].PublicPort')
		echo $id
		echo $ip
		echo $port
		docker -H $swarm stop $id
		docker -H $swarm rm $id
		bash updateConsul.sh -c $consul -p $consulPath -s $swarm -i $targetImage
		break	
	fi
done
