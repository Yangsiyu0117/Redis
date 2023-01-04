# Redis

[TOC]



## <u>文档标识</u>

| 文档名称 | Redis    |
| -------- | -------- |
| 版本号   | <V1.0.0> |

## <u>文档修订历史</u>

| 版本   | 日期       | 描述   | 文档所有者 |
| ------ | ---------- | ------ | ---------- |
| V1.0.0 | 2022.11.14 | create | 杨丝雨     |
|        |            |        |            |
|        |            |        |            |

## <u>服务器规划</u>

| IP地址 | 服务器配置 | OS   | Remarks |
| ------ | ---------- | ---- | ------- |
|        |            |      |         |

## <u>路径规划</u>

| 路径                            | 描述         | 文件名                                 | remarks                                  |
| ------------------------------- | ------------ | -------------------------------------- | ---------------------------------------- |
| /etc/redis.conf                 | 默认配置文件 | redis.conf                             | yum安装的配置文件默认放在/etc/redis.conf |
| /usr/local/redis/etc/redis.conf | 默认配置文件 | redis.conf                             | 编译安装的配置文件存放路径               |
| /usr/local/redis/bin/           | 二进制文件   | redis-benchmark redis-cli redis-server | 编译安装的二进制文件存放路径             |

## <u>端口规划</u>

| 端口 | 协议 | remrks       |
| ---- | ---- | ------------ |
| 6379 | tcp  | 默认开放端口 |
|      |      |              |
|      |      |              |

## <u>软件包</u>

| 安装包 | 版本   | 下载地址                                             |
| ------ | ------ | ---------------------------------------------------- |
| redis  | v7.0.5 | http://download.redis.io/releases/redis-7.0.5.tar.gz |
|        |        |                                                      |
|        |        |                                                      |



## <u>相关文档参考</u>

[Redis官网]: http://redis.io/
[Redis官方文档]: http://redis.io/documentation
[Redis下载]: http://redis.io/download
[Redis系列参考文档]: https://xie.infoq.cn/article/6c3500c66c3cdee3d72b88780
[Redis概念和基础参考文档]: https://www.cnblogs.com/pengdai/p/14650675.html
[Redis五种基础数据类型文档]: https://pdai.tech/md/db/nosql-redis/db-redis-data-types.html



> Redis是一种支持key-value等多种数据结构的存储系统。可用于缓存，事件发布或订阅，高速队列等场景。支持网络，提供字符串，哈希，列表，队列，集合结构直接存取，基于内存，可持久化。

### Yum安装

#### 1.	下载epel仓库

```shell
yum install epel-release
```

#### 2.	安装redis

```shell
yum install redis -y
```

#### 3.	常见命令

```shell
systemctl start redis #启动服务
systemctl stop redis  #停止服务
systemctl restart redis  #重启服务
systemctl status redis   #查看服务状态
systemctl enable redis   #设置开机自启动

netstat -lnp|grep 6379  #查看端口
```

#### 4.	配置文件

```shell
# yum安装的配置文件默认放在/etc/redis.conf
vim /etc/redis.conf
# 找到protected-mode设置为no 
protected-mode no
#	bind 设置为0.0.0.0 
bind 0.0.0.0
# 取消requirepass注释,设置密码
requirepass "password"
```

### 编译安装

#### 1.	下载源码并解压

```shell
wget http://download.redis.io/releases/redis-7.0.5.tar.gz
tar xf redis-7.0.5.tar.gz
cd redis-7.0.5
```

#### 2.	编译

```shell
yum -y install gcc gcc-c++ kernel-devel
make
```

等待编译完成

#### 3.	安装

```shell
make PREFIX=/usr/local/redis install
mkdir /usr/local/redis/etc/
cp redis.conf /usr/local/redis/etc/
cd /usr/local/redis/bin/
cp redis-benchmark redis-cli redis-server /usr/bin/
```

#### 4.	更改配置

```shell
vim /usr/local/redis/etc/redis.conf

# 修改一下配置
# redis以守护进程的方式运行
# no表示不以守护进程的方式运行(会占用一个终端)  
daemonize yes

# 客户端闲置多长时间后断开连接，默认为0关闭此功能                                      
timeout 300

# 设置redis日志级别，默认级别：notice                    
loglevel verbose

# 设置日志文件的输出方式,如果以守护进程的方式运行redis 默认:"" 
# 并且日志输出设置为stdout,那么日志信息就输出到/dev/null里面去了 
logfile stdout
# 设置密码授权
requirepass <设置密码>
# 监听ip
bind 127.0.0.1 
```

#### 5.	配置环境变量

```shell
vim /etc/profile
export PATH="$PATH:/usr/local/redis/bin"
# 保存退出

# 让环境变量立即生效
source /etc/profile
```

#### 6.	配置启动脚本

> 如果有需要可以配置启动脚本

```shell
#!/bin/bash
PATH=/usr/local/bin:/sbin:/usr/bin:/bin
REDISPORT=6379
EXEC=/usr/local/redis/bin/redis-server
REDIS_CLI=/usr/local/redis/bin/redis-cli
   
PIDFILE=/var/run/redis.pid
CONF="/usr/local/redis/etc/redis.conf"
   
case "$1" in
    start)
        if [ -f $PIDFILE ]
        then
                echo "$PIDFILE exists, process is already running or crashed"
        else
                echo "Starting Redis server..."
                $EXEC $CONF
        fi
        if [ "$?"="0" ] 
        then
              echo "Redis is running..."
        fi
        ;;
    stop)
        if [ ! -f $PIDFILE ]
        then
                echo "$PIDFILE does not exist, process is not running"
        else
                PID=$(cat $PIDFILE)
                echo "Stopping ..."
                $REDIS_CLI -p $REDISPORT SHUTDOWN
                while [ -x ${PIDFILE} ]
               do
                    echo "Waiting for Redis to shutdown ..."
                    sleep 1
                done
                echo "Redis stopped"
        fi
        ;;
   restart|force-reload)
        ${0} stop
        ${0} start
        ;;
  *)
    echo "Usage: /etc/init.d/redis {start|stop|restart|force-reload}" >&2
        exit 1
esac
```

#### 7.	开启自启动设置

```shell
# 复制脚本文件到init.d目录下
cp redis /etc/init.d/
# 给脚本增加运行权限
chmod +x /etc/init.d/redis
# 查看服务列表
chkconfig --list
# 添加服务
chkconfig --add redis
# 配置启动级别
chkconfig --level 2345 redis on
```

#### 8.	启动测试

```shell
systemctl start redis   #或者 /etc/init.d/redis start  
systemctl stop redis   #或者 /etc/init.d/redis stop
# 查看redis进程
ps -el|grep redis
# 端口查看
netstat -an|grep 6379
```

### 安裝 Docker & Docker-compose

```shell
yum install -y yum-utils
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum update
yum install docker-ce docker-ce-cli containerd.io.
sudo systemctl enable docker
sudo systemctl start docker
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

```shell
# Firewall
firewall-cmd --permanent --add-port=6379/tcp
firewall-cmd --reload
mkdir ~/Docker/Redis
cd ~/Docker/Redis
touch docker-compose.yml
vi docker-compost.yml
```

```yaml
# docker-compose.yml
services:
  redis:
    image: redis:latest
    container_name: redis
    environment:
      - TZ=Asia/Shanghai
    volumes:
      - ./conf/redis.conf:/usr/local/etc/redis/redis.conf
      - ./redis-data/:/data:rw
    ports:
      - 6379:6379
    command: [ "redis-server", "/usr/local/etc/redis/redis.conf" ]
    restart: always

