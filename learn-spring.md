# Tiny Spring

https://github.com/code4craft/tiny-spring

2019/3/6

tags

## step-1-container-register-and-get

```java
public class BeanDefinition {

    private Object bean;

    public BeanDefinition(Object bean) {
        this.bean = bean;
    }

    public Object getBean() {
        return bean;
    }

}
```

```java
public class BeanFactory {

   private Map<String, BeanDefinition> beanDefinitionMap = new ConcurrentHashMap<String, BeanDefinition>();

   public Object getBean(String name) {
      return beanDefinitionMap.get(name).getBean();
   }

   public void registerBeanDefinition(String name, BeanDefinition beanDefinition) {
      beanDefinitionMap.put(name, beanDefinition);
   }

}
```



Test:

```java
public class BeanFactoryTest {

   @Test
   public void test() {
      // 1.初始化beanfactory
      BeanFactory beanFactory = new BeanFactory();

      // 2.注入bean
      BeanDefinition beanDefinition = new BeanDefinition(new HelloWorldService());
      beanFactory.registerBeanDefinition("helloWorldService", beanDefinition);

        // 3.获取bean
        HelloWorldService helloWorldService = (HelloWorldService) beanFactory.getBean("helloWorldService");
        helloWorldService.helloWorld();


    }
}
```

```java
public class HelloWorldService {

    public void helloWorld(){
        System.out.println("Hello World!");
    }
}
```



这种实现 需要手动实例化bean ，然后 直接把bean 注入到BeanDefinition 中



## step-2-abstract-beanfactory-and-do-bean-initilizing-in-it

```java
public abstract class AbstractBeanFactory implements BeanFactory {

   private Map<String, BeanDefinition> beanDefinitionMap = new ConcurrentHashMap<String, BeanDefinition>();

   @Override
    public Object getBean(String name) {
      return beanDefinitionMap.get(name).getBean();
   }

   @Override
    public void registerBeanDefinition(String name, BeanDefinition beanDefinition) {
        Object bean = doCreateBean(beanDefinition);
        beanDefinition.setBean(bean);
        beanDefinitionMap.put(name, beanDefinition);
   }

    /**
     * 初始化bean
     * @param beanDefinition
     * @return
     */
    protected abstract Object doCreateBean(BeanDefinition beanDefinition);

}
```

```java
public class AutowireCapableBeanFactory extends AbstractBeanFactory {

    @Override
    protected Object doCreateBean(BeanDefinition beanDefinition) {
        try {
            Object bean = beanDefinition.getBeanClass().newInstance();
            return bean;
        } catch (InstantiationException e) {
            e.printStackTrace();
        } catch (IllegalAccessException e) {
            e.printStackTrace();
        }
        return null;
    }
}
```

```java
public interface BeanFactory {

    Object getBean(String name);

    void registerBeanDefinition(String name, BeanDefinition beanDefinition);
}
```

```java
public class BeanDefinition {

   private Object bean;

   private Class beanClass;

   private String beanClassName;

   public BeanDefinition() {
   }

   public void setBean(Object bean) {
      this.bean = bean;
   }

   public Class getBeanClass() {
      return beanClass;
   }

   public void setBeanClass(Class beanClass) {
      this.beanClass = beanClass;
   }

   public String getBeanClassName() {
      return beanClassName;
   }

   public void setBeanClassName(String beanClassName) {
      this.beanClassName = beanClassName;
      try {
         this.beanClass = Class.forName(beanClassName);
      } catch (ClassNotFoundException e) {
         e.printStackTrace();
      }
   }

   public Object getBean() {
      return bean;
   }

}
```

Test

```java
public class BeanFactoryTest {

   @Test
   public void test() {
      // 1.初始化beanfactory
      BeanFactory beanFactory = new AutowireCapableBeanFactory();

      // 2.注入bean
      BeanDefinition beanDefinition = new BeanDefinition();
        beanDefinition.setBeanClassName("us.codecraft.tinyioc.HelloWorldService");
      beanFactory.registerBeanDefinition("helloWorldService", beanDefinition);

        // 3.获取bean
        HelloWorldService helloWorldService = (HelloWorldService) beanFactory.getBean("helloWorldService");
        helloWorldService.helloWorld();

    }
}
```

在BeanFactory 的基础上抽象了一层AbstractBeanFactory， 在实例化BeanDefinition 后只需要传入bean 的 class name, 在调用registerBeanDefinition时会自动实例化bean, 并放入BeanDefinition中。



## step-3-inject-bean-with-property

