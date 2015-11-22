containers=$(curl -s http://10.62.41.134:2376/containers/json)
targetImage="genchilu/helloweb"
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
	docker -H 10.62.41.134:2376 run -d -p 3000:3000 --restart=always --entrypoint=/usr/bin/node genchilu/helloweb /opt/helloweb/app.js
fi
bash /git/hademo/updateConsul.sh
