# High available & dynamically scale with swarm + consul
利用 swarm + consul 架構一個基於 docker 的基礎建設  
可以做到
- 機器無預警關機時服務可自動在另一台機器啟動
- 服務 loading 附載超過臨界值時，可以動態在其他機器新增服務做負載均衡

詳細說明請參考[架構說明](http://genchilu-blog.logdown.com/posts/317095-based-on-swarm-and-consul-ha-and-dynamically-extensible-architectures)  
## 簡單 demo 步驟如下  
準備四台裝好 docker 的vm，一台 master，三台 nodes  
docker daemon 啟動時需加入下列參數 "-H 0.0.0.0:2375 -H unix:///var/run/docker.sock"
### 在  maste 上安裝 consul
```sh
$ docker run -d -p 8400:8400 -p 8500:8500 -p 8600:53/udp -h node1 --name consul progrium/consul -server -bootstrap
```
#### 測試 consul
```sh
$ curl -L http://master_ip:8500/v1/catalog/nodes
[{"Node":"node1","Address":"172.17.0.2"}]
```
### 安裝 swarm
#### 在三台 nodes 上啟動 swarm
```sh
$ docker run -d --name swarm swarm join --advertise=node_ip:2375 consul://master_ip:8500/v1/kv/swarm
```
#### 在 master 上安裝 swarm manager
```sh
$ docker run -d -p 2376:2375 --name swarm swarm manage consul://master_ip:8500/v1/kv/swarm
```
#### 測試 swarm 集群是否正常運作
```sh
$ docker -H master_ip:2376 info
Containers: 3
Images: 4
Role: primary
Strategy: spread
Filters: health, port, dependency, affinity, constraint
Nodes: 3
 docker01: docker01:2375
  └ Containers: 1
  └ Reserved CPUs: 0 / 1
  └ Reserved Memory: 0 B / 778.3 MiB
  └ Labels: executiondriver=native-0.2, kernelversion=3.19.0-28-generic, operatingsystem=Ubuntu 14.04.3 LTS, storagedriver=aufs
 docker02: docker02:2375
  └ Containers: 1
  └ Reserved CPUs: 0 / 1
  └ Reserved Memory: 0 B / 778.3 MiB
  └ Labels: executiondriver=native-0.2, kernelversion=3.19.0-28-generic, operatingsystem=Ubuntu 14.04.3 LTS, storagedriver=aufs
 docker03: docker03:2375
  └ Containers: 1
  └ Reserved CPUs: 0 / 1
  └ Reserved Memory: 0 B / 778.3 MiB
  └ Labels: executiondriver=native-0.2, kernelversion=3.19.0-28-generic, operatingsystem=Ubuntu 14.04.3 LTS, storagedriver=aufs
CPUs: 3
Total Memory: 2.28 GiB
Name: 04511c8c45b8
```
### 架設 demo 用的 HA 
#### build demo image
在 master 上輸入
```sh
$ docker build -t hademo .
$ docker run -ti --rm -p 80:80 --name hademo hademo bash /root/startHaDemo.sh -m masterIp
```
打開瀏覽器輸入 http://masterIp 可看見 express 的範例頁面
#### 測試無預警關機
在 master 上輸入
```sh
$ docker -H master_ip:2376 ps
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS                           NAMES
81e160a3fa43        genchilu/helloweb   "/usr/bin/node /opt/h"   6 minutes ago       Up 6 minutes        docker01:3000->3000/tcp   docker01/happy_brahmagupta
```
發現服務在 docker01 上啟動，連到 docker01 並關機
```sh
$ ssh docker01
$ poweroff
```
這時會發現網頁無法連線，約十秒後網頁又恢復了。  
此時查詢
```sh
$ docker -H master_ip:2376 ps
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS                           NAMES
042d2e99b2b1        genchilu/helloweb   "/usr/bin/node /opt/h"   10 seconds ago      Up 10 seconds       docker02:3000->3000/tcp   docker02/fervent_darwin
```
發現看到服務在 docker02 跑起來

