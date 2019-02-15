## sbc-order  （相当于一个微服务）

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

order-client 模块: 供另一个服务调用，提供接口, 使用前需要在order 模块中启用`@EnableDiscoveryClient` 以注册到Eureka server 中

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

## sbc-common 公用模块

一般将util, enums, exception 等公用文件放在该模块中供其他应用使用



## sbc-service  Eureka Server 应用

可启动多个应用来构成高可用的服务注册中心

## sbc-user  (与sbc-order 相似， 另一个微服务)

依赖 order-client, 在controller 中直接注入

```
@Autowired
private OrderServiceClient orderServiceClient;
```

## Hystrix与Turbine聚合监控

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

将该应用启动访问`http://ip:port/hystrix.stream`：

[![img](https://ws1.sinaimg.cn/large/006tKfTcly1fjr3wu3f4oj316a0i4dig.jpg)](https://ws1.sinaimg.cn/large/006tKfTcly1fjr3wu3f4oj316a0i4dig.jpg)

由于我们的turbine和Dashboard是一个应用所以输入`http://localhost:8282/turbine.stream`即可。

[![img](https://ws1.sinaimg.cn/large/006tNc79ly1fjr4apibpjj31ga0dr416.jpg)](https://ws1.sinaimg.cn/large/006tNc79ly1fjr4apibpjj31ga0dr416.jpg)

详细指标如官方描述:
[![img](https://ws4.sinaimg.cn/large/006tNc79ly1fjr4gjnl82j30hs0bfq4c.jpg)](https://ws4.sinaimg.cn/large/006tNc79ly1fjr4gjnl82j30hs0bfq4c.jpg)

通过该面板我们就可以及时的了解到应用当前的各个状态，如果再加上一些报警措施就能帮我们及时的响应生产问题。



## sbc-gateway-zuul

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

