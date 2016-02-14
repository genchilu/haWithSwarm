#!/bin/bash
show_help() {
	cat << EOF
	Usage: ${0##*/} [-h] [-a ARG] [-i image] [-o OPT] [-s swarm]
	Check target container from target image is running or not. If there is no target container
	running, it would run a new container
	-h	display this help and exit
	-a	ARG for docker run a new container. ex: "/opt/helloweb/app.js"
	-i	image name. ex: "genchilu/helloweb"
	-o 	docker run OPTIONS. ex: "-d -p 3000:3000 --restart=always --entrypoint=/usr/bin/node"
	-s	swarm master ip & port. ex: "192.168.99.104:2376"
	-t      time interval to check container alive
EOF
}

OPTIND=1
swarm=""
dockerOpt=""
targetImage=""
dockerArg=""
interval=10

while getopts "h?a:i:o:s:t:" opt; do
	case "$opt" in
		h|\?)
			show_help
			exit 0
			;;
		a)	dockerArg=$OPTARG
			;;
		i)	targetImage=$OPTARG
			;;
		o)	dockerOpt=$OPTARG
			;;
		s)	swarm=$OPTARG
			;;
		t)	interval=$OPTARG
			;;
	esac
done

shift $((OPTIND-1))

[ "$1" = "--" ] && shift

if [ "$swarm" == "" ] || [ "$dockerOpt" == "" ] || [ "$targetImage" == "" ]; then
	show_help
	exit 0
fi

while true
do
	containers=$(curl -s http://$swarm/containers/json)
	len=$(echo $containers | jq '. | length')
	containerCount=0
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
			containerCount=$((containerCount + 1))
		fi
	done
	echo "container count: "$containerCount

	if [ $containerCount == 0 ]; then	
		docker -H $swarm run $dockerOpt $targetImage $dockerArg
	fi
	sleep $interval
done