```



### Redis集群模式

> Redis支持三种集群方案
>
> - 主从复制模式
> - Sentinel（哨兵）模式
> - Cluster模式

#### 主从复制模式

##### 概念

主从复制模式中包含一个主数据库实例（master）与一个或多个从数据库实例（slave）

![redis-master-slave](https://p1-jj.byteimg.com/tos-cn-i-t2oaga2asx/gold-user-assets/2020/3/19/170f23858652a465~tplv-t2oaga2asx-zoom-in-crop-mark:4536:0:0:0.awebp)

客户端可对主数据库进行读写操作，对从数据库进行读操作，主数据库写入的数据会实时自动同步给从数据库。

具体工作机制为：

1. slave启动后，向master发送SYNC命令，master接收到SYNC命令后通过bgsave保存快照（即上文所介绍的RDB持久化），并使用缓冲区记录保存快照这段时间内执行的写命令
2. master将保存的快照文件发送给slave，并继续记录执行的写命令
3. slave接收到快照文件后，加载快照文件，载入数据
4. master快照发送完后开始向slave发送缓冲区的写命令，slave接收命令并执行，完成复制初始化
5. 此后master每次执行一个写命令都会同步发送给slave，保持master与slave之间数据的一致性

##### 部署示例

> redis.conf的主要配置

```shell
###网络相关###
# bind 127.0.0.1 # 绑定监听的网卡IP，注释掉或配置成0.0.0.0可使任意IP均可访问
protected-mode no # 关闭保护模式，使用密码访问
port 6379  # 设置监听端口，建议生产环境均使用自定义端口
timeout 30 # 客户端连接空闲多久后断开连接，单位秒，0表示禁用

###通用配置###
daemonize yes # 在后台运行
pidfile /var/run/redis_6379.pid  # pid进程文件名
logfile /usr/local/redis/logs/redis.log # 日志文件的位置

###RDB持久化配置###
save 900 1 # 900s内至少一次写操作则执行bgsave进行RDB持久化
save 300 10
save 60 10000 
# 如果禁用RDB持久化，可在这里添加 save ""
rdbcompression yes #是否对RDB文件进行压缩，建议设置为no，以（磁盘）空间换（CPU）时间
dbfilename dump.rdb # RDB文件名称
dir /usr/local/redis/datas # RDB文件保存路径，AOF文件也保存在这里

###AOF配置###
appendonly yes # 默认值是no，表示不使用AOF增量持久化的方式，使用RDB全量持久化的方式
appendfsync everysec # 可选值 always， everysec，no，建议设置为everysec

###设置密码###
requirepass 123456 # 设置复杂一点的密码
```

部署主从复制模式只需稍微调整slave的配置，在redis.conf中添加

```shell
replicaof 127.0.0.1 6379 # master的ip，port
masterauth 123456 # master的密码
replica-serve-stale-data no # 如果slave无法与master同步，设置成slave不可读，方便监控脚本发现问题
```

本示例在单台服务器上配置master端口6379，两个slave端口分别为7001,7002，启动master，再启动两个slave

```shell
[root@dev-server-1 master-slave]# redis-server master.conf
[root@dev-server-1 master-slave]# redis-server slave1.conf
[root@dev-server-1 master-slave]# redis-server slave2.conf
```

进入master数据库，写入一个数据，再进入一个slave数据库，立即便可访问刚才写入master数据库的数据。如下所示

```shell
[root@dev-server-1 master-slave]# redis-cli 
127.0.0.1:6379> auth 123456
OK
127.0.0.1:6379> set site blog.jboost
OK
127.0.0.1:6379> get site
"blog.jboost"
127.0.0.1:6379> info replication
# Replication
role:master
connected_slaves:2
slave0:ip=127.0.0.1,port=7001,state=online,offset=13364738,lag=1
slave1:ip=127.0.0.1,port=7002,state=online,offset=13364738,lag=0
...
127.0.0.1:6379> exit

[root@dev-server-1 master-slave]# redis-cli -p 7001
127.0.0.1:7001> auth 123456
OK
127.0.0.1:7001> get site
"blog.jboost"
```

执行`info replication`命令可以查看连接该数据库的其它库的信息，如上可看到有两个slave连接到master

##### 主从复制的优缺点

优点：

1. master能自动将数据同步到slave，可以进行读写分离，分担master的读压力
2. master、slave之间的同步是以非阻塞的方式进行的，同步期间，客户端仍然可以提交查询或更新请求

缺点：

1. 不具备自动容错与恢复功能，master或slave的宕机都可能导致客户端请求失败，需要等待机器重启或手动切换客户端IP才能恢复
2. master宕机，如果宕机前数据没有同步完，则切换IP后会存在数据不一致的问题
3. 难以支持在线扩容，Redis的容量受限于单机配置

#### Sentinel（哨兵）模式

##### 基本原理

哨兵模式基于主从复制模式，只是引入了哨兵来监控与自动处理故障

![redis-sentinel](https://p1-jj.byteimg.com/tos-cn-i-t2oaga2asx/gold-user-assets/2020/3/19/170f23893704295e~tplv-t2oaga2asx-zoom-in-crop-mark:4536:0:0:0.awebp)

哨兵顾名思义，就是来为Redis集群站哨的，一旦发现问题能做出相应的应对处理。其功能包括

1. 监控master、slave是否正常运行
2. 当master出现故障时，能自动将一个slave转换为master（大哥挂了，选一个小弟上位）
3. 多个哨兵可以监控同一个Redis，哨兵之间也会自动监控

哨兵模式的具体工作机制：

在配置文件中通过 `sentinel monitor <master-name> <ip> <redis-port> <quorum>` 来定位master的IP、端口，一个哨兵可以监控多个master数据库，只需要提供多个该配置项即可。哨兵启动后，会与要监控的master建立两条连接：

1. 一条连接用来订阅master的`_sentinel_:hello`频道与获取其他监控该master的哨兵节点信息
2. 另一条连接定期向master发送INFO等命令获取master本身的信息

与master建立连接后，哨兵会执行三个操作：

1. 定期（一般10s一次，当master被标记为主观下线时，改为1s一次）向master和slave发送INFO命令
2. 定期向master和slave的`_sentinel_:hello`频道发送自己的信息
3. 定期（1s一次）向master、slave和其他哨兵发送PING命令

发送INFO命令可以获取当前数据库的相关信息从而实现新节点的自动发现。所以说哨兵只需要配置master数据库信息就可以自动发现其slave信息。获取到slave信息后，哨兵也会与slave建立两条连接执行监控。通过INFO命令，哨兵可以获取主从数据库的最新信息，并进行相应的操作，比如角色变更等。

接下来哨兵向主从数据库的_sentinel_:hello频道发送信息与同样监控这些数据库的哨兵共享自己的信息，发送内容为哨兵的ip端口、运行id、配置版本、master名字、master的ip端口还有master的配置版本。这些信息有以下用处：

1. 其他哨兵可以通过该信息判断发送者是否是新发现的哨兵，如果是的话会创建一个到该哨兵的连接用于发送PING命令。
2. 其他哨兵通过该信息可以判断master的版本，如果该版本高于直接记录的版本，将会更新
3. 当实现了自动发现slave和其他哨兵节点后，哨兵就可以通过定期发送PING命令定时监控这些数据库和节点有没有停止服务。

如果被PING的数据库或者节点超时（通过 `sentinel down-after-milliseconds master-name milliseconds` 配置）未回复，哨兵认为其主观下线（sdown，s就是Subjectively —— 主观地）。如果下线的是master，哨兵会向其它哨兵发送命令询问它们是否也认为该master主观下线，如果达到一定数目（即配置文件中的quorum）投票，哨兵会认为该master已经客观下线（odown，o就是Objectively —— 客观地），并选举领头的哨兵节点对主从系统发起故障恢复。若没有足够的sentinel进程同意master下线，master的客观下线状态会被移除，若master重新向sentinel进程发送的PING命令返回有效回复，master的主观下线状态就会被移除

哨兵认为master客观下线后，故障恢复的操作需要由选举的领头哨兵来执行，选举采用Raft算法：

1. 发现master下线的哨兵节点（我们称他为A）向每个哨兵发送命令，要求对方选自己为领头哨兵
2. 如果目标哨兵节点没有选过其他人，则会同意选举A为领头哨兵
3. 如果有超过一半的哨兵同意选举A为领头，则A当选
4. 如果有多个哨兵节点同时参选领头，此时有可能存在一轮投票无竞选者胜出，此时每个参选的节点等待一个随机时间后再次发起参选请求，进行下一轮投票竞选，直至选举出领头哨兵

选出领头哨兵后，领头者开始对系统进行故障恢复，从出现故障的master的从数据库中挑选一个来当选新的master,选择规则如下：

1. 所有在线的slave中选择优先级最高的，优先级可以通过slave-priority配置
2. 如果有多个最高优先级的slave，则选取复制偏移量最大（即复制越完整）的当选
3. 如果以上条件都一样，选取id最小的slave

挑选出需要继任的slave后，领头哨兵向该数据库发送命令使其升格为master，然后再向其他slave发送命令接受新的master，最后更新数据。将已经停止的旧的master更新为新的master的从数据库，使其恢复服务后以slave的身份继续运行。

##### 部署演示

哨兵模式基于前文的主从复制模式。哨兵的配置文件为sentinel.conf，在文件中添加

```shell
sentinel monitor mymaster 127.0.0.1 6379 1 # mymaster定义一个master数据库的名称，后面是master的ip， port，1表示至少需要一个Sentinel进程同意才能将master判断为失效，如果不满足这个条件，则自动故障转移（failover）不会执行
sentinel auth-pass mymaster 123456 # master的密码