```java
public class HelloWorldService {

    private String text;

    public void helloWorld(){
        System.out.println(text);
    }

    public void setText(String text) {
        this.text = text;
    }
}
```

```java
public class AutowireCapableBeanFactory extends AbstractBeanFactory {

   @Override
   protected Object doCreateBean(BeanDefinition beanDefinition) throws Exception {
      Object bean = createBeanInstance(beanDefinition);
      applyPropertyValues(bean, beanDefinition);
      return bean;
   }

   protected Object createBeanInstance(BeanDefinition beanDefinition) throws Exception {
      return beanDefinition.getBeanClass().newInstance();
   }

   protected void applyPropertyValues(Object bean, BeanDefinition mbd) throws Exception {
      for (PropertyValue propertyValue : mbd.getPropertyValues().getPropertyValues()) {
         Field declaredField = bean.getClass().getDeclaredField(propertyValue.getName());
         declaredField.setAccessible(true);
         declaredField.set(bean, propertyValue.getValue());
      }
   }
}
```



```java
public class BeanDefinition {

   private Object bean;

   private Class beanClass;

   private String beanClassName;

    private PropertyValues propertyValues;

   public BeanDefinition() {
   }

   public void setBean(Object bean) {
      this.bean = bean;
   }

   public Class getBeanClass() {
      return beanClass;
   }

   public void setBeanClass(Class beanClass) {
      this.beanClass = beanClass;
   }

   public String getBeanClassName() {
      return beanClassName;
   }

   public void setBeanClassName(String beanClassName) {
      this.beanClassName = beanClassName;
      try {
         this.beanClass = Class.forName(beanClassName);
      } catch (ClassNotFoundException e) {
         e.printStackTrace();
      }
   }

   public Object getBean() {
      return bean;
   }

    public PropertyValues getPropertyValues() {
        return propertyValues;
    }

    public void setPropertyValues(PropertyValues propertyValues) {
        this.propertyValues = propertyValues;
    }
}
```

```java
public class PropertyValue {

    private final String name;

    private final Object value;

    public PropertyValue(String name, Object value) {
        this.name = name;
        this.value = value;
    }

    public String getName() {
        return name;
    }

    public Object getValue() {
        return value;
    }
}
```

```java
public class PropertyValues {

   private final List<PropertyValue> propertyValueList = new ArrayList<PropertyValue>();

   public PropertyValues() {
   }

   public void addPropertyValue(PropertyValue pv) {
        //TODO:这里可以对于重复propertyName进行判断，直接用list没法做到
      this.propertyValueList.add(pv);
   }

   public List<PropertyValue> getPropertyValues() {
      return this.propertyValueList;
   }

}
```

Test

```java
public class BeanFactoryTest {

   @Test
   public void test() throws Exception {
      // 1.初始化beanfactory
      BeanFactory beanFactory = new AutowireCapableBeanFactory();

      // 2.bean定义
      BeanDefinition beanDefinition = new BeanDefinition();
      beanDefinition.setBeanClassName("us.codecraft.tinyioc.HelloWorldService");

      // 3.设置属性
      PropertyValues propertyValues = new PropertyValues();
      propertyValues.addPropertyValue(new PropertyValue("text", "Hello World!"));
        beanDefinition.setPropertyValues(propertyValues);

      // 4.生成bean
      beanFactory.registerBeanDefinition("helloWorldService", beanDefinition);

      // 5.获取bean
      HelloWorldService helloWorldService = (HelloWorldService) beanFactory.getBean("helloWorldService");
      helloWorldService.helloWorld();

   }
}
```

新加了PropertyValue 和 PropertyValues， 现在可以为bean 设置属性。 BeanDefinition中新增  PropertyValues，主要变化为 在 AutowireCapableBeanFactory 的 doCreateBean 中的实例化之后增加一步     `applyPropertyValues(bean, beanDefinition);`

利用反射机制和beanDefinition中的 propertyValues 设置 bean 的属性

```java
     Field declaredField = bean.getClass().getDeclaredField(propertyValue.getName());
     declaredField.setAccessible(true);
     declaredField.set(bean, propertyValue.getValue());
```


## step-4-config-beanfactory-with-xml

io

```java
public interface Resource {

    InputStream getInputStream() throws IOException;
}
```

```java
public class ResourceLoader {

    public Resource getResource(String location){
        URL resource = this.getClass().getClassLoader().getResource(location);
        return new UrlResource(resource);
    }
}
```

```java
public class UrlResource implements Resource {

    private final URL url;

    public UrlResource(URL url) {
        this.url = url;
    }

    @Override
    public InputStream getInputStream() throws IOException{
        URLConnection urlConnection = url.openConnection();
        urlConnection.connect();
        return urlConnection.getInputStream();
    }
}
```

