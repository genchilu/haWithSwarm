containers=$(curl -s http://10.62.41.134:2376/containers/json)
targetImage="genchilu/helloweb"
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
		docker -H 10.62.41.134:2376 stop $id
		docker -H 10.62.41.134:2376 rm $id
		bash /git/hademo/updateConsul.sh
		break	
	fi
done
