## 

# 初探 Spring Cloud

## Spring cloud 的核心组件介绍



1、`Eureka ` : 各个服务启动时，`Eureka Client`都会将服务注册到`Eureka Server`，并且`Eureka Client`还可以反过来从`Eureka Server`拉取注册表，从而知道其他服务在哪里

2、`Feign` : 基于`Feign`的动态代理机制，根据注解和选择的机器，拼接请求URL地址，发起请求

3、`Ribbon`: 服务间发起请求的时候，基于`Ribbon`做负载均衡，从一个服务的多台机器中选择一台

4、`Hystrix` : 发起请求是通过`Hystrix`的线程池来走的，不同的服务走不同的线程池，实现了不同服务调用的隔离，避免了服务雪崩的问题

5、`Zuul`: 如果前端、移动端要调用后端系统，统一从`Zuul`网关进入，由`Zuul`网关转发请求给对应的服务





先来给大家说一个业务场景，假设咱们现在开发一个电商网站，要实现支付订单的功能，流程如下：

> 1.创建一个订单后，如果用户立刻支付了这个订单，我们需要将订单状态更新为“已支付”

> 2.扣减相应的商品库存

> 3.通知仓储中心，进行发货

> 4.给用户的这次购物增加相应的积分

![img](https://user-gold-cdn.xitu.io/2018/11/7/166ebffb48c481a3?imageView2/0/w/1280/h/960/format/webp/ignore-error/1)

## 

第一个问题就是，如果订单服务想要调用库存、仓储或者积分服务时，它需要如何调用？ **订单服务根本不知道其他服务是在哪一台机器上**。

这时候`Eureka` 就可以闪亮登场了，它在微服务构架中充当一个注册中心的角色，专门负责服务的注册和发现。

![img](https://user-gold-cdn.xitu.io/2018/11/7/166ebffcb7ce31b8?imageView2/0/w/1280/h/960/format/webp/ignore-error/1)

各个服务都有一个`Eureka Client`组件，负责将自己的服务信息注册到`Eureka Server` 中，`Eureka Server` 实际上就是维护着各服务所在的机器和端口。





现在虽然 订单服务知道了其他服务所在的机器和端口，但是我们难道要自己建立一个 http client, 构造请求，发送请求，最后解析请求吗？

莫慌，`Feign`已经为我们提供了优雅的解决方案。 

![img](https://user-gold-cdn.xitu.io/2018/11/7/166ebcf01b773dd4?imageView2/0/w/1280/h/960/format/webp/ignore-error/1)



如上图所示，`Feign` 帮我们做了脏活累活， `InventoryService` 就像普通的`service`, 可以直接被注入到 `OrderService`中。



假设库存服务部署在5台机器上，

> - 192.168.169:9000
> - 192.168.170:9000
> - 192.168.171:9000
> - 192.168.172:9000
> - 192.168.173:9000

`Feign`就不知道向哪一台机器做请求，`Ribbon`的作用就是帮我们选择一台机器，进行负载均衡。



现在假设订单服务自己最多只有100个线程可以处理请求，然后呢，积分服务不幸的挂了，每次订单服务调用积分服务的时候，都会卡住几秒钟，然后抛出—个超时异常。

如果大量的请求涌来，订单服务的所有线程都卡在请求积分服务这里，就会导致订单服务无法响应别人的任何请求。

![img](https://user-gold-cdn.xitu.io/2018/11/7/166ec0033f64a0a7?imageView2/0/w/1280/h/960/format/webp/ignore-error/1)

这时就轮到`Hystrix`出马了。`Hystrix`的作用是隔离、熔断和降级。Hystrix 会分很多小线程池，每一个服务使用一个线程池，这便是隔离。熔断就是在一定时间内使请求直接返回，不再做没有意义的等待；降级是指使用Plan B， 飞机延误了我们可以坐动车。

最后 讲一下`Zuul`，它 负责网络路由。假设我们有上百个服务，让前端记住这些服务的名称、地址、端口是不现实的。`Zuul`相当于一个网关，所有前端请求都经过它，它再根据请求的特征进行转发。好处是可以做统一的限流、认证授权等。



## 例子

### sbc-order  （相当于一个微服务）

order 模块:   实现order-api 中接口， controller， config.

order-api 模块:   定义 api

如

```java
@RestController
@Api("订单服务API")
@RequestMapping(value = "/orderService")
@Validated
public interface OrderService {

    /**
     * 活动订单号
     * @param orderNoReq
     * @return
     */
    @ApiOperation("获取订单号")
    @RequestMapping(value = "/getOrderNo", method = RequestMethod.POST)
    BaseResponse<OrderNoResVO> getOrderNo(@RequestBody OrderNoReqVO orderNoReq) ;

    /**
     * 限流获取订单号
     * @param orderNoReq
     * @return
     */
    @ApiOperation("限流获取订单号")
    @RequestMapping(value = "/getOrderNoLimit", method = RequestMethod.POST)
    BaseResponse<OrderNoResVO> getOrderNoLimit(@RequestBody OrderNoReqVO orderNoReq) ;

    /**
     * 通用限流获取订单号
     * @param orderNoReq
     * @return
     */
    @ApiOperation("通用限流获取订单号")
    @RequestMapping(value = "/getOrderNoCommonLimit", method = RequestMethod.POST)
    BaseResponse<OrderNoResVO> getOrderNoCommonLimit(@RequestBody OrderNoReqVO orderNoReq) ;
}
```

order-client 模块: 供另一个服务调用，相当于封装了order-api，提供接口, 使用前需要在order 模块中启用`@EnableDiscoveryClient` 以注册到Eureka server 中,另一个服务可以直接 使用 @Autowired 进行注入

如

```Java
@RequestMapping(value="/orderService")
@FeignClient(name="sbc-order"
        //// FIXME: 26/04/2018 为了方便测试，先把降级关掉
        //fallbackFactory = OrderServiceFallbackFactory.class,
        // FIXME: 2017/9/4 如果配置了 fallback 那么 fallbackFactory 将会无效
        //fallback = OrderServiceFallBack.class,
        //configuration = OrderConfig.class
)
@RibbonClient
public interface OrderServiceClient extends OrderService{


    /**
     * 获取订单号
     * @param orderNoReq
     * @return
     */
    @Override
    @ApiOperation("获取订单号")
    @RequestMapping(value = "/getOrderNo", method = RequestMethod.POST)
    BaseResponse<OrderNoResVO> getOrderNo(@RequestBody OrderNoReqVO orderNoReq) ;



    /**
     * 限流获取订单号
     * @param orderNoReq
     * @return
     */
    @Override
    @ApiOperation("限流获取订单号")
    @RequestMapping(value = "/getOrderNoLimit", method = RequestMethod.POST)
    BaseResponse<OrderNoResVO> getOrderNoLimit(@RequestBody OrderNoReqVO orderNoReq) ;


    /**
     * 通用限流获取订单号
     * @param orderNoReq
     * @return
     */
    @Override
    @ApiOperation("通用限流获取订单号")
    @RequestMapping(value = "/getOrderNoCommonLimit", method = RequestMethod.POST)
    BaseResponse<OrderNoResVO> getOrderNoCommonLimit(@RequestBody OrderNoReqVO orderNoReq) ;
}
```

服务降级  在OrderServiceClient 中 FeignClient 注解中指定 fallback, configuration

```Java
@Configuration
public class OrderConfig {
    //// FIXME: 26/04/2018 为了方便测试，先把降级关掉
    //@Bean
    public OrderServiceFallBack fallBack(){
        return new OrderServiceFallBack();
    }
    //// FIXME: 26/04/2018 为了方便测试，先把降级关掉
    //@Bean
    public OrderServiceFallbackFactory factory(){
        return new OrderServiceFallbackFactory();
    }

}
```

```Java
public class OrderServiceFallBack implements OrderServiceClient {
    @Override
    public BaseResponse<OrderNoResVO> getOrderNo(@RequestBody OrderNoReqVO orderNoReq) {
        BaseResponse<OrderNoResVO> baseResponse = new BaseResponse<>() ;
        OrderNoResVO vo = new OrderNoResVO() ;
        vo.setOrderId(123456L);
        baseResponse.setDataBody(vo);
        baseResponse.setMessage(StatusEnum.FALLBACK.getMessage());
        baseResponse.setCode(StatusEnum.FALLBACK.getCode());
        return baseResponse;
    }

    @Override
    public BaseResponse<OrderNoResVO> getOrderNoLimit(@RequestBody OrderNoReqVO orderNoReq) {
        return null;
    }

    @Override
    public BaseResponse<OrderNoResVO> getOrderNoCommonLimit(@RequestBody OrderNoReqVO orderNoReq) {
        return null;
    }
}
```

## 

### sbc-common 公用模块

一般将util, enums, exception 等公用文件放在该模块中供其他应用使用



sbc-service  Eureka Server 应用

可启动多个应用来构成高可用的服务注册中心

### sbc-user  (与sbc-order 相似， 另一个微服务)

依赖 order-client, 在controller 中直接注入

```
@Autowired
private OrderServiceClient orderServiceClient;
```

### Hystrix与Turbine聚合监控

为此我们新建了一个应用`sbc-hystrix-turbine`来显示`hystrix-dashboard`。
目录结构和普通的`springboot`应用没有差异，看看主类:

```java
//开启EnableTurbine

@EnableTurbine
@SpringBootApplication
@EnableHystrixDashboard
public class SbcHystrixTurbineApplication {

	public static void main(String[] args) {
		SpringApplication.run(SbcHystrixTurbineApplication.class, args);
	}
}
```

其中使用`@EnableHystrixDashboard`开启`Dashboard` 

`@EnableTurbine`开启`Turbine`支持。

以上这些注解需要以下这些依赖:

```
<dependency>
	<groupId>org.springframework.cloud</groupId>
	<artifactId>spring-cloud-starter-turbine</artifactId>
</dependency>
<dependency>
	<groupId>org.springframework.cloud</groupId>
	<artifactId>spring-cloud-netflix-turbine</artifactId>
</dependency>
<dependency>
	<groupId>org.springframework.boot</groupId>
	<artifactId>spring-boot-starter-actuator</artifactId>
</dependency>
<dependency>
	<groupId>org.springframework.cloud</groupId>
	<artifactId>spring-cloud-starter-hystrix-dashboard</artifactId>
</dependency>
```

> 实际项目中，我们的应用都是多节点部署以达到高可用的目的，单个监控显然不现实，所以需要使用Turbine来进行聚合监控。

关键的`application.properties`配置文件:

```
# 项目配置
spring.application.name=sbc-hystrix-trubine
server.context-path=/
server.port=8282
# eureka地址
eureka.client.serviceUrl.defaultZone=http://node1:8888/eureka/
eureka.instance.prefer-ip-address=true
# 需要加入的实例
turbine.appConfig=sbc-user,sbc-order
turbine.cluster-name-expression="default"
```

其中`turbine.appConfig`配置我们需要监控的应用，这样当多节点部署的时候就非常方便了(`同一个应用的多个节点spring.application.name值是相同的`)。

将该应用启动访问`http://ip:port/hystrix.stream`：![img](https://ws1.sinaimg.cn/large/006tKfTcly1fjr3wu3f4oj316a0i4dig.jpg)

由于我们的turbine和Dashboard是一个应用所以输入`http://localhost:8282/turbine.stream`即可。![img](https://ws1.sinaimg.cn/large/006tNc79ly1fjr4apibpjj31ga0dr416.jpg)

详细指标如官方描述:
![img](https://ws4.sinaimg.cn/large/006tNc79ly1fjr4gjnl82j30hs0bfq4c.jpg)




通过该面板我们就可以及时的了解到应用当前的各个状态，如果再加上一些报警措施就能帮我们及时的响应生产问题。



### sbc-gateway-zuul

```java
@SpringBootApplication

//开启zuul代理
@EnableZuulProxy
public class SbcGateWayZuulApplication {

   public static void main(String[] args) {
      SpringApplication.run(SbcGateWayZuulApplication.class, args);
   }
}
```

```java
public class RequestFilter extends ZuulFilter {
    private Logger logger = LoggerFactory.getLogger(RequestFilter.class) ;
    /**
     * 请求路由之前被拦截 实现 pre 拦截器
     * @return
     */
    @Override
    public String filterType() {
        return "pre";
    }

    @Override
    public int filterOrder() {
        return 0;
    }

    @Override
    public boolean shouldFilter() {
        return true;
    }

    @Override
    public Object run() {

        RequestContext currentContext = RequestContext.getCurrentContext();
        HttpServletRequest request = currentContext.getRequest();
        String token = request.getParameter("token");
        if (StringUtil.isEmpty(token)){
            logger.warn("need token");
            //过滤请求
            currentContext.setSendZuulResponse(false);
            currentContext.setResponseStatusCode(401);
            return null ;
        }
        logger.info("token ={}",token) ;

        return null;
    }
}
```

```java
@Configuration
@Component
public class FilterConf {

    @Bean
    public RequestFilter filter(){
        return  new RequestFilter() ;
    }
}
```

```java
zuul.routes.sbc-user=/api/user/**
```