xml

```java
public class XmlBeanDefinitionReader extends AbstractBeanDefinitionReader {

   public XmlBeanDefinitionReader(ResourceLoader resourceLoader) {
      super(resourceLoader);
   }

   @Override
   public void loadBeanDefinitions(String location) throws Exception {
      InputStream inputStream = getResourceLoader().getResource(location).getInputStream();
      doLoadBeanDefinitions(inputStream);
   }

   protected void doLoadBeanDefinitions(InputStream inputStream) throws Exception {
      DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
      DocumentBuilder docBuilder = factory.newDocumentBuilder();
      Document doc = docBuilder.parse(inputStream);
      // 解析bean
      registerBeanDefinitions(doc);
      inputStream.close();
   }

   public void registerBeanDefinitions(Document doc) {
      Element root = doc.getDocumentElement();

      parseBeanDefinitions(root);
   }

   protected void parseBeanDefinitions(Element root) {
      NodeList nl = root.getChildNodes();
      for (int i = 0; i < nl.getLength(); i++) {
         Node node = nl.item(i);
         if (node instanceof Element) {
            Element ele = (Element) node;
            processBeanDefinition(ele);
         }
      }
   }

   protected void processBeanDefinition(Element ele) {
      String name = ele.getAttribute("name");
      String className = ele.getAttribute("class");
        BeanDefinition beanDefinition = new BeanDefinition();
        processProperty(ele,beanDefinition);
        beanDefinition.setBeanClassName(className);
      getRegistry().put(name, beanDefinition);
   }

    private void processProperty(Element ele,BeanDefinition beanDefinition) {
        NodeList propertyNode = ele.getElementsByTagName("property");
        for (int i = 0; i < propertyNode.getLength(); i++) {
            Node node = propertyNode.item(i);
            if (node instanceof Element) {
                Element propertyEle = (Element) node;
                String name = propertyEle.getAttribute("name");
                String value = propertyEle.getAttribute("value");
                beanDefinition.getPropertyValues().addPropertyValue(new PropertyValue(name,value));
            }
        }
    }
}
```

```java
public interface BeanDefinitionReader {

    void loadBeanDefinitions(String location) throws Exception;
}
```

```java
public abstract class AbstractBeanDefinitionReader implements BeanDefinitionReader {

    private Map<String,BeanDefinition> registry;

    private ResourceLoader resourceLoader;

    protected AbstractBeanDefinitionReader(ResourceLoader resourceLoader) {
        this.registry = new HashMap<String, BeanDefinition>();
        this.resourceLoader = resourceLoader;
    }

    public Map<String, BeanDefinition> getRegistry() {
        return registry;
    }

    public ResourceLoader getResourceLoader() {
        return resourceLoader;
    }
}
```

Test



```java
public class BeanFactoryTest {

   @Test
   public void test() throws Exception {
      // 1.读取配置
      XmlBeanDefinitionReader xmlBeanDefinitionReader = new XmlBeanDefinitionReader(new ResourceLoader());
      xmlBeanDefinitionReader.loadBeanDefinitions("tinyioc.xml");

      // 2.初始化BeanFactory并注册bean
      BeanFactory beanFactory = new AutowireCapableBeanFactory();
      for (Map.Entry<String, BeanDefinition> beanDefinitionEntry : xmlBeanDefinitionReader.getRegistry().entrySet()) {
         beanFactory.registerBeanDefinition(beanDefinitionEntry.getKey(), beanDefinitionEntry.getValue());
      }

      // 3.获取bean
      HelloWorldService helloWorldService = (HelloWorldService) beanFactory.getBean("helloWorldService");
      helloWorldService.helloWorld();

   }
}
```

```java
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:aop="http://www.springframework.org/schema/aop"
       xmlns:tx="http://www.springframework.org/schema/tx" xmlns:context="http://www.springframework.org/schema/context"
       xsi:schemaLocation="
   http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans-2.5.xsd
   http://www.springframework.org/schema/aop http://www.springframework.org/schema/aop/spring-aop-2.5.xsd
   http://www.springframework.org/schema/tx http://www.springframework.org/schema/tx/spring-tx-2.5.xsd
   http://www.springframework.org/schema/context http://www.springframework.org/schema/context/spring-context-2.5.xsd">

    <bean name="helloWorldService" class="us.codecraft.tinyioc.HelloWorldService">
        <property name="text" value="Hello World!"></property>
    </bean>

</beans>
```

ps: 抽象类实现某个接口，可以不实现所有接口的方法，可以由它的子类实现。

