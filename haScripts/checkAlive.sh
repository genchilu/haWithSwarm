#!/bin/bash
show_help() {
	cat << EOF
	Usage: ${0##*/} [-h] [-s swarm] [-o OPT] [-i image] [-a ARG] [-c consul] [-p path]
	Check target container from target image is running or not. If there is no target container
	running, it would run a new container and update consul
	-h	display this help and exit
	-s	swarm master ip & port. ex: "192.168.99.104:2376"
	-o 	docker run OPTIONS. ex: "-d -p 3000:3000 --restart=always --entrypoint=/usr/bin/node"
	-i	image name. ex: "genchilu/helloweb"
	-a	ARG for docker run a new container. ex: "/opt/helloweb/app.js"
	-c	consul. ex: "http://192.168.99.104:8500"
	-p	path in consul. ex: "helloweb"
EOF
}

OPTIND=1
swarm=""
dockerOpt=""
targetImage=""
dockerArg=""
consult=""
consultPath=""

while getopts "h?s:o:i:a:c:p:" opt; do
	case "$opt" in
		h|\?)
			show_help
			exit 0
			;;
		s)	swarm=$OPTARG
			;;
		o)	dockerOpt=$OPTARG
			;;
		i)	targetImage=$OPTARG
			;;
		a)	dockerArg=$OPTARG
			;;
		c)	consul=$OPTARG
			;;
		p)	consulPath=$OPTARG
			;;
	esac
done

shift $((OPTIND-1))

[ "$1" = "--" ] && shift

if [ "$swarm" == "" ] || [ "$dockerOpt" == "" ] || [ "$targetImage" == "" ] || [ "$consul" == "" ] || [ "$consulPath" == "" ]; then
	show_help
	exit 0
fi

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
bash updateConsul.sh -c $consul -p $consulPath -s $swarm -i $targetImage