sentinel down-after-milliseconds mymaster 5000 # 5s未回复PING，则认为master主观下线，默认为30s
sentinel parallel-syncs mymaster 2  # 指定在执行故障转移时，最多可以有多少个slave实例在同步新的master实例，在slave实例较多的情况下这个数字越小，同步的时间越长，完成故障转移所需的时间就越长
sentinel failover-timeout mymaster 300000 # 如果在该时间（ms）内未能完成故障转移操作，则认为故障转移失败，生产环境需要根据数据量设置该值
```

> 一个哨兵可以监控多个master数据库，只需按上述配置添加多套

分别以26379,36379,46379端口启动三个sentinel

```shell
[root@dev-server-1 sentinel]# redis-server sentinel1.conf --sentinel
[root@dev-server-1 sentinel]# redis-server sentinel2.conf --sentinel
[root@dev-server-1 sentinel]# redis-server sentinel3.conf --sentinel
```

也可以使用`redis-sentinel sentinel1.conf` 命令启动。此时集群包含一个master、两个slave、三个sentinel

我们来模拟master挂掉的场景，执行 `kill -9 3017` 将master进程干掉，进入slave中执行 `info replication`查看

```shell
[root@dev-server-1 sentinel]# redis-cli -p 7001
127.0.0.1:7001> auth 123456
OK
127.0.0.1:7001> info replication
# Replication
role:slave
master_host:127.0.0.1
master_port:7002
master_link_status:up
master_last_io_seconds_ago:1
master_sync_in_progress:0
# 省略
127.0.0.1:7001> exit
[root@dev-server-1 sentinel]# redis-cli -p 7002
127.0.0.1:7002> auth 123456
OK
127.0.0.1:7002> info replication
# Replication
role:master
connected_slaves:1
slave0:ip=127.0.0.1,port=7001,state=online,offset=13642721,lag=1
# 省略
```

可以看到slave 7002已经成功上位晋升为master（role：master），接收一个slave 7001的连接。此时查看slave2.conf配置文件，发现`replicaof`的配置已经被移除了，slave1.conf的配置文件里`replicaof 127.0.0.1 6379` 被改为 `replicaof 127.0.0.1 7002`。重新启动master，也可以看到master.conf配置文件中添加了`replicaof 127.0.0.1 7002`的配置项，可见大哥（master）下位后，再出来混就只能当当小弟（slave）了，三十年河东三十年河西。

##### 哨兵模式的优缺点

优点：

1. 哨兵模式基于主从复制模式，所以主从复制模式有的优点，哨兵模式也有
2. 哨兵模式下，master挂掉可以自动进行切换，系统可用性更高

缺点：

1. 同样也继承了主从模式难以在线扩容的缺点，Redis的容量受限于单机配置
2. 需要额外的资源来启动sentinel进程，实现相对复杂一点，同时slave节点作为备份节点不提供服务

#### Cluster模式

##### 基本原理

哨兵模式解决了主从复制不能自动故障转移，达不到高可用的问题，但还是存在难以在线扩容，Redis容量受限于单机配置的问题。Cluster模式实现了Redis的分布式存储，即每台节点存储不同的内容，来解决在线扩容的问题。如图

![redis-cluster](https://p1-jj.byteimg.com/tos-cn-i-t2oaga2asx/gold-user-assets/2020/3/19/170f238bca333f96~tplv-t2oaga2asx-zoom-in-crop-mark:4536:0:0:0.awebp)

Cluster采用无中心结构,它的特点如下：

1. 所有的redis节点彼此互联(PING-PONG机制),内部使用二进制协议优化传输速度和带宽
2. 节点的fail是通过集群中超过半数的节点检测失效时才生效
3. 客户端与redis节点直连,不需要中间代理层.客户端不需要连接集群所有节点,连接集群中任何一个可用节点即可

Cluster模式的具体工作机制：

1. 在Redis的每个节点上，都有一个插槽（slot），取值范围为0-16383
2. 当我们存取key的时候，Redis会根据CRC16的算法得出一个结果，然后把结果对16384求余数，这样每个key都会对应一个编号在0-16383之间的哈希槽，通过这个值，去找到对应的插槽所对应的节点，然后直接自动跳转到这个对应的节点上进行存取操作
3. 为了保证高可用，Cluster模式也引入主从复制模式，一个主节点对应一个或者多个从节点，当主节点宕机的时候，就会启用从节点
4. 当其它主节点ping一个主节点A时，如果半数以上的主节点与A通信超时，那么认为主节点A宕机了。如果主节点A和它的从节点都宕机了，那么该集群就无法再提供服务了

Cluster模式集群节点最小配置6个节点(3主3从，因为需要半数以上)，其中主节点提供读写操作，从节点作为备用节点，不提供请求，只作为故障转移使用。

##### 部署演示

Cluster模式的部署比较简单，首先在redis.conf中

```shell
port 7100 # 本示例6个节点端口分别为7100,7200,7300,7400,7500,7600 
daemonize yes # r后台运行 
pidfile /var/run/redis_7100.pid # pidfile文件对应7100,7200,7300,7400,7500,7600 
cluster-enabled yes # 开启集群模式 
masterauth passw0rd # 如果设置了密码，需要指定master密码
cluster-config-file nodes_7100.conf # 集群的配置文件，同样对应7100,7200等六个节点
cluster-node-timeout 15000 # 请求超时 默认15秒，可自行设置 
```

分别以端口7100,7200,7300,7400,7500,7600 启动六个实例(如果是每个服务器一个实例则配置可一样)

```shell
[root@dev-server-1 cluster]# redis-server redis_7100.conf
[root@dev-server-1 cluster]# redis-server redis_7200.conf
...
```

然后通过命令将这个6个实例组成一个3主节点3从节点的集群

```shell
redis-cli --cluster create --cluster-replicas 1 127.0.0.1:7100 127.0.0.1:7200 127.0.0.1:7300 127.0.0.1:7400 127.0.0.1:7500 127.0.0.1:7600 -a passw0rd
```

执行结果如图

![redis-cluster-deploy](https://p1-jj.byteimg.com/tos-cn-i-t2oaga2asx/gold-user-assets/2020/3/19/170f238d683bd472~tplv-t2oaga2asx-zoom-in-crop-mark:4536:0:0:0.awebp)

可以看到 7100， 7200， 7300 作为3个主节点，分配的slot分别为 0-5460， 5461-10922， 10923-16383， 7600作为7100的slave， 7500作为7300的slave，7400作为7200的slave。

我们连接7100设置一个值

```shell
[root@dev-server-1 cluster]# redis-cli -p 7100 -c -a passw0rd
Warning: Using a password with '-a' or '-u' option on the command line interface may not be safe.
127.0.0.1:7100> set site blog.jboost
-> Redirected to slot [9421] located at 127.0.0.1:7200
OK
127.0.0.1:7200> get site
"blog.jboost"
127.0.0.1:7200>
```

注意添加 -c 参数表示以集群模式，否则报 `(error) MOVED 9421 127.0.0.1:7200` 错误， 以 -a 参数指定密码，否则报`(error) NOAUTH Authentication required`错误。

从上面命令看到key为site算出的slot为9421，落在7200节点上，所以有`Redirected to slot [9421] located at 127.0.0.1:7200`，集群会自动进行跳转。因此客户端可以连接任何一个节点来进行数据的存取。

通过`cluster nodes`可查看集群的节点信息

```shell
127.0.0.1:7200> cluster nodes
eb28aaf090ed1b6b05033335e3d90a202b422d6c 127.0.0.1:7500@17500 slave c1047de2a1b5d5fa4666d554376ca8960895a955 0 1584165266071 5 connected
4cc0463878ae00e5dcf0b36c4345182e021932bc 127.0.0.1:7400@17400 slave 5544aa5ff20f14c4c3665476de6e537d76316b4a 0 1584165267074 4 connected
dbbb6420d64db22f35a9b6fa460b0878c172a2fb 127.0.0.1:7100@17100 master - 0 1584165266000 1 connected 0-5460
d4b434f5829e73e7e779147e905eea6247ffa5a2 127.0.0.1:7600@17600 slave dbbb6420d64db22f35a9b6fa460b0878c172a2fb 0 1584165265000 6 connected
5544aa5ff20f14c4c3665476de6e537d76316b4a 127.0.0.1:7200@17200 myself,master - 0 1584165267000 2 connected 5461-10922
c1047de2a1b5d5fa4666d554376ca8960895a955 127.0.0.1:7300@17300 master - 0 1584165268076 3 connected 10923-16383
```

我们将7200通过 `kill -9 pid`杀死进程来验证集群的高可用，重新进入集群执行`cluster nodes`可以看到7200 fail了，但是7400成了master，重新启动7200，可以看到此时7200已经变成了slave。

##### Cluster模式的优缺点

优点：

1. 无中心架构，数据按照slot分布在多个节点。
2. 集群中的每个节点都是平等的关系，每个节点都保存各自的数据和整个集群的状态。每个节点都和其他所有节点连接，而且这些连接保持活跃，这样就保证了我们只需要连接集群中的任意一个节点，就可以获取到其他节点的数据。
3. 可线性扩展到1000多个节点，节点可动态添加或删除
4. 能够实现自动故障转移，节点之间通过gossip协议交换状态信息，用投票机制完成slave到master的角色转换

缺点：

1. 客户端实现复杂，驱动要求实现Smart Client，缓存slots mapping信息并及时更新，提高了开发难度。目前仅JedisCluster相对成熟，异常处理还不完善，比如常见的“max redirect exception”
2. 节点会因为某些原因发生阻塞（阻塞时间大于 cluster-node-timeout）被判断下线，这种failover是没有必要的
3. 数据通过异步复制，不保证数据的强一致性
4. slave充当“冷备”，不能缓解读压力
5. 批量操作限制，目前只支持具有相同slot值的key执行批量操作，对mset、mget、sunion等操作支持不友好
6. key事务操作支持有线，只支持多key在同一节点的事务操作，多key分布不同节点时无法使用事务功能
7. 不支持多数据库空间，单机redis可以支持16个db，集群模式下只能使用一个，即db 0

Redis Cluster模式不建议使用pipeline和multi-keys操作，减少max redirect产生的场景。

#### 总结

本文介绍了Redis集群方案的三种模式，其中主从复制模式能实现读写分离，但是不能自动故障转移；哨兵模式基于主从复制模式，能实现自动故障转移，达到高可用，但与主从复制模式一样，不能在线扩容，容量受限于单机的配置；Cluster模式通过无中心化架构，实现分布式存储，可进行线性扩展，也能高可用，但对于像批量操作、事务操作等的支持性不够好。三种模式各有优缺点，可根据实际场景进行选择

### Redis数据类型

> 首先对redis来说，所有的key（键）都是字符串。我们在谈基础数据结构时，讨论的是存储值的数据类型，主要包括常见的5种数据类型，分别是：String、List、Set、Zset、Hash。

![img](https://pdai.tech/_images/db/redis/db-redis-ds-1.jpeg)

| 结构类型         | 结构存储的值                               | 结构的读写能力                                               |
| ---------------- | ------------------------------------------ | ------------------------------------------------------------ |
| **String字符串** | 可以是字符串、整数或浮点数                 | 对整个字符串或字符串的一部分进行操作；对整数或浮点数进行自增或自减操作； |
| **List列表**     | 一个链表，链表上的每个节点都包含一个字符串 | 对链表的两端进行push和pop操作，读取单个或多个元素；根据值查找或删除元素； |
| **Set集合**      | 包含字符串的无序集合                       | 字符串的集合，包含基础的方法有看是否存在添加、获取、删除；还包含计算交集、并集、差集等 |
| **Hash散列**     | 包含键值对的无序散列表                     | 包含方法有添加、获取、删除单个元素                           |
| **Zset有序集合** | 和散列一样，用于存储键值对                 | 字符串成员与浮点数分数之间的有序映射；元素的排列顺序由分数的大小决定；包含方法有添加、获取、删除单个元素以及根据分值范围或成员来获取元素 |

#### String字符串

> String是redis中最基本的数据类型，一个key对应一个value。

- **命令使用**

| 命令   | 简述                   | 使用              |
| ------ | ---------------------- | ----------------- |
| GET    | 获取存储在给定键中的值 | GET name          |
| SET    | 设置存储在给定键中的值 | SET name value    |
| DEL    | 删除存储在给定键中的值 | DEL name          |
| INCR   | 将键存储的值加1        | INCR key          |
| DECR   | 将键存储的值减1        | DECR key          |
| INCRBY | 将键存储的值加上整数   | INCRBY key amount |
| DECRBY | 将键存储的值减去整数   | DECRBY key amount |

------

- **命令执行**

```shell
127.0.0.1:6379> set hello world
OK
127.0.0.1:6379> get hello
"world"
127.0.0.1:6379> del hello
(integer) 1
127.0.0.1:6379> get hello
(nil)
127.0.0.1:6379> set counter 2
OK
127.0.0.1:6379> get counter
"2"
127.0.0.1:6379> incr counter
(integer) 3
127.0.0.1:6379> get counter
"3"
127.0.0.1:6379> incrby counter 100
(integer) 103
127.0.0.1:6379> get counter
"103"
127.0.0.1:6379> decr counter
(integer) 102
127.0.0.1:6379> get counter
"102"
```

#### List列表

> Redis中的List其实就是链表（Redis用双端链表实现List）。

- **命令使用**

| 命令   | 简述                                                         | 使用             |
| ------ | ------------------------------------------------------------ | ---------------- |
| RPUSH  | 将给定值推入到列表右端                                       | RPUSH key value  |
| LPUSH  | 将给定值推入到列表左端                                       | LPUSH key value  |
| RPOP   | 从列表的右端弹出一个值，并返回被弹出的值                     | RPOP key         |
| LPOP   | 从列表的左端弹出一个值，并返回被弹出的值                     | LPOP key         |
| LRANGE | 获取列表在给定范围上的所有值                                 | LRANGE key 0 -1  |
| LINDEX | 通过索引获取列表中的元素。你也可以使用负数下标，以 -1 表示列表的最后一个元素， -2 表示列表的倒数第二个元素，以此类推。 | LINDEX key index |

------

- 使用列表的技巧
  - lpush+lpop=Stack(栈)
  - lpush+rpop=Queue（队列）
  - lpush+ltrim=Capped Collection（有限集合）
  - lpush+brpop=Message Queue（消息队列）
- **命令执行**

```bash
127.0.0.1:6379> lpush mylist 1 2 ll ls mem
(integer) 5
127.0.0.1:6379> lrange mylist 0 -1
1) "mem"
2) "ls"
3) "ll"
4) "2"
5) "1"
127.0.0.1:6379> lindex mylist -1
"1"
127.0.0.1:6379> lindex mylist 10        # index不在 mylist 的区间范围内
(nil)
```

#### Set集合

> Redis 的 Set 是 String 类型的无序集合。集合成员是唯一的，这就意味着集合中不能出现重复的数据。

- **命令使用**

| 命令      | 简述                                  | 使用                 |
| --------- | ------------------------------------- | -------------------- |
| SADD      | 向集合添加一个或多个成员              | SADD key value       |
| SCARD     | 获取集合的成员数                      | SCARD key            |
| SMEMBERS  | 返回集合中的所有成员                  | SMEMBERS key member  |
| SISMEMBER | 判断 member 元素是否是集合 key 的成员 | SISMEMBER key member |

------

- **命令执行**

```bash
127.0.0.1:6379> sadd myset hao hao1 xiaohao hao
(integer) 3
127.0.0.1:6379> smembers myset
1) "xiaohao"
2) "hao1"
3) "hao"
127.0.0.1:6379> sismember myset hao
(integer) 1
```

#### Hash散列

- **命令使用**

| 命令    | 简述                                     | 使用                          |
| ------- | ---------------------------------------- | ----------------------------- |
| HSET    | 添加键值对                               | HSET hash-key sub-key1 value1 |
| HGET    | 获取指定散列键的值                       | HGET hash-key key1            |
| HGETALL | 获取散列中包含的所有键值对               | HGETALL hash-key              |
| HDEL    | 如果给定键存在于散列中，那么就移除这个键 | HDEL hash-key sub-key1        |

------

- **命令执行**

```bash
127.0.0.1:6379> hset user name1 hao
(integer) 1
127.0.0.1:6379> hset user email1 hao@163.com
(integer) 1
127.0.0.1:6379> hgetall user
1) "name1"
2) "hao"
3) "email1"
4) "hao@163.com"
127.0.0.1:6379> hget user user
(nil)
127.0.0.1:6379> hget user name1
"hao"
127.0.0.1:6379> hset user name2 xiaohao
(integer) 1
127.0.0.1:6379> hset user email2 xiaohao@163.com
(integer) 1
127.0.0.1:6379> hgetall user
1) "name1"
2) "hao"
3) "email1"
4) "hao@163.com"
5) "name2"
6) "xiaohao"
7) "email2"
8) "xiaohao@163.com"
```

#### Zset有序集合

> Redis 有序集合和集合一样也是 string 类型元素的集合,且不允许重复的成员。不同的是每个元素都会关联一个 double 类型的分数。redis 正是通过分数来为集合中的成员进行从小到大的排序。

有序集合的成员是唯一的, 但分数(score)却可以重复。有序集合是通过两种数据结构实现：

1. **压缩列表(ziplist)**: ziplist是为了提高存储效率而设计的一种特殊编码的双向链表。它可以存储字符串或者整数，存储整数时是采用整数的二进制而不是字符串形式存储。它能在O(1)的时间复杂度下完成list两端的push和pop操作。但是因为每次操作都需要重新分配ziplist的内存，所以实际复杂度和ziplist的内存使用量相关
2. **跳跃表（zSkiplist)**: 跳跃表的性能可以保证在查找，删除，添加等操作的时候在对数期望时间内完成，这个性能是可以和平衡树来相比较的，而且在实现方面比平衡树要优雅，这是采用跳跃表的主要原因。跳跃表的复杂度是O(log(n))。

- **命令使用**

| 命令   | 简述                                                     | 使用                           |
| ------ | -------------------------------------------------------- | ------------------------------ |
| ZADD   | 将一个带有给定分值的成员添加到有序集合里面               | ZADD zset-key 178 member1      |
| ZRANGE | 根据元素在有序集合中所处的位置，从有序集合中获取多个元素 | ZRANGE zset-key 0-1 withccores |
| ZREM   | 如果给定元素成员存在于有序集合中，那么就移除这个元素     | ZREM zset-key member1          |

更多命令请参考这里 https://www.runoob.com/redis/redis-sorted-sets.html

- **命令执行**

```bash
127.0.0.1:6379> zadd myscoreset 100 hao 90 xiaohao
(integer) 2
127.0.0.1:6379> ZRANGE myscoreset 0 -1
1) "xiaohao"
2) "hao"
127.0.0.1:6379> ZSCORE myscoreset hao
"100"
```

### redis配置文件中常用配置详解

#### NETWORK

**###################################  NETWORK ###################################**

```shell
# 指定 redis 只接收来自于该IP地址的请求，如果不进行设置，那么将处理所有请求
bind 127.0.0.1
 