实现了从xml中读取bean 的相关信息， 如 name, class, property

流程为 XmlBeanDefinitionReader 继承 抽象类AbstractBeanDefinitionReader, 现在的注册变为

```java
  for (Map.Entry<String, BeanDefinition> beanDefinitionEntry : xmlBeanDefinitionReader.getRegistry().entrySet()) {
     		       beanFactory.registerBeanDefinition(beanDefinitionEntry.getKey(), beanDefinitionEntry.getValue());
  }
```


## step-5-inject-bean-to-bean

```java
public class AutowireCapableBeanFactory extends AbstractBeanFactory {

....
   protected void applyPropertyValues(Object bean, BeanDefinition mbd) throws Exception {
      for (PropertyValue propertyValue : mbd.getPropertyValues().getPropertyValues()) {
         Field declaredField = bean.getClass().getDeclaredField(propertyValue.getName());
         declaredField.setAccessible(true);
         Object value = propertyValue.getValue();
         if (value instanceof BeanReference) {
            BeanReference beanReference = (BeanReference) value;
            value = getBean(beanReference.getName());
         }
         declaredField.set(bean, value);
      }
   }
    ....
}
```

```java
AbstractBeanFactory....
    
public void preInstantiateSingletons() throws Exception {
   for (Iterator it = this.beanDefinitionNames.iterator(); it.hasNext();) {
      String beanName = (String) it.next();
      getBean(beanName);
   }
}
```

```java
XmlBeanDefinitionReader... 

private void processProperty(Element ele, BeanDefinition beanDefinition) {
   NodeList propertyNode = ele.getElementsByTagName("property");
   for (int i = 0; i < propertyNode.getLength(); i++) {
      Node node = propertyNode.item(i);
      if (node instanceof Element) {
         Element propertyEle = (Element) node;
         String name = propertyEle.getAttribute("name");
         String value = propertyEle.getAttribute("value");
         if (value != null && value.length() > 0) {
            beanDefinition.getPropertyValues().addPropertyValue(new PropertyValue(name, value));
         } else {
            String ref = propertyEle.getAttribute("ref");
            if (ref == null || ref.length() == 0) {
               throw new IllegalArgumentException("Configuration problem: <property> element for property '"
                     + name + "' must specify a ref or value");
            }
            BeanReference beanReference = new BeanReference(ref);
            beanDefinition.getPropertyValues().addPropertyValue(new PropertyValue(name, beanReference));
         }
      }
   }
}
```

```java
public class BeanReference {

    private String name;

    private Object bean;

    public BeanReference(String name) {
        this.name = name;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public Object getBean() {
        return bean;
    }

    public void setBean(Object bean) {
        this.bean = bean;
    }
}
```

```java
<bean name="outputService" class="us.codecraft.tinyioc.OutputService">
    <property name="helloWorldService" ref="helloWorldService"></property>
</bean>

<bean name="helloWorldService" class="us.codecraft.tinyioc.HelloWorldService">
    <property name="text" value="Hello World!"></property>
    <property name="outputService" ref="outputService"></property>
</bean>
```

实现在 bean中注入bean； 现在 bean 的实例化时机可分为：1.延迟到该bean被引用(xml 中ref)或使用(getBean) 2.在beanFactory注册bean 之后直接实例化所有的bean

新增BeanReference

## step-6-invite-application-context

```java
public interface ApplicationContext extends BeanFactory {

}
```

```java
public abstract class AbstractApplicationContext implements ApplicationContext {
    protected AbstractBeanFactory beanFactory;

    public AbstractApplicationContext(AbstractBeanFactory beanFactory) {
        this.beanFactory = beanFactory;
    }

    public void refresh() throws Exception{
    }

    @Override
    public Object getBean(String name) throws Exception {
        return beanFactory.getBean(name);
    }
}
```

```java
public class ClassPathXmlApplicationContext extends AbstractApplicationContext {

   private String configLocation;

   public ClassPathXmlApplicationContext(String configLocation) throws Exception {
      this(configLocation, new AutowireCapableBeanFactory());
   }

   public ClassPathXmlApplicationContext(String configLocation, AbstractBeanFactory beanFactory) throws Exception {
      super(beanFactory);
      this.configLocation = configLocation;
      refresh();
   }

   @Override
   public void refresh() throws Exception {
      XmlBeanDefinitionReader xmlBeanDefinitionReader = new XmlBeanDefinitionReader(new ResourceLoader());
      xmlBeanDefinitionReader.loadBeanDefinitions(configLocation);
      for (Map.Entry<String, BeanDefinition> beanDefinitionEntry : xmlBeanDefinitionReader.getRegistry().entrySet()) {
         beanFactory.registerBeanDefinition(beanDefinitionEntry.getKey(), beanDefinitionEntry.getValue());
      }
   }

}
```

