#先清空所有 consul key value
curl -X DELETE http://10.62.41.134:8500/v1/kv/helloweb/?recurse

#重新得到所有 container 資訊後再更新 consul
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
		curl -X PUT -d "$ip:$port" http://10.62.41.134:8500/v1/kv/helloweb/$id
	fi
done
