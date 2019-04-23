## cim-client

### 1.CIMClient

`userLogin()` //登陆 & 获得可使用得服务器 ip + port

`startClient(CIMServerResVO.ServerInfo cimServer)` 启动客户端 ->

`.handler(new CIMClientHandleInitializer())`

->

CIMClientHandleInitializer

```java
ch.pipeline()
        //10 秒没发送消息 将IdleStateHandler 添加到 ChannelPipeline 中
        .addLast(new IdleStateHandler(0, 10, 0))

        //心跳解码
        //.addLast(new HeartbeatEncode())

        // google Protobuf 编解码
        //拆包解码
        .addLast(new ProtobufVarint32FrameDecoder())
        .addLast(new ProtobufDecoder(CIMResponseProto.CIMResProtocol.getDefaultInstance()))
        //
        //拆包编码
        .addLast(new ProtobufVarint32LengthFieldPrepender())
        .addLast(new ProtobufEncoder())
        .addLast(cimClientHandle)
```

->

cimClientHandle

`userEventTriggered` //一定时间未向服务器端发送消息，则发送心跳包 ping 到服务器端

`channelInactive` //客户端 断开，开启定时任务来重连服务器

`channelRead0` //1. 收到心跳回复，更新readerTime 2. 收到普通消息，`callBackMsg` 回调消息 --->

```java
private void callBackMsg(String msg) {
    threadPoolExecutor = SpringBeanFactory.getBean("callBackThreadPool",ThreadPoolExecutor.class) ; //为什么要使用线程池？
    threadPoolExecutor.execute(() -> {
        caller = SpringBeanFactory.getBean(MsgHandleCaller.class) ;
        caller.getMsgHandleListener().handle(msg);
    }); //MsgHandleCaller & MsgHandleListener 的作用

}
```

AsyncMsgLogger.log

### 2.CIMClientApplication

```java
@Override
public void run(String... args) throws Exception {
   Scan scan = new Scan() ;
   Thread thread = new Thread(scan);
   thread.setName("scan-thread");
   thread.start();
   clientInfo.saveStartDate();
}
```

Scan

```java
@Override
public void run() {
    Scanner sc = new Scanner(System.in);
    while (true) {
        String msg = sc.nextLine();

        //检查消息
        if (msgHandle.checkMsg(msg)) {
            continue;
        }

        //系统内置命令
        if (msgHandle.innerCommand(msg)){
            continue;
        }

        //真正的发送消息
        msgHandle.sendMsg(msg) ;

        //写入聊天记录
        msgLogger.log(msg) ;

        LOGGER.info("{}:【{}】", configuration.getUserName(), msg);
    }
}
```

## cim-server

### 1.CIMServer

`start()` -> `.childHandler(new CIMServerInitializer());`

`CIMServerInitializer` -> 

```java
ch.pipeline()
        //11 秒没有向客户端发送消息就发生心跳
        .addLast(new IdleStateHandler(11, 0, 0))
        // google Protobuf 编解码
        .addLast(new ProtobufVarint32FrameDecoder())
        .addLast(new ProtobufDecoder(CIMRequestProto.CIMReqProtocol.getDefaultInstance()))
        .addLast(new ProtobufVarint32LengthFieldPrepender())
        .addLast(new ProtobufEncoder())
        .addLast(cimServerHandle);
```

cimServerHandle ->

```java
public void channelInactive(ChannelHandlerContext ctx) throws Exception {
    //可能出现业务判断离线后再次触发 channelInactive
    CIMUserInfo userInfo = SessionSocketHolder.getUserId((NioSocketChannel) ctx.channel());
    if (userInfo != null){
        LOGGER.warn("[{}]触发 channelInactive 掉线!",userInfo.getUserName());
        userOffLine(userInfo, (NioSocketChannel) ctx.channel());
        ctx.channel().close();
    }
}
```



```java
private void userOffLine(CIMUserInfo userInfo, NioSocketChannel channel) throws IOException {
    LOGGER.info("用户[{}]下线", userInfo.getUserName());
    SessionSocketHolder.remove(channel);
    SessionSocketHolder.removeSession(userInfo.getUserId());

    //清除路由关系
    clearRouteInfo(userInfo);
}
```

`clearRouteInfo`  -> 发送清除请求到 route server 

`channelRead0` -> 1. 收到 LOGIN 类型的消息，

```java
SessionSocketHolder.put(msg.getRequestId(), (NioSocketChannel) ctx.channel());
SessionSocketHolder.saveSession(msg.getRequestId(), msg.getReqMsg());
```

2.收到心跳包，向客户端发送心跳响应， 若发送失败则关闭channel

`userEventTriggered` -> 一定时间内没有读到客户端消息，判断 readerTime 是否超时来决定是否调用 `userOffLine` 和 `channel.close()`

`sendMsg`发送 Google Protocol 编码消息 到某一客户端

### 2.CIMServerApplication

`run` -> `Thread thread = new Thread(new RegistryZK(addr, appConfiguration.getCimServerPort(),httpPort));`

`RegistryZK` -> 

```java
@Override
public void run() {

    //创建父节点
    zKit.createRootNode();

    //是否要将自己注册到 ZK
    if (appConfiguration.isZkSwitch()){
        String path = appConfiguration.getZkRoot() + "/ip-" + ip + ":" + cimServerPort + ":" + httpPort;
        zKit.createNode(path);
        logger.info("注册 zookeeper 成功，msg=[{}]", path);
    }
}
```

### 3.IndexController

提供`sendMsg` 接口给 route server 调用实现 p2p & groupMsg



## cim-forward-route

### 1.RouteApplication

`run` -> `Thread thread = new Thread(new ServerListListener());`

`ServerListener` 

```java
@Override
public void run() {
    //注册监听服务
    zkUtil.subscribeEvent(appConfiguration.getZkRoot());
}
```

`Zkit`

```java
public void subscribeEvent(String path) {
    zkClient.subscribeChildChanges(path, new IZkChildListener() {
        @Override
        public void handleChildChange(String parentPath, List<String> currentChilds) throws Exception {
            logger.info("清除/更新本地缓存 parentPath=【{}】,currentChilds=【{}】", parentPath,currentChilds.toString());

            //更新所有缓存/先删除 再新增
            serverCache.updateCache(currentChilds) ;
        }
    });
}
```

### 2.RouteController 

`groupRoute` 群聊API  ->

```java
Map<Long, CIMServerResVO> serverResVOMap = accountService.loadRouteRelated(); //获取所有的推送列表 userId , server info

            accountService.pushMsg(url,groupReqVO.getUserId(),chatVO);
```

`p2pRoute` 单聊 API -> `pushMsg`

`offLine` 客户端下线API -> `accountService.offLine(groupReqVO.getUserId());`

```java
@Override
public void offLine(Long userId) throws Exception {

    // TODO: 2019-01-21 改为一个原子命令，以防数据一致性

    //删除路由
    redisTemplate.delete(ROUTE_PREFIX + userId) ;

    //删除登录状态
    userInfoCacheService.removeLoginStatus(userId);
}
```



`login` 登录并获取服务器API ，供 client 调用

`registerAccount`

`onlineUser`