Test

```java
public class ApplicationContextTest {

    @Test
    public void test() throws Exception {
        ApplicationContext applicationContext = new ClassPathXmlApplicationContext("tinyioc.xml");
        HelloWorldService helloWorldService = (HelloWorldService) applicationContext.getBean("helloWorldService");
        helloWorldService.helloWorld();
    }
}
```

引入了ApplicationContext, 对外隐藏了读取配置、初始化beanFactory、注册beanDefinition的过程。

ApplicationContext 中 refresh方法可以重新读取配置、注册beanDefinition 



## step-7-method-interceptor-by-jdk-dynamic-proxy

aop

```java
public interface AopProxy {

    Object getProxy();
}
```

TargetSource 保存 bean object 和 bean class

```java
public class TargetSource {

   private Class targetClass;

   private Object target;

   public TargetSource(Object target, Class<?> targetClass) {
      this.target = target;
      this.targetClass = targetClass;
   }

   public Class getTargetClass() {
      return targetClass;
   }

   public Object getTarget() {
      return target;
   }
}
```

AdvisedSupport 存放  TargetSource ， 即被代理的类 ， 以及 MethodInterceptor ，即拦截器 （其实不是必需的）

```java
public class AdvisedSupport {

   private TargetSource targetSource;

    private MethodInterceptor methodInterceptor;

    public TargetSource getTargetSource() {
        return targetSource;
    }

    public void setTargetSource(TargetSource targetSource) {
        this.targetSource = targetSource;
    }

    public MethodInterceptor getMethodInterceptor() {
        return methodInterceptor;
    }

    public void setMethodInterceptor(MethodInterceptor methodInterceptor) {
        this.methodInterceptor = methodInterceptor;
    }
}
```

```java
public class ReflectiveMethodInvocation implements MethodInvocation {

   private Object target;

   private Method method;

   private Object[] args;

   public ReflectiveMethodInvocation(Object target, Method method, Object[] args) {
      this.target = target;
      this.method = method;
      this.args = args;
   }

   @Override
   public Method getMethod() {
      return method;
   }

   @Override
   public Object[] getArguments() {
      return args;
   }

   @Override
   public Object proceed() throws Throwable {
      return method.invoke(target, args);
   }

   @Override
   public Object getThis() {
      return target;
   }

   @Override
   public AccessibleObject getStaticPart() {
      return method;
   }
}
```

JdkDynamicAopProxy在invoke 方法中 调用 methodInterceptor 的 invoke， 从而改变原有方法的行为或在其基础之上增加自定义行为(如日志记录)

```java
public class JdkDynamicAopProxy implements AopProxy, InvocationHandler {

   private AdvisedSupport advised;

   public JdkDynamicAopProxy(AdvisedSupport advised) {
      this.advised = advised;
   }

    @Override
   public Object getProxy() {
      return Proxy.newProxyInstance(getClass().getClassLoader(), new Class[] { advised.getTargetSource()
            .getTargetClass() }, this);
   }

   @Override
   public Object invoke(final Object proxy, final Method method, final Object[] args) throws Throwable {
      MethodInterceptor methodInterceptor = advised.getMethodInterceptor();
      return methodInterceptor.invoke(new ReflectiveMethodInvocation(advised.getTargetSource().getTarget(), method,
            args));
   }

}
```

test

```java
public class JdkDynamicAopProxyTest {

   @Test
   public void testInterceptor() throws Exception {
      // --------- helloWorldService without AOP
      ApplicationContext applicationContext = new ClassPathXmlApplicationContext("tinyioc.xml");
      HelloWorldService helloWorldService = (HelloWorldService) applicationContext.getBean("helloWorldService");
      helloWorldService.helloWorld();

      // --------- helloWorldService with AOP
      // 1. 设置被代理对象(Joinpoint)
      AdvisedSupport advisedSupport = new AdvisedSupport();
      TargetSource targetSource = new TargetSource(helloWorldService, HelloWorldService.class);
      advisedSupport.setTargetSource(targetSource);

      // 2. 设置拦截器(Advice)
      TimerInterceptor timerInterceptor = new TimerInterceptor();
      advisedSupport.setMethodInterceptor(timerInterceptor);

      // 3. 创建代理(Proxy)
      JdkDynamicAopProxy jdkDynamicAopProxy = new JdkDynamicAopProxy(advisedSupport);
      HelloWorldService helloWorldServiceProxy = (HelloWorldService) jdkDynamicAopProxy.getProxy();

        // 4. 基于AOP的调用
        helloWorldServiceProxy.helloWorld();

   }
}
```

