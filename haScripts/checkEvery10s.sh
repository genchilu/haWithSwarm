#!/bin/bash
show_help() {
	cat << EOF
	Usage: ${0##*/} [-h] [-a ARG] [-c consul] [-i image] [-o OPT] [-p path] [-s swarm]
	run a new container in a swarm cluster and update conatiner info to cinsul
	-h	display this help and exit
	-a	ARG for docker run a new container. ex: "/opt/helloweb/app.js"
	-c	consul. ex: "http://192.168.99.104:8500"
	-i	image name. ex: "genchilu/helloweb"
	-o 	docker run OPTIONS. ex: "-d -p 3000:3000 --restart=always --entrypoint=/usr/bin/node"
	-p	path in consul. ex: "helloweb"
	-s	swarm master ip & port. ex: "192.168.99.104:2376"
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
		a)	dockerArg=$OPTARG
			;;
		c)	consul=$OPTARG
			;;
		i)	targetImage=$OPTARG
			;;
		o)	dockerOpt=$OPTARG
			;;
		p)	consulPath=$OPTARG
			;;
		s)	swarm=$OPTARG
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