#是否开启保护模式，默认开启。要是配置里没有指定bind和密码。开启该参数后，redis只会本地进行访问，
拒绝外部访问。要是开启了密码和bind，可以开启。否则最好关闭，设置为no
protected-mode yes
 
#redis监听的端口号
port 6379
 
#此参数确定了TCP连接中已完成队列(完成三次握手之后)的长度， 当然此值必须不大于Linux系统定义
的/proc/sys/net/core/somaxconn值，默认是511，而Linux的默认参数值是128。当系统并发量大并且客户端
速度缓慢的时候，可以将这二个参数一起参考设定。该内核参数默认值一般是128，对于负载很大的服务程序来说
大大的不够。一般会将它修改为2048或者更大。在/etc/sysctl.conf中添加:net.core.somaxconn = 2048，
然后在终端中执行sysctl -p
tcp-backlog 511
 
#此参数为设置客户端空闲超过timeout，服务端会断开连接，为0则服务端不会主动断开连接，不能小于0
timeout 0
 
#tcp keepalive参数。如果设置不为0，就使用配置tcp的SO_KEEPALIVE值，使用keepalive有两个好处:检测挂
掉的对端。降低中间设备出问题而导致网络看似连接却已经与对端端口的问题。在Linux内核中，设置了
keepalive，redis会定时给对端发送ack。检测到对端关闭需要两倍的设置值
tcp-keepalive 300
 
