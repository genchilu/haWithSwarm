#!/bin/bash
show_help() {
	cat << EOF
	Usage: ${0##*/} [-h] [-a ARG] [-c consul] [-i imagev] [-o OPT] [-p path] [-s swarm]
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
image=""
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
		i)	image=$OPTARG
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
echo "swarm $swarm"
echo "dockerOpt $dockerOpt"
echo "image $image"
echo "consul $consul"
echo "consulPath $consulPath"
if [ "$swarm" == "" ] || [ "$dockerOpt" == "" ] || [ "$image" == "" ] || [ "$consul" == "" ] || [ "$consulPath" == "" ]; then
	show_help
	exit 0
fi

docker -H $swarm run $dockerOpt $image $dockerArg
bash updateConsul.sh -c $consul -p $consulPath -s $swarm -i $image
