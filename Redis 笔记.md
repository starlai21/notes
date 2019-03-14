# Redis 笔记

`$ redis-cli -h 127.0.0.1 -p 6379`

------

## 

## ruby ./redis-trib.rb create  127.0.0.1:6379 127.0.0.1:6380 127.0.0.1:6381

集群  建多个文件夹

config

```
daemonize yes
port 6379
cluster-enabled yes
cluster-config-file nodes.conf
cluster-node-timeout 5000
appendonly yes

```

start.bat

## 

## 1.1 全局命令

### 1.1.1 查看所有键

`keys pattern`

如

![æ¥è¯¢ææé®](https://segmentfault.com/img/bVLEEM?w=1134&h=438)

### 1.1.2 键总数

`dbsize` 返回当前数据库中所有键的总数

### 1.1.3 检查键是否存在

`exists key` 检查key是否存在，存在返回1，不存在返回0.

### 1.1.4 删除键

`del key [...]` 返回结果为删除key的个数，如果删除一个不存在的键，会返回0.

### 1.1.5 键过期

`expire key seconds`

`ttl`命令会返回键剩余的过期时间，它有三个返回值：

- 大于或等于0的整数，键的剩余时间
- -1: 键未设置过期时间
- -2: 键不存在

### 1.1.6 键的数据类型

`type key`



## 1.2 数据结构和内部编码

`type`命令返回的是当前键的数据结构类型，他们分别是`string`(字符串), `hash`(哈希), `list`(列表), `set`(集合), `zset`(有序集合).

这些只是redis 对外的数据类型，每种数据类型都有自己的内部编码实现，而且是多种编码，这样redis 会在合适的场景选择适合的内部编码。可以通过`object encoding`命令查询内部编码

redis 的5种数据结构：

![redisç5ç§æ°æ®ç"æ](https://segmentfault.com/img/bVLENS?w=1330&h=936)

redis 数据结构与内部编码：

![redis5ç§æ°æ®ç»æçåé¨ç¼ç ](https://segmentfault.com/img/bVLEQZ?w=1194&h=1058)

 

## 1.3 字符串

字符串类型是redis最基础的数据类型，其他几种数据类型结构都是在字符串基础上建立的。字符串的值可以是字符串，数字，二进制，值最大不可以超过512mb.

### 1.3.1 命令

#### 1 设置值

`set key value ` 为键设置值
	
`setex key value seconds ` 为键设置值，并设置秒级的过期时间
	
`setpx key value millisecond` 为键设置值，并设置毫秒级的过期时间
	
`setnx key value`对键设置值前判断键是否存在，不存在则设置，存在则不设置
	
`setxx key value`与`setnx`相反，对键设置值前判断键是否存在，存在则设置，不存在则不设置

#### 2 计数

`incr`用于对键的值进行自增操作，返回结果为三种
	
		值不是整数，返回错误
	
		值是整数，返回自增后的结果
	
		值不存在，按照值为0自增，返回1

`incrby key value`用于对键的值进行指定自增量的自增操作，返回结果与`incr`相同
	
`incrbyfloat`用于对键的值进行指定浮点型自增量的自增操作
	
`decr`   `decrby`
	
`append`用于对键的值进行追加操作，返回追加后的值的长度，如

```
    set hello w
    OK
    append hello orld
    (integer) 5
    get hello
    "world"
```

`strlen`用于查看键的值的长度
	
`setrange`用于键的值内指定索引字符的替换，如果参数是多个字符则从指定位置开始逐个替换，返回替换后值的长度，如

```
    set hello world
    OK
    setrange hello 0 helloworld
    (integer) 10
```

`getrange key start end `用于获取键的值指定索引的内容, 如

```
    set hello world
    OK
    getrange hello 0 2
    "wor"
```

### 1.3.2 内部编码

字符串类型的内部编码：

	int: 8个字节长度的长整形
	
	embstr: 小于等于39个字节的字符串
	
	raw: 大于39个字节的字符串

## 1.4 哈希

### 1.4.1 命令

#### 1 设置值

`hset key field value`
	
如 

```
hset user:1 name username
(integer) 1
hset user:1 name codger
(integer) 0
```

	如果设置不存在的field 则返回1， 存在则返回0. 此外还提供了hsetnx命令

#### 2 获取值

`hget key field`
	
如

```
    hget user:2 name
    (nil)
    hget user:1 name
    "codger"
```

#### 3 删除field

`hdel key field [field1...]` 返回结果为成功删除的field 数量

#### 4 计算field数量

`hlen key` 获取对应的hash结构值的field数量

#### 5 批量设置或获取 field-value

`hmget key field [field...]`
	
`hmset key field1 value1 field2 value2..`

#### 6 判断 field 是否存在

`hexists key field ` 1表示存在，0表示不存在

#### 7 获取所有field

`hkeys key`

#### 8 获取所有value

`hvals key`

#### 9 获取所有的field-value

`hgetall key`

## 1.5 列表

列表list 类型是用来存储多个字符串，如下图

![åè¡¨](https://segmentfault.com/img/bVLV3q?w=1276&h=532)

列表类型有两个特点：

 1. 列表中的元素是有序的，这就意味着可以通过索引下标获取某个元素或者某个范围内的元素列表
2. 列表中的元素可以是重复的

### 1.5.1

#### 1 插入命令

	从右边插入元素

`rpush key value [value...]`  如 `rpush user:1 task a b c`
	
`lrange key 0 -1` 命令可以获取列表中所有的元素
	
	从左边插入元素

`lpush key value [value...]`

#### 2 查询命令

	查询指定范围内的元素列表

`lrange key start end`
	
	两个特点：

  1. 索引下标从左到右分别是0到N-1, 但是从右到左分别是-1 到 -N
  2. lrange中的end 选项包含了自身



	获取列表指定索引下的元素

`lindex key index`
	
	获取列表长度

`llen key`

#### 3 删除命令

	从列表左侧或右侧弹出元素

`lpop key` `rpop key`
	
	删除指定元素

`lrem key count value`
	
lrem 命令会从列表中找到等于value 的元素进行删除，根据count的不同分为三种：

  1. count>0 || count <0从列表中删除指定数量 |count| 的元素
  2. count=0，删除所有



	按照索引范围修建列表

`ltrim key start end` 

#### 4 修改命令

	修改指定索引下标的元素

`lset key index value`

#### 5 阻塞操作

	阻塞式弹出

`blpop key [key ...] timeout` `brpop key [key ...] timeout` 
	
	brpop 命令包含两个参数
	
		key[keys...]：多个列表的键
	
		timeout: 阻塞时间(单位为 秒)
	
	列表为空：如果timeout等于3， 那么客户端等到三秒后返回，如果timeout=0,那么客户端将一直阻塞，直到弹出成功

在使用阻塞弹出命令时，有两点需要注意：

	第一点：如果有多个键，那么会从左到右遍历键，一旦有一个键能弹出元素，客户端就会立刻返回
	
	第二点：如果多个客户端同时对一个键进行操作，那么最先执行命令的客户端将获取到值

## 1.6 集合

集合set 类型也是用来保存多个的字符串元素，但和列表不同的是：它的元素是无需且不可重复的，不能通过索引获取元素

### 1.6.1 集合内操作

#### 1 添加元素

`sadd key value [value...]`返回结果为添加成功的元素数量

#### 2 删除元素

`srem key value [value...]`返回结果为删除成功的元素数量

#### 3 获取元素个数

`scard key`

#### 4 判断元素是否子集合中

`sismember key value`
	
	如果元素存在于集合内则返回1，否则返回0

#### 5 随机从集合中返回指定个数元素

`srandmember key [count]` 不写count 默认为1

#### 6 从集合中随机弹出元素

`spop key`

#### 7 获取集合的所有元素

`smembers key`

### 1.6.2 集合间操作

#### 1 求多个集合的交集

`sinter key [key...]`

#### 2 求多个集合的并集

`sunion key [key...]`

#### 3 求多个集合的差集

`sdiff key [key...]`

#### 4 将交集、并集、差集的结果保存

```
    sinterstore storeKey key [key...]
    sunionstore storeKey key [key...]
    sdiffstore storeKey key [key...]
```

	

1.7 有序集合

有序集合给每个元素设置了一个分数score 作为排序的依据

![clipboard.png](https://segmentfault.com/img/bVMCOK?w=1106&h=590)



1.7.1 集合内

1 添加成员

`zadd key score member [score member...]`

2 获取成员个数

`zcard key`

3 获取某个成员的分数

`zscore key member`

4 获取成员排名

`zrank key member`

`zrevrank key member`

zrank 分数从低到高返回排名，最低的排名为0

5 删除成员

`zrem key member [member...]`

6 增加成员分数

`zincrby key score member `

7 获取制定范围的元素

`zrange key start end [withscores]`

`zrevrange key start end [withscores]`

有序集合是按照分值排名的，zrange是由低到高返回，zrevrange反之,查询全部：`zrange user:ranking 0 -1`

, 加上withscores 参数显示分数

8 返回指定分数范围的成员

```
zrangebyscore key min max [limit offset count]
zrevrangebyscore key min max [limit offset count]
```

9 返回指定分数范围成员个数

`zcount key min max`

10 删除指定排名内的升序元素

`zremrangebyrank key start end `

11 删除指定分数范围的成员

`zremrangebyscore key min max`

1.7.2 集合间的操作

1 交集

```
zinterstore storeKey keyNum key [key ...] [weights weight [weight...]] [aggregate sum|min|max]
```

参数说明:

- `storeKey`:交集计算结果保存到这个键下.
- `keyNum`:需要做交集的键的个数.
- `key[key ...]`:需要做交集的键.
- `weights weight [weight...]`:每个键的权重,在做交集计算时,每个键中的每个`member`的分值会和这个权重相乘,每个键的权重默认为`1`.
- `aggregate sum|min|sum`:计算成员交集后,分值可以按照`sum`(和)、`min`(最小值)、`max`(最大值)做汇总.默认值为`sum`.

```
    127.0.0.1:6379> zrange user:ranking:2 0 -1 withscores
    1) "Rico"
    2) "138"
    3) "tom"
    4) "160"
    127.0.0.1:6379> zinterstore user:ranking:1_2 2 user:ranking user:ranking:2 aggregate min
    (integer) 2
    127.0.0.1:6379> zrange user:ranking:1_2 0 -1
    1) "Rico"
    2) "tom"
    127.0.0.1:6379> zrange user:ranking:1_2 0 -1 withscores
    1) "Rico"
    2) "69"
    3) "tom"
    4) "80"
```

(2) 并集

```
zunionstore storeKey keyNum key [key...] [weights weight [weight...]] [aggregate sum|min|max]
```

该命令的所有参数和`zinterstore`是一致的,只不过做的是并集计算.
例:

```
    127.0.0.1:6379> zunionstore user:ranking:1_2 2 user:ranking user:ranking:2  aggregate min
    (integer) 3
    127.0.0.1:6379> zrange user:ranking:1_2 0 -1 withscores
    1) "Rico"
    2) "69"
    3) "codger"
    4) "90"
    5) "tom"
    6) "160"
```