#是否在后台执行，yes：后台运行；no：不是后台运行
daemonize yes
 
#redis的进程文件
pidfile /var/run/redis/redis.pid
 
#指定了服务端日志的级别。级别包括：debug（很多信息，方便开发、测试），verbose（许多有用的信息，
但是没有debug级别信息多），notice（适当的日志级别，适合生产环境），warn（只有非常重要的信息）
loglevel notice
 
#指定了记录日志的文件。空字符串的话，日志会打印到标准输出设备。后台运行的redis标准输出是/dev/null
logfile /usr/local/redis/var/redis.log
 
 
#是否打开记录syslog功能
# syslog-enabled no
 
#syslog的标识符。
# syslog-ident redis
 
#日志的来源、设备
# syslog-facility local0
 
#数据库的数量，默认使用的数据库是0。可以通过”SELECT 【数据库序号】“命令选择一个数据库，序号从0开始
databases 16
```

#### SNAPSHOTTING

**################################# SNAPSHOTTING  #################################** 

```shell
###################################  SNAPSHOTTING  ###################################
 
#RDB核心规则配置 save <指定时间间隔> <执行指定次数更新操作>，满足条件就将内存中的数据同步到硬盘
中。官方出厂配置默认是 900秒内有1个更改，300秒内有10个更改以及60秒内有10000个更改，则将内存中的
数据快照写入磁盘。
若不想用RDB方案，可以把 save "" 的注释打开，下面三个注释
#   save ""
save 900 1
save 300 10
save 60 10000
 
#当RDB持久化出现错误后，是否依然进行继续进行工作，yes：不能进行工作，no：可以继续进行工作，可以通
过info中的rdb_last_bgsave_status了解RDB持久化是否有错误
stop-writes-on-bgsave-error yes
 
#配置存储至本地数据库时是否压缩数据，默认为yes。Redis采用LZF压缩方式，但占用了一点CPU的时间。若关闭该选项，
但会导致数据库文件变的巨大。建议开启。
rdbcompression yes
 