```java
public class TimerInterceptor implements MethodInterceptor {

   @Override
   public Object invoke(MethodInvocation invocation) throws Throwable {
      long time = System.nanoTime();
      System.out.println("Invocation of Method " + invocation.getMethod().getName() + " start!");
      Object proceed = invocation.proceed();
      System.out.println("Invocation of Method " + invocation.getMethod().getName() + " end! takes " + (System.nanoTime() - time)
            + " nanoseconds.");
      return proceed;
   }
}
```

## step-8-invite-pointcut-and-aspectj



```java
public class AspectJExpressionPointcut implements Pointcut, ClassFilter, MethodMatcher {

   private PointcutParser pointcutParser;

   private String expression; //pointCut 的 注解表达式

   private PointcutExpression pointcutExpression;

   private static final Set<PointcutPrimitive> DEFAULT_SUPPORTED_PRIMITIVES = new HashSet<PointcutPrimitive>();

   static {
      DEFAULT_SUPPORTED_PRIMITIVES.add(PointcutPrimitive.EXECUTION);
      DEFAULT_SUPPORTED_PRIMITIVES.add(PointcutPrimitive.ARGS);
      DEFAULT_SUPPORTED_PRIMITIVES.add(PointcutPrimitive.REFERENCE);
      DEFAULT_SUPPORTED_PRIMITIVES.add(PointcutPrimitive.THIS);
      DEFAULT_SUPPORTED_PRIMITIVES.add(PointcutPrimitive.TARGET);
      DEFAULT_SUPPORTED_PRIMITIVES.add(PointcutPrimitive.WITHIN);
      DEFAULT_SUPPORTED_PRIMITIVES.add(PointcutPrimitive.AT_ANNOTATION);
      DEFAULT_SUPPORTED_PRIMITIVES.add(PointcutPrimitive.AT_WITHIN);
      DEFAULT_SUPPORTED_PRIMITIVES.add(PointcutPrimitive.AT_ARGS);
      DEFAULT_SUPPORTED_PRIMITIVES.add(PointcutPrimitive.AT_TARGET);
   }

   public AspectJExpressionPointcut() {
      this(DEFAULT_SUPPORTED_PRIMITIVES);
   }

   public AspectJExpressionPointcut(Set<PointcutPrimitive> supportedPrimitives) {
      pointcutParser = PointcutParser
            .getPointcutParserSupportingSpecifiedPrimitivesAndUsingContextClassloaderForResolution(supportedPrimitives);
   }

   protected void checkReadyToMatch() {
      if (pointcutExpression == null) {
         pointcutExpression = buildPointcutExpression();
      }
   }

   private PointcutExpression buildPointcutExpression() {
      return pointcutParser.parsePointcutExpression(expression);
   }

   public void setExpression(String expression) {
      this.expression = expression;
   }

   @Override
   public ClassFilter getClassFilter() {
      return this;
   }

   @Override
   public MethodMatcher getMethodMatcher() {
      return this;
   }

   @Override
   public boolean matches(Class targetClass) {
      checkReadyToMatch();
      return pointcutExpression.couldMatchJoinPointsInType(targetClass);
   }

   @Override
   public boolean matches(Method method, Class targetClass) {
      checkReadyToMatch();
      ShadowMatch shadowMatch = pointcutExpression.matchesMethodExecution(method);
      if (shadowMatch.alwaysMatches()) {
         return true;
      } else if (shadowMatch.neverMatches()) {
         return false;
      }
      // TODO:其他情况不判断了！见org.springframework.aop.aspectj.RuntimeTestWalker
      return false;
   }
}
```

```java
public interface MethodMatcher {

    boolean matches(Method method, Class targetClass);
}
```

```java
public interface Pointcut {

    ClassFilter getClassFilter();

    MethodMatcher getMethodMatcher();

}
```

```java
public interface ClassFilter {

    boolean matches(Class targetClass);
}
```

