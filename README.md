# High available & auto scale up with swarm + consul

## 在  maste 上安裝 consul
```sh
$ docker run -d -p 8400:8400 -p 8500:8500 -p 8600:53/udp -h node1 --name consul progrium/consul -server -bootstrap
```
### 測試 consul
```sh
$ curl -L http://master_ip:8500/v1/catalog/nodes
[{"Node":"node1","Address":"172.17.0.2"}]
```
## 安裝 swarm
### 在 docker nodes 上啟動 swarm
```sh
$ docker run -d --name swarm swarm join --advertise=192.168.99.105:2375 consul://192.168.99.104:8500/v1/kv/swarm
```
### 在 master 上安裝 swarm manager
```sh
$ docker run -d -p 2376:2375 --name swarm swarm manage consul://master_ip:8500/v1/kv/swarm
```
### 測試 swarm 集群是否正常運作
```sh
$ docker -H master_ip:2376 info
Containers: 3
Images: 4
Role: primary
Strategy: spread
Filters: health, port, dependency, affinity, constraint
Nodes: 3
 docker01: 192.168.99.105:2375
  └ Containers: 1
  └ Reserved CPUs: 0 / 1
  └ Reserved Memory: 0 B / 778.3 MiB
  └ Labels: executiondriver=native-0.2, kernelversion=3.19.0-28-generic, operatingsystem=Ubuntu 14.04.3 LTS, storagedriver=aufs
 docker02: 192.168.99.106:2375
  └ Containers: 1
  └ Reserved CPUs: 0 / 1
  └ Reserved Memory: 0 B / 778.3 MiB
  └ Labels: executiondriver=native-0.2, kernelversion=3.19.0-28-generic, operatingsystem=Ubuntu 14.04.3 LTS, storagedriver=aufs
 docker03: 192.168.99.107:2375
  └ Containers: 1
  └ Reserved CPUs: 0 / 1
  └ Reserved Memory: 0 B / 778.3 MiB
  └ Labels: executiondriver=native-0.2, kernelversion=3.19.0-28-generic, operatingsystem=Ubuntu 14.04.3 LTS, storagedriver=aufs
CPUs: 3
Total Memory: 2.28 GiB
Name: 04511c8c45b8
```
## 架設 demo 用的 HA 
### build demo image
在 master 上輸入
```sh
$ docker build -t hademo .
$ docker run -ti --rm -p 80:80 --name hademo hademo bash /root/startHaDemo.sh -m masterIp
```
打開瀏覽器輸入 http://masterIp 可看見 express 的範例頁面
### 測試無預警關機
在 master 上輸入
```sh
$ docker -H 192.168.99.104:2376 ps
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS                           NAMES
81e160a3fa43        genchilu/helloweb   "/usr/bin/node /opt/h"   6 minutes ago       Up 6 minutes        192.168.99.105:3000->3000/tcp   docker01/happy_brahmagupta
```
發現服務在 docker01 上啟動，連到 docker01 並關機
```sh
$ ssh docker01
$ poweroff
```
這時會發現網頁無法連線，約十秒後網頁又恢復了。  
此時查詢
```sh
$ docker -H 192.168.99.104:2376 ps
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS                           NAMES
042d2e99b2b1        genchilu/helloweb   "/usr/bin/node /opt/h"   10 seconds ago      Up 10 seconds       192.168.99.106:3000->3000/tcp   docker02/fervent_darwin
```
發現服務自動在 docker02 跑起來