#是否校验rdb文件;从rdb格式的第五个版本开始，在rdb文件的末尾会带上CRC64的校验和。这跟有利于文件的
容错性，但是在保存rdb文件的时候，会有大概10%的性能损耗，所以如果你追求高性能，可以关闭该配置
rdbchecksum yes
 
#指定本地数据库文件名，一般采用默认的 dump.rdb
dbfilename dump.rdb
 
#数据目录，数据库的写入会在这个目录。rdb、aof文件也会写在这个目录
dir /usr/local/redis/var
```

#### REPLICATION

**################################# REPLICATION  #################################**

```shell
################################# REPLICATION #################################
 
# 复制选项，slave复制对应的master。
# replicaof <masterip> <masterport>
 
#如果master设置了requirepass，那么slave要连上master，需要有master的密码才行。masterauth就是用来
配置master的密码，这样可以在连上master后进行认证。
# masterauth <master-password>
 
#当从库同主机失去连接或者复制正在进行，从机库有两种运行方式：1) 如果slave-serve-stale-data设置为
yes(默认设置)，从库会继续响应客户端的请求。2) 如果slave-serve-stale-data设置为no，
INFO,replicaOF, AUTH, PING, SHUTDOWN, REPLCONF, ROLE, CONFIG,SUBSCRIBE, UNSUBSCRIBE,
PSUBSCRIBE, PUNSUBSCRIBE, PUBLISH, PUBSUB,COMMAND, POST, HOST: and LATENCY命令之外的任何请求
都会返回一个错误”SYNC with master in progress”。
replica-serve-stale-data yes
 
#作为从服务器，默认情况下是只读的（yes），可以修改成NO，用于写（不建议）
#replica-read-only yes
 
# 是否使用socket方式复制数据。目前redis复制提供两种方式，disk和socket。如果新的slave连上来或者
重连的slave无法部分同步，就会执行全量同步，master会生成rdb文件。有2种方式：disk方式是master创建
一个新的进程把rdb文件保存到磁盘，再把磁盘上的rdb文件传递给slave。socket是master创建一个新的进
程，直接把rdb文件以socket的方式发给slave。disk方式的时候，当一个rdb保存的过程中，多个slave都能
共享这个rdb文件。socket的方式就的一个个slave顺序复制。在磁盘速度缓慢，网速快的情况下推荐用socket方式。
repl-diskless-sync no
 
#diskless复制的延迟时间，防止设置为0。一旦复制开始，节点不会再接收新slave的复制请求直到下一个rdb传输。
所以最好等待一段时间，等更多的slave连上来
repl-diskless-sync-delay 5
 
#slave根据指定的时间间隔向服务器发送ping请求。时间间隔可以通过 repl_ping_slave_period 来设置，默认10秒。
# repl-ping-slave-period 10
 
# 复制连接超时时间。master和slave都有超时时间的设置。master检测到slave上次发送的时间超过repl-timeout，即认为slave离线，清除该slave信息。slave检测到上次和master交互的时间超过repl-timeout，则认为master离线。需要注意的是repl-timeout需要设置一个比repl-ping-slave-period更大的值，不然会经常检测到超时
# repl-timeout 60
 
 
#是否禁止复制tcp链接的tcp nodelay参数，可传递yes或者no。默认是no，即使用tcp nodelay。如果
master设置了yes来禁止tcp nodelay设置，在把数据复制给slave的时候，会减少包的数量和更小的网络带
宽。但是这也可能带来数据的延迟。默认我们推荐更小的延迟，但是在数据量传输很大的场景下，建议选择yes
repl-disable-tcp-nodelay no
 
#复制缓冲区大小，这是一个环形复制缓冲区，用来保存最新复制的命令。这样在slave离线的时候，不需要完
全复制master的数据，如果可以执行部分同步，只需要把缓冲区的部分数据复制给slave，就能恢复正常复制状
态。缓冲区的大小越大，slave离线的时间可以更长，复制缓冲区只有在有slave连接的时候才分配内存。没有
slave的一段时间，内存会被释放出来，默认1m
# repl-backlog-size 1mb
 
# master没有slave一段时间会释放复制缓冲区的内存，repl-backlog-ttl用来设置该时间长度。单位为秒。
# repl-backlog-ttl 3600
 
# 当master不可用，Sentinel会根据slave的优先级选举一个master。最低的优先级的slave，当选master。
而配置成0，永远不会被选举
replica-priority 100
 
#redis提供了可以让master停止写入的方式，如果配置了min-replicas-to-write，健康的slave的个数小于N，mater就禁止写入。master最少得有多少个健康的slave存活才能执行写命令。这个配置虽然不能保证N个slave都一定能接收到master的写操作，但是能避免没有足够健康的slave的时候，master不能写入来避免数据丢失。设置为0是关闭该功能
# min-replicas-to-write 3
 
# 延迟小于min-replicas-max-lag秒的slave才认为是健康的slave
# min-replicas-max-lag 10
 
# 设置1或另一个设置为0禁用这个特性。
# Setting one or the other to 0 disables the feature.
# By default min-replicas-to-write is set to 0 (feature disabled) and
# min-replicas-max-lag is set to 10.
```

#### SECURITY

**################################# SECURITY #################################**

```shell
 
#requirepass配置可以让用户使用AUTH命令来认证密码，才能使用其他命令。这让redis可以使用在不受信任的
网络中。为了保持向后的兼容性，可以注释该命令，因为大部分用户也不需要认证。使用requirepass的时候需要
注意，因为redis太快了，每秒可以认证15w次密码，简单的密码很容易被攻破，所以最好使用一个更复杂的密码
# requirepass foobared
 
#把危险的命令给修改成其他名称。比如CONFIG命令可以重命名为一个很难被猜到的命令，这样用户不能使用，而
内部工具还能接着使用
# rename-command CONFIG b840fc02d524045429941cc15f59e41cb7be6c52
 
#设置成一个空的值，可以禁止一个命令
# rename-command CONFIG ""
```

#### CLIENTS 

**################################# CLIENTS #################################**

```shell
# 设置能连上redis的最大客户端连接数量。默认是10000个客户端连接。由于redis不区分连接是客户端连接还
是内部打开文件或者和slave连接等，所以maxclients最小建议设置到32。如果超过了maxclients，redis会给
新的连接发送’max number of clients reached’，并关闭连接
# maxclients 10000
```

#### MEMORY MANAGEMENT 

**#######################  MEMORY MANAGEMENT  ##########################**

```shell
redis配置的最大内存容量。当内存满了，需要配合maxmemory-policy策略进行处理。注意slave的输出缓冲区
是不计算在maxmemory内的。所以为了防止主机内存使用完，建议设置的maxmemory需要更小一些
maxmemory 122000000
 
#内存容量超过maxmemory后的处理策略。
#volatile-lru：利用LRU算法移除设置过过期时间的key。
#volatile-random：随机移除设置过过期时间的key。
#volatile-ttl：移除即将过期的key，根据最近过期时间来删除（辅以TTL）
#allkeys-lru：利用LRU算法移除任何key。
#allkeys-random：随机移除任何key。
#noeviction：不移除任何key，只是返回一个写错误。
#上面的这些驱逐策略，如果redis没有合适的key驱逐，对于写命令，还是会返回错误。redis将不再接收写请求，只接收get请求。写命令包括：set setnx setex append incr decr rpush lpush rpushx lpushx linsert lset rpoplpush sadd sinter sinterstore sunion sunionstore sdiff sdiffstore zadd zincrby zunionstore zinterstore hset hsetnx hmset hincrby incrby decrby getset mset msetnx exec sort。
# maxmemory-policy noeviction
 
# lru检测的样本数。使用lru或者ttl淘汰算法，从需要淘汰的列表中随机选择sample个key，选出闲置时间最长的key移除
# maxmemory-samples 5
 
