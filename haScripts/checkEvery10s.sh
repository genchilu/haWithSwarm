#!/bin/bash
show_help() {
	cat << EOF
	Usage: ${0##*/} [-h] [-s swarm] [-o OPT] [-i image] [-a ARG] [-c consul] [-p path]
	run a new container in a swarm cluster and update conatiner info to cinsul
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

while true
do
	bash checkAlive.sh -s "$swarm" -o "$dockerOpt" -i "$targetImage" -a "$dockerArg" -c "$consul" -p "$consulPath"
	sleep 10
done
