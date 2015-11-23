#!/bin/bash
show_help() {
	cat << EOF
	Usage: ${0##*/} [-h] [-c consul] [-i image] [-p path] [-s swarm]
	get all running container info from swarm api and update to consul
	-h	display this help and exit
	-c	consul url. ex: "http://192.168.99.104:8500"
	-i	image. ex: "genchilu/helloweb"
	-p	path in consul. ex: "helloweb"
	-s	swarm. ex: "192.168.99.104:2376"
EOF
}

OPTIND=1
consul=""
consulPath=""
swarm=""
targetImage=""

while getopts "h?c:p:s:i:" opt; do
	case "$opt" in
		h|\?)
			show_help
			exit 0
			;;
		c)	consul=$OPTARG
			;;
		i)	targetImage=$OPTARG
			;;
		p)	consulPath=$OPTARG
			;;
		s)	swarm=$OPTARG
			;;
	esac
done

[ "$1" = "--" ] && shift

if [ "$consul" == "" ] || [ "$consulPath" == "" ] || [ "$swarm" == "" ] || [ "$targetImage" == "" ]; then
        show_help
        exit 0
fi

#claer all val under path at consul before update
curl -X DELETE $consul/v1/kv/$consulPath/?recurse

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
		curl -X PUT -d "$ip:$port" $consul/v1/kv/$consulPath/$id
	fi
done