```java
public class AspectJExpressionPointcutTest {

    @Test
    public void testClassFilter() throws Exception {
        String expression = "execution(* us.codecraft.tinyioc.*.*(..))";
        AspectJExpressionPointcut aspectJExpressionPointcut = new AspectJExpressionPointcut();
        aspectJExpressionPointcut.setExpression(expression);
        boolean matches = aspectJExpressionPointcut.getClassFilter().matches(HelloWorldService.class);
        Assert.assertTrue(matches);
    }

    @Test
    public void testMethodInterceptor() throws Exception {
        String expression = "execution(* us.codecraft.tinyioc.*.*(..))";
        AspectJExpressionPointcut aspectJExpressionPointcut = new AspectJExpressionPointcut();
        aspectJExpressionPointcut.setExpression(expression);
        boolean matches = aspectJExpressionPointcut.getMethodMatcher().matches(HelloWorldServiceImpl.class.getDeclaredMethod("helloWorld"),HelloWorldServiceImpl.class);
        Assert.assertTrue(matches);
    }
}
```

## step-9-auto-create-aop-proxy

现在可以根据xml中的property的name 来设置value

具体实现为修改`AutowireCapableBeanFactory` 中 `applyPropertyValues`

先找set方法，如不存在再找属性

```java
protected void applyPropertyValues(Object bean, BeanDefinition mbd) throws Exception {
   if (bean instanceof BeanFactoryAware) {
      ((BeanFactoryAware) bean).setBeanFactory(this);
   }
   for (PropertyValue propertyValue : mbd.getPropertyValues().getPropertyValues()) {
      Object value = propertyValue.getValue();
      if (value instanceof BeanReference) {
         BeanReference beanReference = (BeanReference) value;
         value = getBean(beanReference.getName());
      }

      try {
         Method declaredMethod = bean.getClass().getDeclaredMethod(
               "set" + propertyValue.getName().substring(0, 1).toUpperCase()
                     + propertyValue.getName().substring(1), value.getClass());
         declaredMethod.setAccessible(true);

         declaredMethod.invoke(bean, value);
      } catch (NoSuchMethodException e) {
         Field declaredField = bean.getClass().getDeclaredField(propertyValue.getName());
         declaredField.setAccessible(true);
         declaredField.set(bean, value);
      }
   }
}
```

`xml` 中

```java
<bean id="timeInterceptor" class="us.codecraft.tinyioc.aop.TimerInterceptor"></bean>

<bean id="autoProxyCreator" class="us.codecraft.tinyioc.aop.AspectJAwareAdvisorAutoProxyCreator"></bean>

<bean id="aspectjAspect" class="us.codecraft.tinyioc.aop.AspectJExpressionPointcutAdvisor">
    <property name="advice" ref="timeInterceptor"></property>
    <property name="expression" value="execution(* us.codecraft.tinyioc.*.*(..))"></property>
</bean>
```

`AspectJAwareAdvisorAutoProxyCreator` 充当的角色为拦截器？

实现 两个接口 `BeanPostProcessor` 、 `BeanFactoryAware`  

`BeanPostProcessor` 的主要作用为:

`AbstractBeanFactory` 的`getBean` 在实例化bean后新增了`initializeBean` 的步骤

```java
public Object getBean(String name) throws Exception {
   BeanDefinition beanDefinition = beanDefinitionMap.get(name);
   if (beanDefinition == null) {
      throw new IllegalArgumentException("No bean named " + name + " is defined");
   }
   Object bean = beanDefinition.getBean();
   if (bean == null) {
      bean = doCreateBean(beanDefinition);
      bean = initializeBean(bean, name);
   }
   return bean;
}
```

```java
protected Object initializeBean(Object bean, String name) throws Exception {
   for (BeanPostProcessor beanPostProcessor : beanPostProcessors) {
      bean = beanPostProcessor.postProcessBeforeInitialization(bean, name);
   }

   // TODO:call initialize method
   for (BeanPostProcessor beanPostProcessor : beanPostProcessors) {
           bean = beanPostProcessor.postProcessAfterInitialization(bean, name);
   }
       return bean;
}
```

`beanPostProcessors` 来自`AbstractApplicationContext` 的 `registerBeanPostProcessors` 

因此，我们可以对bean做初始化 或者 代理它



 `BeanFactoryAware`   的作用为在BeanFactory 为实现该接口的bean注入属性时（`AutowireCapableBeanFactory` 的`applyPropertyValues`）顺带注入beanFactory

