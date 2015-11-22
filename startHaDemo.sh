#!/bin/bash
show_help() {
	cat << EOF
	Usage: ${0##*/} [-h] [-m msterIp]
	startup demo
	-h	display this help and exit
	-m	master ip. ex: "192.168.99.104"
EOF
}

OPTIND=1
master=""

while getopts "h?m:" opt; do
	case "$opt" in
		h|\?)
			show_help
			exit 0
			;;
		m)	master=$OPTARG
			;;
	esac
done

shift $((OPTIND-1))

[ "$1" = "--" ] && shift

if [ "$master" == "" ]; then
	show_help
	exit 0
fi

confd -interval 5 -backend consul -node $master:8500 &
service nginx start
bash checkEvery10s.sh -s "$master:2376" -o "-d -p 3000:3000 --restart=always --entrypoint=/usr/bin/node" -i "genchilu/helloweb" -a "/opt/helloweb/app.js" -c "http://$master:8500" -p "helloweb"