# 是否开启salve的最大内存
# replica-ignore-maxmemory yes
```

#### LAZY FREEING

**##########################  LAZY FREEING  #############################**

```shell
#以非阻塞方式释放内存
#使用以下配置指令调用了
lazyfree-lazy-eviction no
lazyfree-lazy-expire no
lazyfree-lazy-server-del no
replica-lazy-flush no
```

#### APPEND ONLY MODE 

**########################  APPEND ONLY MODE  ###########################**

```shell
#Redis 默认不开启。它的出现是为了弥补RDB的不足（数据的不一致性），所以它采用日志的形式来记录每个写
操作，并追加到文件中。Redis 重启的会根据日志文件的内容将写指令从前到后执行一次以完成数据的恢复工作
默认redis使用的是rdb方式持久化，这种方式在许多应用中已经足够用了。但是redis如果中途宕机，会导致可
能有几分钟的数据丢失，根据save来策略进行持久化，Append Only File是另一种持久化方式，可以提供更好的
持久化特性。Redis会把每次写入的数据在接收后都写入 appendonly.aof 文件，每次启动时Redis都会先把这
个文件的数据读入内存里，先忽略RDB文件。若开启rdb则将no改为yes
appendonly no
 
指定本地数据库文件名，默认值为 appendonly.aof
appendfilename "appendonly.aof"
 
 
#aof持久化策略的配置
#no表示不执行fsync，由操作系统保证数据同步到磁盘，速度最快
#always表示每次写入都执行fsync，以保证数据同步到磁盘
#everysec表示每秒执行一次fsync，可能会导致丢失这1s数据
# appendfsync always
appendfsync everysec
# appendfsync no
 
# 在aof重写或者写入rdb文件的时候，会执行大量IO，此时对于everysec和always的aof模式来说，执行
fsync会造成阻塞过长时间，no-appendfsync-on-rewrite字段设置为默认设置为no。如果对延迟要求很高的
应用，这个字段可以设置为yes，否则还是设置为no，这样对持久化特性来说这是更安全的选择。设置为yes表
示rewrite期间对新写操作不fsync,暂时存在内存中,等rewrite完成后再写入，默认为no，建议yes。Linux的
默认fsync策略是30秒。可能丢失30秒数据
no-appendfsync-on-rewrite no
 
#aof自动重写配置。当目前aof文件大小超过上一次重写的aof文件大小的百分之多少进行重写，即当aof文件
增长到一定大小的时候Redis能够调用bgrewriteaof对日志文件进行重写。当前AOF文件大小是上次日志重写得
到AOF文件大小的二倍（设置为100）时，自动启动新的日志重写过程
auto-aof-rewrite-percentage 100
 
#设置允许重写的最小aof文件大小，避免了达到约定百分比但尺寸仍然很小的情况还要重写
auto-aof-rewrite-min-size 64mb
 
#aof文件可能在尾部是不完整的，当redis启动的时候，aof文件的数据被载入内存。重启可能发生在redis所
在的主机操作系统宕机后，尤其在ext4文件系统没有加上data=ordered选项（redis宕机或者异常终止不会造
成尾部不完整现象。）出现这种现象，可以选择让redis退出，或者导入尽可能多的数据。如果选择的是yes，
当截断的aof文件被导入的时候，会自动发布一个log给客户端然后load。如果是no，用户必须手动redis-
check-aof修复AOF文件才可以
aof-load-truncated yes
 
#加载redis时，可以识别AOF文件以“redis”开头。
#字符串并加载带前缀的RDB文件，然后继续加载AOF尾巴
aof-use-rdb-preamble yes
```

#### LUA SCRIPTING 

**#########################  LUA SCRIPTING   ############################**

```shell
# 如果达到最大时间限制（毫秒），redis会记个log，然后返回error。当一个脚本超过了最大时限。只有
SCRIPT KILL和SHUTDOWN NOSAVE可以用。第一个可以杀没有调write命令的东西。要是已经调用了write，只能
用第二个命令杀
lua-time-limit 5000
```

#### REDIS CLUSTER 

**#########################  REDIS CLUSTER   ############################**

```shell
# 集群开关，默认是不开启集群模式
# cluster-enabled yes
 
#集群配置文件的名称，每个节点都有一个集群相关的配置文件，持久化保存集群的信息。这个文件并不需要手动
配置，这个配置文件有Redis生成并更新，每个Redis集群节点需要一个单独的配置文件，请确保与实例运行的系
统中配置文件名称不冲突
# cluster-config-file nodes-6379.conf
 
#节点互连超时的阀值。集群节点超时毫秒数
# cluster-node-timeout 15000
 
#在进行故障转移的时候，全部slave都会请求申请为master，但是有些slave可能与master断开连接一段时间
了，导致数据过于陈旧，这样的slave不应该被提升为master。该参数就是用来判断slave节点与master断线的时
间是否过长。判断方法是：
#比较slave断开连接的时间和(node-timeout * slave-validity-factor) + repl-ping-slave-period
#如果节点超时时间为三十秒, 并且slave-validity-factor为10,假设默认的repl-ping-slave-period是10
秒，即如果超过310秒slave将不会尝试进行故障转移
# cluster-replica-validity-factor 10
 
# master的slave数量大于该值，slave才能迁移到其他孤立master上，如这个参数若被设为2，那么只有当一
个主节点拥有2 个可工作的从节点时，它的一个从节点会尝试迁移
# cluster-migration-barrier 1
 
#默认情况下，集群全部的slot有节点负责，集群状态才为ok，才能提供服务。设置为no，可以在slot没有全
部分配的时候提供服务。不建议打开该配置，这样会造成分区的时候，小分区的master一直在接受写请求，而
造成很长时间数据不一致
# cluster-require-full-coverage yes
```

#### CLUSTER DOCKER/NAT support

**#################### CLUSTER DOCKER/NAT support #######################**

```shell
#*群集公告IP
#*群集公告端口
#*群集公告总线端口
# Example:
#
# cluster-announce-ip 10.1.1.5
# cluster-announce-port 6379
# cluster-announce-bus-port 6380
```

#### SLOW LOG 

**############################# SLOW LOG #################################**

```shell
# slog log是用来记录redis运行中执行比较慢的命令耗时。当命令的执行超过了指定时间，就记录在slow log
中，slog log保存在内存中，所以没有IO操作。
#执行时间比slowlog-log-slower-than大的请求记录到slowlog里面，单位是微秒，所以1000000就是1秒。注
意，负数时间会禁用慢查询日志，而0则会强制记录所有命令。
slowlog-log-slower-than 10000
 
#慢查询日志长度。当一个新的命令被写进日志的时候，最老的那个记录会被删掉。这个长度没有限制。只要有足
够的内存就行。你可以通过 SLOWLOG RESET 来释放内存
slowlog-max-len 128
```

#### LATENCY MONITOR 

**######################## LATENCY MONITOR ############################**

```shell
#延迟监控功能是用来监控redis中执行比较缓慢的一些操作，用LATENCY打印redis实例在跑命令时的耗时图表。
只记录大于等于下边设置的值的操作。0的话，就是关闭监视。默认延迟监控功能是关闭的，如果你需要打开，也
可以通过CONFIG SET命令动态设置
latency-monitor-threshold 0
```

#### EVENT NOTIFICATION

**####################### EVENT NOTIFICATION ###########################**

```shell
#键空间通知使得客户端可以通过订阅频道或模式，来接收那些以某种方式改动了 Redis 数据集的事件。因为开启键空间通知功能需要消耗一些 CPU ，所以在默认配置下，该功能处于关闭状态。
#notify-keyspace-events 的参数可以是以下字符的任意组合，它指定了服务器该发送哪些类型的通知：
##K 键空间通知，所有通知以 __keyspace@__ 为前缀
##E 键事件通知，所有通知以 __keyevent@__ 为前缀
##g DEL 、 EXPIRE 、 RENAME 等类型无关的通用命令的通知
##$ 字符串命令的通知
##l 列表命令的通知
##s 集合命令的通知
##h 哈希命令的通知
##z 有序集合命令的通知
##x 过期事件：每当有过期键被删除时发送
##e 驱逐(evict)事件：每当有键因为 maxmemory 政策而被删除时发送
##A 参数 g$lshzxe 的别名
#输入的参数中至少要有一个 K 或者 E，否则的话，不管其余的参数是什么，都不会有任何 通知被分发。详细使用可以参考http://redis.io/topics/notifications
 