```java
public class AspectJAwareAdvisorAutoProxyCreator implements BeanPostProcessor, BeanFactoryAware {

   private AbstractBeanFactory beanFactory;

   @Override
   public Object postProcessBeforeInitialization(Object bean, String beanName) throws Exception {
      return bean;
   }

   @Override
   public Object postProcessAfterInitialization(Object bean, String beanName) throws Exception {
      if (bean instanceof AspectJExpressionPointcutAdvisor) {
         return bean;
      }
        if (bean instanceof MethodInterceptor) {
            return bean;
        }
      List<AspectJExpressionPointcutAdvisor> advisors = beanFactory
            .getBeansForType(AspectJExpressionPointcutAdvisor.class);// 获得 pointCutAdvisor list
      for (AspectJExpressionPointcutAdvisor advisor : advisors) {
         if (advisor.getPointcut().getClassFilter().matches(bean.getClass())) {
            AdvisedSupport advisedSupport = new AdvisedSupport();
            advisedSupport.setMethodInterceptor((MethodInterceptor) advisor.getAdvice());
            advisedSupport.setMethodMatcher(advisor.getPointcut().getMethodMatcher());

            TargetSource targetSource = new TargetSource(bean, bean.getClass().getInterfaces());
            advisedSupport.setTargetSource(targetSource);

            return new JdkDynamicAopProxy(advisedSupport).getProxy();
         }
      }
      return bean;
   }

   @Override
   public void setBeanFactory(BeanFactory beanFactory) throws Exception {
      this.beanFactory = (AbstractBeanFactory) beanFactory;
   }
}
```



## step-10-invite-cglib-and-aopproxy-factory

cglib 的优势在于：即使被代理对象没有实现接口也能实现AOP.

`Enhancer` 的  `callback`相当于 invocationHandler



```java
public abstract class AbstractAopProxy implements AopProxy {

    protected AdvisedSupport advised;

    public AbstractAopProxy(AdvisedSupport advised) {
        this.advised = advised;
    }
}
```

```java
public class Cglib2AopProxy extends AbstractAopProxy {

   public Cglib2AopProxy(AdvisedSupport advised) {
      super(advised);
   }

   @Override
   public Object getProxy() {
      Enhancer enhancer = new Enhancer();
          enhancer.setSuperclass(advised.getTargetSource().getTargetClass());
      enhancer.setInterfaces(advised.getTargetSource().getInterfaces());
      enhancer.setCallback(new DynamicAdvisedInterceptor(advised));
      Object enhanced = enhancer.create();
      return enhanced;
   }

   private static class DynamicAdvisedInterceptor implements MethodInterceptor {

      private AdvisedSupport advised;

      private org.aopalliance.intercept.MethodInterceptor delegateMethodInterceptor;

      private DynamicAdvisedInterceptor(AdvisedSupport advised) {
         this.advised = advised;
         this.delegateMethodInterceptor = advised.getMethodInterceptor();
      }

      @Override
      public Object intercept(Object obj, Method method, Object[] args, MethodProxy proxy) throws Throwable {
         if (advised.getMethodMatcher() == null
               || advised.getMethodMatcher().matches(method, advised.getTargetSource().getTargetClass())) {
            return delegateMethodInterceptor.invoke(new CglibMethodInvocation(advised.getTargetSource().getTarget(), method, args, proxy));
         }
         return new CglibMethodInvocation(advised.getTargetSource().getTarget(), method, args, proxy).proceed();
      }
   }

   private static class CglibMethodInvocation extends ReflectiveMethodInvocation {

      private final MethodProxy methodProxy;

      public CglibMethodInvocation(Object target, Method method, Object[] args, MethodProxy methodProxy) {
         super(target, method, args);
         this.methodProxy = methodProxy;
      }

      @Override
      public Object proceed() throws Throwable {
         return this.methodProxy.invoke(this.target, this.arguments);
      }
   }

}
```



Test

```java
public class Cglib2AopProxyTest {

   @Test
   public void testInterceptor() throws Exception {
      // --------- helloWorldService without AOP
      ApplicationContext applicationContext = new ClassPathXmlApplicationContext("tinyioc.xml");
      HelloWorldService helloWorldService = (HelloWorldService) applicationContext.getBean("helloWorldService");
      helloWorldService.helloWorld();

      // --------- helloWorldService with AOP
      // 1. 设置被代理对象(Joinpoint)
      AdvisedSupport advisedSupport = new AdvisedSupport();
      TargetSource targetSource = new TargetSource(helloWorldService, HelloWorldServiceImpl.class,
            HelloWorldService.class);
      advisedSupport.setTargetSource(targetSource);

      // 2. 设置拦截器(Advice)
      TimerInterceptor timerInterceptor = new TimerInterceptor();
      advisedSupport.setMethodInterceptor(timerInterceptor);

      // 3. 创建代理(Proxy)
        Cglib2AopProxy cglib2AopProxy = new Cglib2AopProxy(advisedSupport);
      HelloWorldService helloWorldServiceProxy = (HelloWorldService) cglib2AopProxy.getProxy();

      // 4. 基于AOP的调用
      helloWorldServiceProxy.helloWorld();

   }
}
```