notify-keyspace-events ""
```

#### ADVANCED CONFIG 

**####################### ADVANCED CONFIG ###########################**

```shell
# 数据量小于等于hash-max-ziplist-entries的用ziplist，大于hash-max-ziplist-entries用hash
hash-max-ziplist-entries 512
 
# value大小小于等于hash-max-ziplist-value的用ziplist，大于hash-max-ziplist-value用hash
hash-max-ziplist-value 64
 
#-5:最大大小：64 KB<--不建议用于正常工作负载
#-4:最大大小：32 KB<--不推荐
#-3:最大大小：16 KB<--可能不推荐
#-2:最大大小：8kb<--良好
#-1:最大大小：4kb<--良好
list-max-ziplist-size -2
 
#0:禁用所有列表压缩
#1：深度1表示“在列表中的1个节点之后才开始压缩，
#从头部或尾部
#所以：【head】->node->node->…->node->【tail】
#[头部]，[尾部]将始终未压缩；内部节点将压缩。
#2:[头部]->[下一步]->节点->节点->…->节点->[上一步]->[尾部]
#2这里的意思是：不要压缩头部或头部->下一个或尾部->上一个或尾部，
#但是压缩它们之间的所有节点。
#3:[头部]->[下一步]->[下一步]->节点->节点->…->节点->[上一步]->[上一步]->[尾部]
list-compress-depth 0
 
# 数据量小于等于set-max-intset-entries用iniset，大于set-max-intset-entries用set
set-max-intset-entries 512
 
#数据量小于等于zset-max-ziplist-entries用ziplist，大于zset-max-ziplist-entries用zset
zset-max-ziplist-entries 128
 
#value大小小于等于zset-max-ziplist-value用ziplist，大于zset-max-ziplist-value用zset
zset-max-ziplist-value 64
 
#value大小小于等于hll-sparse-max-bytes使用稀疏数据结构（sparse），大于hll-sparse-max-bytes使
用稠密的数据结构（dense）。一个比16000大的value是几乎没用的，建议的value大概为3000。如果对CPU要
求不高，对空间要求较高的，建议设置到10000左右
hll-sparse-max-bytes 3000
 
#宏观节点的最大流/项目的大小。在流数据结构是一个基数
#树节点编码在这项大的多。利用这个配置它是如何可能#大节点配置是单字节和
#最大项目数，这可能包含了在切换到新节点的时候
# appending新的流条目。如果任何以下设置来设置
# ignored极限是零，例如，操作系统，它有可能只是一集
通过设置限制最大#纪录到最大字节0和最大输入到所需的值
stream-node-max-bytes 4096
stream-node-max-entries 100
 
#Redis将在每100毫秒时使用1毫秒的CPU时间来对redis的hash表进行重新hash，可以降低内存的使用。当你
的使用场景中，有非常严格的实时性需要，不能够接受Redis时不时的对请求有2毫秒的延迟的话，把这项配置
为no。如果没有这么严格的实时性要求，可以设置为yes，以便能够尽可能快的释放内存
activerehashing yes
 
##对客户端输出缓冲进行限制可以强迫那些不从服务器读取数据的客户端断开连接，用来强制关闭传输缓慢的客户端。
#对于normal client，第一个0表示取消hard limit，第二个0和第三个0表示取消soft limit，normal 
client默认取消限制，因为如果没有寻问，他们是不会接收数据的
client-output-buffer-limit normal 0 0 0
 
#对于slave client和MONITER client，如果client-output-buffer一旦超过256mb，又或者超过64mb持续
60秒，那么服务器就会立即断开客户端连接
client-output-buffer-limit replica 256mb 64mb 60
 
#对于pubsub client，如果client-output-buffer一旦超过32mb，又或者超过8mb持续60秒，那么服务器就
会立即断开客户端连接
client-output-buffer-limit pubsub 32mb 8mb 60
 
# 这是客户端查询的缓存极限值大小
# client-query-buffer-limit 1gb
 
#在redis协议中，批量请求，即表示单个字符串，通常限制为512 MB。但是您可以更改此限制。
# proto-max-bulk-len 512mb
 
#redis执行任务的频率为1s除以hz
hz 10
 
#当启用动态赫兹时，实际配置的赫兹将用作作为基线，但实际配置的赫兹值的倍数
#在连接更多客户端后根据需要使用。这样一个闲置的实例将占用很少的CPU时间，而繁忙的实例将反应更灵敏
dynamic-hz yes
 
#在aof重写的时候，如果打开了aof-rewrite-incremental-fsync开关，系统会每32MB执行一次fsync。这
对于把文件写入磁盘是有帮助的，可以避免过大的延迟峰值
aof-rewrite-incremental-fsync yes
 
#在rdb保存的时候，如果打开了rdb-save-incremental-fsync开关，系统会每32MB执行一次fsync。这
对于把文件写入磁盘是有帮助的，可以避免过大的延迟峰值
rdb-save-incremental-fsync yes
```

#### ACTIVE DEFRAGMENTATION 

**###################### ACTIVE DEFRAGMENTATION ##########################**

```shell
# 已启用活动碎片整理
# activedefrag yes
 
# 启动活动碎片整理的最小碎片浪费量
# active-defrag-ignore-bytes 100mb
 
# 启动活动碎片整理的最小碎片百分比
# active-defrag-threshold-lower 10
 
# 我们使用最大努力的最大碎片百分比
# active-defrag-threshold-upper 100
 
# 以CPU百分比表示的碎片整理的最小工作量
# active-defrag-cycle-min 5
 
# 在CPU的百分比最大的努力和碎片整理
# active-defrag-cycle-max 75
 
#将从中处理的set/hash/zset/list字段的最大数目
#主词典扫描
# active-defrag-max-scan-fields 1000
```















### <u>附录：Redis优势</u>

- 性能极高 – Redis的读取速度是110000次/s,写入速度是81000次/s 。
- 丰富的数据类型 – Redis支持二进制案例的 Strings, Lists, Hashes, Sets 及 Ordered Sets 数据类型操作。
- 原子 – Redis的所有操作都是原子性的。意思就是要么成功执行要么失败完全不执行。单个操作是原子性的。多个操作也支持事务，即原子性，通过MULTI和EXEC指令包起来。
- 丰富的特性 – Redis还支持 publish/subscribe（发布-订阅模式）, 通知, key 过期等等特性。

### <u>附录：Redis特点</u>

- 读写性能优异
  - Redis能读的速度是110000次/s,写的速度是81000次/s （测试条件见下一节）。
- 数据类型丰富
  - Redis支持二进制案例的 Strings, Lists, Hashes, Sets 及 Ordered Sets 数据类型操作。
- 原子性
  - Redis的所有操作都是原子性的，同时Redis还支持对几个操作全并后的原子性执行。
- 丰富的特性
  - Redis支持 publish/subscribe, 通知, key 过期等特性。
- 持久化
  - Redis支持RDB, AOF等持久化方式
- 发布订阅
  - Redis支持发布/订阅模式
- 分布式
  - Redis Cluster

### <u>附录：官方性能测试数据</u>

> 官方的bench-mark根据如下条件获得的性能测试（**读的速度是110000次/s,写的速度是81000次/s**）

- 测试完成了50个并发执行100000个请求。
- 设置和获取的值是一个256字节字符串。
- Linux box是运行Linux 2.6,这是X3320 Xeon 2.5 ghz。
- 文本执行使用loopback接口(127.0.0.1)。

### <u>附录：Redis知识体系</u>

![img](https://pdai.tech/_images/db/redis/db-redis-overview.png)

### <u>附录：Redis数据类型</u>

- Redis所有的key（键）都是字符串。我们在谈基础数据结构时，讨论的是存储值的数据类型，主要包括常见的5种数据类型，分别是：String、List、Set、Zset、Hash

![img](https://pdai.tech/_images/db/redis/db-redis-object-2-2.png)