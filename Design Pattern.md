# Design Pattern

<https://www.cnblogs.com/leeSmall/p/10010006.html>

## 装饰器模式 Decorator 

 **定义：装饰模式是在不必改变原类文件和使用继承的情况下，动态的扩展一个对象的功能。它是通过创建一个包装对象，也就是装饰来包裹真实的对象。**

![img](http://www.zuoxiaolong.com/image/201608/25223009371.jpg)



从图中可以看到，我们装饰的是一个接口的任何实现类，而这些实现类也包括了装饰器本身，装饰器本身也可以再被装饰。

 **另外，这个类图只是装饰器模式的完整结构，但其实里面有很多可以变化的地方**

1.Component接口可以是接口也可以是抽象类，甚至是一个普通的父类（这个强烈不推荐，普通的类作为继承体系的超级父类不易于维护）

2.装饰器的抽象父类Decorator并不是必须的。

首先是待装饰的接口Component。

```Java
package com.decorator;

public interface Component {

    void method();
    
}
```

接下来便是我们的一个具体的接口实现类，也就是俗称的原始对象，或者说待装饰对象

```Java
package com.decorator;

public class ConcreteComponent implements Component{

    public void method() {
        System.out.println("原来的方法");
    }

}
```

下面便是我们的抽象装饰器父类，它主要是为装饰器定义了我们需要装饰的目标是什么，并对Component进行了基础的装饰

```Java
package com.decorator;

public abstract class Decorator implements Component{

    protected Component component;

    public Decorator(Component component) {
        super();
        this.component = component;
    }

    public void method() {
        component.method();
    }
    
}
```

```Java
package com.decorator;

public class ConcreteDecoratorA extends Decorator{

    public ConcreteDecoratorA(Component component) {
        super(component);
    }
    
    public void methodA(){
        System.out.println("被装饰器A扩展的功能");
    }

    public void method(){
        System.out.println("针对该方法加一层A包装");
        super.method();
        System.out.println("A包装结束");
    }
}
```

```Java
package com.decorator;

public class ConcreteDecoratorB extends Decorator{

    public ConcreteDecoratorB(Component component) {
        super(component);
    }
    
    public void methodB(){
        System.out.println("被装饰器B扩展的功能");
    }

    public void method(){
        System.out.println("针对该方法加一层B包装");
        super.method();
        System.out.println("B包装结束");
    }
}
```

```Java
package com.decorator;

public class Main {

    public static void main(String[] args) {
        Component component =new ConcreteComponent();//原来的对象
        System.out.println("------------------------------");
        component.method();//原来的方法
        ConcreteDecoratorA concreteDecoratorA = new ConcreteDecoratorA(component);//装饰成A
        System.out.println("------------------------------");
        concreteDecoratorA.method();//原来的方法
        concreteDecoratorA.methodA();//装饰成A以后新增的方法
        ConcreteDecoratorB concreteDecoratorB = new ConcreteDecoratorB(component);//装饰成B
        System.out.println("------------------------------");
        concreteDecoratorB.method();//原来的方法
        concreteDecoratorB.methodB();//装饰成B以后新增的方法
        concreteDecoratorB = new ConcreteDecoratorB(concreteDecoratorA);//装饰成A以后再装饰成B
        System.out.println("------------------------------");
        concreteDecoratorB.method();//原来的方法
        concreteDecoratorB.methodB();//装饰成B以后新增的方法
    }
}
```

从此可以看到，我们首先是使用的原始的类的方法，然后分别让A和B装饰完以后再调用，最后我们将两个装饰器一起使用，再调用该接口定义的方法。

上述当中，我们分别对待装饰类进行了原方法的装饰和新功能的增加，methodA和methodB就是新增加的功能，这些都是装饰器可以做的，当然两者并不一定兼有，但一般至少会有一种，否则也就失去了装饰的意义。

## 单例模式 Singleton

可以使用单例模式的类都有一个共性，那就是这个类没有自己的状态，换句话说，这些类无论你实例化多少个，其实都是一样的，而且更重要的一点是，这个类如果有两个或者两个以上的实例的话，我的程序竟然会产生程序错误或者与现实相违背的逻辑错误。

这样的话，如果我们不将这个类控制成单例的结构，应用中就会存在很多一模一样的类实例，这会非常浪费系统的内存资源，而且容易导致错误甚至一定会产生错误，所以我们单例模式所期待的目标或者说使用它的目的，是为了**尽可能的节约内存空间，减少无谓的GC消耗，并且使应用可以正常运作**

我稍微总结一下，一般一个类能否做成单例，最容易区别的地方就在于，**这些类，在应用中如果有两个或者两个以上的实例会引起错误，又或者我换句话说，就是这些类，在整个应用中，同一时刻，有且只能有一种状态。**

第一种方式，我们来看一下最标准也是最原始的单例模式的构造方式。

```java
public class Singleton {

    //一个静态的实例
    private static Singleton singleton;
    //私有化构造函数
    private Singleton(){}
    //给出一个公共的静态方法返回一个单一实例
    public static Singleton getInstance(){
        if (singleton == null) {
            singleton = new Singleton();
        }
        return singleton;
    }
}
```

这是在不考虑并发访问的情况下标准的单例模式的构造方式，这种方式通过几个地方来限制了我们取到的实例是唯一的。

-             **1.静态实例，带有static关键字的属性在每一个类中都是唯一的。**

-             **2.限制客户端随意创造实例，即私有化构造方法，此为保证单例的最重要的一步。**

-             **3.给一个公共的获取实例的静态方法，注意，是静态的方法，因为这个方法是在我们未获取到实例的时候就要提供给客户端调用的，所以如果是非静态的话，那就变成一个矛盾体了，因为非静态的方法必须要拥有实例才可以调用。**

-             **4.判断只有持有的静态实例为null时才调用构造方法创造一个实例，否则就直接返回。**

上面的例子不适用于多线程，我们最容易想到的解决方式应该是下面这样的方式，直接将整个方法同步。

```Java
public class BadSynchronizedSingleton {

    //一个静态的实例
    private static BadSynchronizedSingleton synchronizedSingleton;
    //私有化构造函数
    private BadSynchronizedSingleton(){}
    //给出一个公共的静态方法返回一个单一实例
    public synchronized static BadSynchronizedSingleton getInstance(){
        if (synchronizedSingleton == null) {
            synchronizedSingleton = new BadSynchronizedSingleton();
        }
        return synchronizedSingleton;
    }
    
}
```

上面的做法很简单，就是将整个获取实例的方法同步，这样在一个线程访问这个方法时，其它所有的线程都要处于挂起等待状态，倒是避免了刚才同步访问创造出多个实例的危险。

其实我们同步的地方只是需要发生在单例的实例还未创建的时候，在实例创建以后，获取实例的方法就没必要再进行同步控制了，所以我们将上面的示例改为很多教科书中标准的单例模式版本，也称为**双重加锁**。

```Java
public class SynchronizedSingleton {

    //一个静态的实例
    private static SynchronizedSingleton synchronizedSingleton;
    //私有化构造函数
    private SynchronizedSingleton(){}
    //给出一个公共的静态方法返回一个单一实例
    public static SynchronizedSingleton getInstance(){
        if (synchronizedSingleton == null) {
            synchronized (SynchronizedSingleton.class) {
                if (synchronizedSingleton == null) {
                    synchronizedSingleton = new SynchronizedSingleton();
                }
            }
        }
        return synchronizedSingleton;
    }
}
```

这种做法与上面那种最无脑的同步做法相比就要好很多了，因为我们只是在当前实例为null，也就是实例还未创建时才进行同步，否则就直接返回，这样就节省了很多无谓的线程等待时间，值得注意的是在同步块中，我们再次判断了synchronizedSingleton是否为null，解释下为什么要这样做。

假设我们去掉同步块中的是否为null的判断，有这样一种情况，假设A线程和B线程都在同步块外面判断了synchronizedSingleton为null，结果A线程首先获得了线程锁，进入了同步块，然后A线程会创造一个实例，此时synchronizedSingleton已经被赋予了实例，A线程退出同步块，直接返回了第一个创造的实例，此时B线程获得线程锁，也进入同步块，此时A线程其实已经创造好了实例，B线程正常情况应该直接返回的，但是因为同步块里没有判断是否为null，直接就是一条创建实例的语句，所以B线程也会创造一个实例返回，此时就造成创造了多个实例的情况

经过刚才的分析，貌似上述双重加锁的示例看起来是没有问题了，但如果再进一步深入考虑的话，其实仍然是有问题的。

如果我们深入到JVM中去探索上面这段代码，它就有可能（注意，只是有可能）是有问题的。因为虚拟机在执行创建实例的这一步操作的时候，其实是分了好几步去进行的，也就是说创建一个新的对象并非是原子性操作。在有些JVM中上述做法是没有问题的，但是有些情况下是会造成莫名的错误。

首先要明白在JVM创建新的对象时，主要要经过三步。

-               **1.分配内存**

-               **2.初始化构造器**

-               **3.将对象指向分配的内存的地址**

这种顺序在上述双重加锁的方式是没有问题的，因为这种情况下JVM是完成了整个对象的构造才将内存的地址交给了对象。但是如果2和3步骤是相反的（2和3可能是相反的是因为JVM会针对字节码进行调优，而其中的一项调优便是调整指令的执行顺序），就会出现问题了。

因为这时将会先将内存地址赋给对象，针对上述的双重加锁，就是说先将分配好的内存地址指给synchronizedSingleton，然后再进行初始化构造器，这时候后面的线程去请求getInstance方法时，会认为synchronizedSingleton对象已经实例化了，直接返回一个引用。如果在初始化构造器之前，这个线程使用了synchronizedSingleton，就会产生莫名的错误。

所以我们在语言级别无法完全避免错误的发生，我们只有将该任务交给JVM，所以有一种比较标准的单例模式。如下所示。

```Java
public class Singleton {
    
    private Singleton(){}
    
    public static Singleton getInstance(){
        return SingletonInstance.instance;
    }
    
    private static class SingletonInstance{
        
        static Singleton instance = new Singleton();
        
    }
}
```

首先来说一下，这种方式为何会避免了上面莫名的错误，主要是因为一个类的静态属性只会在第一次加载类时初始化，这是JVM帮我们保证的，所以我们无需担心并发访问的问题。所以在初始化进行一半的时候，别的线程是无法使用的，因为JVM会帮我们强行同步这个过程。另外由于静态变量只初始化一次，所以singleton仍然是单例的。



**饿汉式加载**

```Java
public class Singleton {
    
    private static Singleton singleton = new Singleton();
    
    private Singleton(){}
    
    public static Singleton getInstance(){
        return singleton;
    }
    
}
```

上述方式与我们最后一种给出的方式类似，只不过没有经过内部类处理，这种方式最主要的缺点就是一旦我访问了Singleton的任何其他的静态域，就会造成实例的初始化，而事实是可能我们从始至终就没有使用这个实例，造成内存的浪费。

第二种不太常见的，与双重锁定一模一样，只是给**静态的实例属性加上关键字volatile**，标识这个属性是不需要优化的。这样也不会出现实例化发生一半的情况，因为加入了volatile关键字，就等于禁止了JVM自动的指令重排序优化，并且强行保证线程中对变量所做的任何写入操作对其他线程都是即时可见的。这里没有篇幅去介绍volatile以及JVM中变量访问时所做的具体动作，总之volatile会强行将对该变量的所有读和取操作绑定成一个不可拆分的动作。

 

使用CAS

```java
public class Singleton {
    private static final AtomicReference<Singleton> INSTANCE = new AtomicReference<Singleton>();

    private Singleton() {}

    public static Singleton getInstance() {
        for (;;) {
            Singleton singleton = INSTANCE.get();
            if (null != singleton) {
                return singleton;
            }

            singleton = new Singleton();
            if (INSTANCE.compareAndSet(null, singleton)) {
                return singleton;
            }
        }
    }
}
```

缺点是：可能会一直执行不成功，如果N个线程同时执行到singleton = new Singleton(); 的时候，会有大量对象创建，很可能导致内存溢出。

## [代理模式 Proxy](www.zuoxiaolong.com/html/article_123.html#)

代理模式可以分为静态代理和动态代理。

两种代理从虚拟机加载类的角度来讲，本质上是一样的，都是在原有类的行为基础上，加入一些行为，甚至完全替代原有的行为。

静态代理采用的方式就是我们手动将这些行为还进去，然后让编译器帮我们编译，同时也就将字节码在原有类的基础上加入一些其他东西或者替代原有的东西，产生一个新的与原有类接口相同却行为不同的类型。

说归说，我们来真实的去试验一下，实验的话需要找一个示例，就拿我们的数据库连接来做例子吧。

我们都知道，数据库连接是很珍贵的资源，频繁的开关数据库连接是非常浪费服务器的CPU资源以及内存的，所以我们一般都是使用数据库连接池来解决这一问题，即创造一堆等待被使用的连接，等到用的时候就从池里取一个，不用了再放回去，数据库连接在整个应用启动期间，几乎是不关闭的，除非是超过了最大闲置时间。

但是在程序员编写程序的时候，会经常使用connection.close()这样的方法，去关闭数据库连接，而且这样做是对的，所以你并不能告诉程序员们说，你们使用连接都不要关了，去调用一个其他的类似归还给连接池的方法吧。这是不符合程序员的编程思维的，也很勉强，而且具有风险性，因为程序员会忘的。

解决这一问题的办法就是使用代理模式，因为代理模式可以替代原有类的行为，所以我们要做的就是替换掉connection的close行为。

下面是connection接口原有的样子，我去掉了很多方法，因为都类似，全贴上来占地方。

```java
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Wrapper;

public interface Connection  extends Wrapper {
    
    Statement createStatement() throws SQLException;
    
    void close() throws SQLException;
    
}
```

这里只贴了两个方法，但是我们代理的精髓只要两个方法就能掌握，下面使用静态代理，采用静态代理我们通常会使用组合的方式，为了保持对程序猿是透明的，我们实现Connection这个接口， 如下所示。

```java
import java.sql.SQLException;
import java.sql.Statement;


public class ConnectionProxy implements Connection{
    
    private Connection connection;
    
    public ConnectionProxy(Connection connection) {
        super();
        this.connection = connection;
    }

    public Statement createStatement() throws SQLException{
        return connection.createStatement();
    }
    
    public void close() throws SQLException{
        System.out.println("不真正关闭连接，归还给连接池");
    }

}
```

我们在构造方法中让调用者强行传入一个原有的连接，接下来我们将我们不关心的方法，交给真正的Connection接口去处理，就像createStatement方法一样，而我们将真正关心的close方法用我们自己希望的方式去进行。

此处为了更形象，LZ给出一个本人写的非常简单的连接池，意图在于表明实现的思路。下面我们来看一下连接池的变化，在里面注明了变化点。

```java
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.LinkedList;

public class DataSource {
    
    private static LinkedList<Connection> connectionList = new LinkedList<Connection>();
    
    static{
        try {
            Class.forName("com.mysql.jdbc.Driver");
        } catch (ClassNotFoundException e) {
            e.printStackTrace();
        }
    }
    
    private static Connection createNewConnection() throws SQLException{
        return DriverManager.getConnection("url","username", "password");
    }
    
    private DataSource(){
        if (connectionList == null || connectionList.size() == 0) {
            for (int i = 0; i < 10; i++) {
                try {
                    connectionList.add(createNewConnection());
                } catch (SQLException e) {
                    e.printStackTrace();
                }
            }
        }
    }
    
    public Connection getConnection() throws Exception{
        if (connectionList.size() > 0) {
            //return connectionList.remove();  这是原有的方式，直接返回连接，这样可能会被程序员把连接给关闭掉
            //下面是使用代理的方式，程序员再调用close时，就会归还到连接池
            return new ConnectionProxy(connectionList.remove());
        }
        return null;
    }
    
    public void recoveryConnection(Connection connection){
        connectionList.add(connection);
    }
    
    public static DataSource getInstance(){
        return DataSourceInstance.dataSource;
    }
    
    private static class DataSourceInstance{
        
        private static DataSource dataSource = new DataSource();
        
    }
    
}
```

连接池我们把它做成单例，所以假设是上述连接池的话，我们代理中的close方法可以再具体化一点，就像下面这样，用归还给连接池的动作取代关闭连接的动作。

```java
    public void close() throws SQLException{
        DataSource.getInstance().recoveryConnection(connection);
    }
```

好了，这下我们的连接池返回的连接全是代理，就算程序员调用了close方法也只会归还给连接池了。

**我们使用代理模式解决了上述问题，从静态代理的使用上来看，我们一般是这么做的。**

 **1，代理类一般要持有一个被代理的对象的引用。**

**2，对于我们不关心的方法，全部委托给被代理的对象处理。**

**3，自己处理我们关心的方法。**

这种代理是死的，不会在运行时动态创建，因为我们相当于在编译期，也就是你按下CTRL+S的那一刻，就给被代理的对象生成了一个不可动态改变的代理类。

静态代理对于这种，被代理的对象很固定，我们只需要去代理一个类或者若干固定的类，数量不是太多的时候，可以使用，而且其实效果比动态代理更好，因为动态代理就是在运行期间动态生成代理类，所以需要消耗的时间会更久一点。就像上述的情况，其实就比较适合使用静态代理。

下面介绍下动态代理，动态代理是JDK自带的功能，它需要你去实现一个InvocationHandler接口，并且调用Proxy的静态方法去产生代理类。

接下来我们依然使用上面的示例，但是这次该用动态代理处理，我们来试一下看如何做。

```java
import java.lang.reflect.InvocationHandler;
import java.lang.reflect.Method;
import java.lang.reflect.Proxy;
import java.sql.Connection;


public class ConnectionProxy implements InvocationHandler{
    
    private Connection connection;
    
    public ConnectionProxy(Connection connection) {
        super();
        this.connection = connection;
    }

    public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
        //这里判断是Connection接口的close方法的话
        if (Connection.class.isAssignableFrom(proxy.getClass()) && method.getName().equals("close")) {
            //我们不执行真正的close方法
            //method.invoke(connection, args);
            //将连接归还连接池
            DataSource.getInstance().recoveryConnection(connection);
            return null;
        }else {
            return method.invoke(connection, args);
        }
    }
    
    public Connection getConnectionProxy(){
        return (Connection) Proxy.newProxyInstance(getClass().getClassLoader(), new Class[]{Connection.class}, this);
    }
    
}
```

上面是我们针对connection写的动态代理，InvocationHandler接口只有一个invoke方法需要实现，这个方法是用来在生成的代理类用回调使用的，关于动态代理的原理一会做详细的分析，这里我们先只关注用法。很显然，动态代理是将每个方法的具体执行过程交给了我们在invoke方法里处理。而具体的使用方法，我们只需要创造一个ConnectionProxy的实例，并且将调用getConnectionProxy方法的返回结果作为数据库连接池返回的连接就可以了。

上述便是我们针对connection做动态代理的方式，但是我们从中得不到任何好处，除了能少写点代码以外，因为这个动态代理还是只能代理Connection这一个接口，如果我们写出这种动态代理的方式的话，说明我们应该使用静态代理处理这个问题，因为它代表我们其实只希望代理一个类就好。从重构的角度来说，其实更简单点，那就是在你发现你使用静态代理的时候，需要写一大堆重复代码的时候，就请改用动态代理试试吧。

通常情况下，动态代理的使用是为了解决这样一种问题，就是我们需要代理一系列类的某一些方法，最典型的应用就是我们前段时间讨论过的springAOP，我们需要创造出一批代理类，切入到一系列类当中的某一些方法中。下面给出一个经常使用的动态代理方式。

```Java
import java.lang.reflect.InvocationHandler;
import java.lang.reflect.Method;
import java.lang.reflect.Proxy;


public class DynamicProxy implements InvocationHandler{
    
    private Object source;
    
    public DynamicProxy(Object source) {
        super();
        this.source = source;
    }
    
    public void before(){
        System.out.println("在方法前做一些事，比如打开事务");
    }
    
    public void after(){
        System.out.println("在方法返回前做一些事，比如提交事务");
    }

    public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
        //假设我们切入toString方法，其他其实也是类似的，一般我们这里大部分是针对特定的方法做事情的，通常不会对类的全部方法切入
        //比如我们常用的事务管理器，我们通常配置的就是对save,update,delete等方法才打开事务
        if (method.getName().equals("toString")) {
            before();
        }
        Object result = method.invoke(source, args);
        if (method.getName().equals("toString")) {
            after();
        }
        return result;
    }
    
    public Object getProxy(){
        return Proxy.newProxyInstance(getClass().getClassLoader(), source.getClass().getInterfaces(), this);
    }
    
    
}
```

上述我做了一些注释，其实已经说明一些问题，这个代理类的作用是可以代理任何类，因为它被传入的对象是Object，而不再是具体的类，比如刚才的Connection，这些产生的代理类在调用toString方法时会被插入before方法和after方法。

**动态代理有一个强制性要求，就是被代理的类必须实现了某一个接口，或者本身就是接口，就像我们的Connection。**

## [观察者模式](http://www.zuoxiaolong.com/html/article_119.html#)

**简单点概括成通俗的话来说，就是一个类管理着所有依赖于它的观察者类，并且它状态变化时会主动给这些依赖它的类发出通知。**

![img](http://www.zuoxiaolong.com/image/201608/25223027564.jpg)

简单观察者模式

```java
package net;

//这个接口是为了提供一个统一的观察者做出相应行为的方法
public interface Observer {

    void update(Observable o);
    
}
```

```java
package net;

public class ConcreteObserver1 implements Observer{

    public void update(Observable o) {
        System.out.println("观察者1观察到" + o.getClass().getSimpleName() + "发生变化");
        System.out.println("观察者1做出相应");
    }

}
```

```java
package net;

public class ConcreteObserver2 implements Observer{

    public void update(Observable o) {
        System.out.println("观察者2观察到" + o.getClass().getSimpleName() + "发生变化");
        System.out.println("观察者2做出相应");
    }

}
```

```java
package net;

import java.util.ArrayList;
import java.util.List;

public class Observable {

    List<Observer> observers = new ArrayList<Observer>();
    
    public void addObserver(Observer o){
        observers.add(o);
    }
    
    public void changed(){
        System.out.println("我是被观察者，我已经发生变化了");
        notifyObservers();//通知观察自己的所有观察者
    }
    
    public void notifyObservers(){
        for (Observer observer : observers) {
            observer.update(this);
        }
    }
}
```

JDK版

```java
//观察者接口，每一个观察者都必须实现这个接口
public interface Observer {
    //这个方法是观察者在观察对象产生变化时所做的响应动作，从中传入了观察的对象和一个预留参数
    void update(Observable o, Object arg);

}
```

```java
import java.util.Vector;

//被观察者类
public class Observable {
    //这是一个改变标识，来标记该被观察者有没有改变
    private boolean changed = false;
    //持有一个观察者列表
    private Vector obs;
    
    public Observable() {
    obs = new Vector();
    }
    //添加观察者，添加时会去重
    public synchronized void addObserver(Observer o) {
        if (o == null)
            throw new NullPointerException();
    if (!obs.contains(o)) {
        obs.addElement(o);
    }
    }
    //删除观察者
    public synchronized void deleteObserver(Observer o) {
        obs.removeElement(o);
    }
    //notifyObservers(Object arg)的重载方法
    public void notifyObservers() {
    notifyObservers(null);
    }
    //通知所有观察者，被观察者改变了，你可以执行你的update方法了。
    public void notifyObservers(Object arg) {
        //一个临时的数组，用于并发访问被观察者时，留住观察者列表的当前状态，这种处理方式其实也算是一种设计模式，即备忘录模式。
        Object[] arrLocal;
    //注意这个同步块，它表示在获取观察者列表时，该对象是被锁定的
    //也就是说，在我获取到观察者列表之前，不允许其他线程改变观察者列表
    synchronized (this) {
        //如果没变化直接返回
        if (!changed)
                return;
            //这里将当前的观察者列表放入临时数组
            arrLocal = obs.toArray();
            //将改变标识重新置回未改变
            clearChanged();
        }
        //注意这个for循环没有在同步块，此时已经释放了被观察者的锁，其他线程可以改变观察者列表
        //但是这并不影响我们当前进行的操作，因为我们已经将观察者列表复制到临时数组
        //在通知时我们只通知数组中的观察者，当前删除和添加观察者，都不会影响我们通知的对象
        for (int i = arrLocal.length-1; i>=0; i--)
            ((Observer)arrLocal[i]).update(this, arg);
    }

    //删除所有观察者
    public synchronized void deleteObservers() {
    obs.removeAllElements();
    }

    //标识被观察者被改变过了
    protected synchronized void setChanged() {
    changed = true;
    }
    //标识被观察者没改变
    protected synchronized void clearChanged() {
    changed = false;
    }
    //返回被观察者是否改变
    public synchronized boolean hasChanged() {
    return changed;
    }
    //返回观察者数量
    public synchronized int countObservers() {
    return obs.size();
    }
}
```

```java
//读者类，要实现观察者接口
public class Reader implements Observer{
    
    private String name;
    
    public Reader(String name) {
        super();
        this.name = name;
    }

    public String getName() {
        return name;
    }
    
    //读者可以关注某一位作者，关注则代表把自己加到作者的观察者列表里
    public void subscribe(String writerName){
        WriterManager.getInstance().getWriter(writerName).addObserver(this);
    }
    
    //读者可以取消关注某一位作者，取消关注则代表把自己从作者的观察者列表里删除
    public void unsubscribe(String writerName){
        WriterManager.getInstance().getWriter(writerName).deleteObserver(this);
    }
    
    //当关注的作者发表新小说时，会通知读者去看
    public void update(Observable o, Object obj) {
        if (o instanceof Writer) {
            Writer writer = (Writer) o;
            System.out.println(name+"知道" + writer.getName() + "发布了新书《" + writer.getLastNovel() + "》，非要去看！");
        }
    }
    
}
```

```java
//作者类，要继承自被观察者类
public class Writer extends Observable{
    
    private String name;//作者的名称
    
    private String lastNovel;//记录作者最新发布的小说

    public Writer(String name) {
        super();
        this.name = name;
        WriterManager.getInstance().add(this);
    }

    //作者发布新小说了，要通知所有关注自己的读者
    public void addNovel(String novel) {
        System.out.println(name + "发布了新书《" + novel + "》！");
        lastNovel = novel;
        setChanged();
        notifyObservers();
    }
    
    public String getLastNovel() {
        return lastNovel;
    }

    public String getName() {
        return name;
    }

}
```

```java
import java.util.HashMap;
import java.util.Map;

//管理器，保持一份独有的作者列表
public class WriterManager{
    
    private Map<String, Writer> writerMap = new HashMap<String, Writer>();

    //添加作者
    public void add(Writer writer){
        writerMap.put(writer.getName(), writer);
    }
    //根据作者姓名获取作者
    public Writer getWriter(String name){
        return writerMap.get(name);
    }
    
    //单例
    private WriterManager(){}
    
    public static WriterManager getInstance(){
        return WriterManagerInstance.instance;
    }
    private static class WriterManagerInstance{
        
        private static WriterManager instance = new WriterManager();
        
    }
}
```

**观察者模式分离了观察者和被观察者二者的责任，这样让类之间各自维护自己的功能，专注于自己的功能，会提高系统的可维护性和可重用性**。

事件驱动模式 

首先事件驱动模型与观察者模式勉强的对应关系可以看成是，被观察者相当于事件源，观察者相当于监听器，事件源会产生事件，监听器监听事件。所以这其中就搀和到四个类，事件源，事件，监听器以及具体的监听器。

```java
package java.util;

/**
 * A tagging interface that all event listener interfaces must extend.
 * @since JDK1.1
 */
public interface EventListener {
}
```

```java
public class EventObject implements java.io.Serializable {

    private static final long serialVersionUID = 5516075349620653480L;

    /**
     * The object on which the Event initially occurred.
     */
    protected transient Object  source;

    /**
     * Constructs a prototypical Event.
     *
     * @param    source    The object on which the Event initially occurred.
     * @exception  IllegalArgumentException  if source is null.
     */
    public EventObject(Object source) {
    if (source == null)
        throw new IllegalArgumentException("null source");

        this.source = source;
    }

    /**
     * The object on which the Event initially occurred.
     *
     * @return   The object on which the Event initially occurred.
     */
    public Object getSource() {
        return source;
    }

    /**
     * Returns a String representation of this EventObject.
     *
     * @return  A a String representation of this EventObject.
     */
    public String toString() {
        return getClass().getName() + "[source=" + source + "]";
    }
}
```

```java
import java.util.EventObject;

public class WriterEvent extends EventObject{
    
    private static final long serialVersionUID = 8546459078247503692L;

    public WriterEvent(Writer writer) {
        super(writer);
    }
    
    public Writer getWriter(){
        return (Writer) super.getSource();
    }

}
```

```java
import java.util.EventListener;

public interface WriterListener extends EventListener{

    void addNovel(WriterEvent writerEvent);
    
}
```

```java
import java.util.HashSet;
import java.util.Set;

//作者类
public class Writer{
    
    private String name;//作者的名称
    
    private String lastNovel;//记录作者最新发布的小说
    
    private Set<WriterListener> writerListenerList = new HashSet<WriterListener>();//作者类要包含一个自己监听器的列表

    public Writer(String name) {
        super();
        this.name = name;
        WriterManager.getInstance().add(this);
    }

    //作者发布新小说了，要通知所有关注自己的读者
    public void addNovel(String novel) {
        System.out.println(name + "发布了新书《" + novel + "》！");
        lastNovel = novel;
        fireEvent();
    }
    //触发发布新书的事件，通知所有监听这件事的监听器
    private void fireEvent(){
        WriterEvent writerEvent = new WriterEvent(this);
        for (WriterListener writerListener : writerListenerList) {
            writerListener.addNovel(writerEvent);
        }
    }
    //提供给外部注册成为自己的监听器的方法
    public void registerListener(WriterListener writerListener){
        writerListenerList.add(writerListener);
    }
    //提供给外部注销的方法
    public void unregisterListener(WriterListener writerListener){
        writerListenerList.remove(writerListener);
    }
    
    public String getLastNovel() {
        return lastNovel;
    }

    public String getName() {
        return name;
    }

}
```

```java
public class Reader implements WriterListener{

    private String name;
    
    public Reader(String name) {
        super();
        this.name = name;
    }

    public String getName() {
        return name;
    }
    
    //读者可以关注某一位作者，关注则代表把自己加到作者的监听器列表里
    public void subscribe(String writerName){
        WriterManager.getInstance().getWriter(writerName).registerListener(this);
    }
    
    //读者可以取消关注某一位作者，取消关注则代表把自己从作者的监听器列表里注销
    public void unsubscribe(String writerName){
        WriterManager.getInstance().getWriter(writerName).unregisterListener(this);
    }
    
    public void addNovel(WriterEvent writerEvent) {
        Writer writer = writerEvent.getWriter();
        System.out.println(name+"知道" + writer.getName() + "发布了新书《" + writer.getLastNovel() + "》，非要去看！");
    }

}
```

- **观察者模式：发布（release）--订阅（subscibe），变化（change）--更新（update）**

-                **事件驱动模型：请求（request）--响应（response），事件发生（occur）--事件处理（handle）**  



## [策略模式 Strategy](http://www.zuoxiaolong.com/html/article_118.html#)

**定义：策略模式定义了一系列的算法，并将每一个算法封装起来，而且使它们还可以相互替换。策略模式让算法独立于使用它的客户而独立变化。**

简单的例子

```java
package net;

public interface Strategy {

    void algorithm();
    
}

class ConcreteStrategyA implements Strategy{

    public void algorithm() {
        System.out.println("采用策略A计算");
    }
    
}
class ConcreteStrategyB implements Strategy{

    public void algorithm() {
        System.out.println("采用策略B计算");
    }
    
}
class ConcreteStrategyC implements Strategy{

    public void algorithm() {
        System.out.println("采用策略C计算");
    }
    
}
```

```java
package net;

public class Context {

    Strategy strategy;
    
    public void method(){
        strategy.algorithm();
    }

    public void setStrategy(Strategy strategy) {
        this.strategy = strategy;
    }
}
```

```java
package net;


public class Client {

    public static void main(String[] args) throws Exception {
        Context context = new Context();
        context.setStrategy(new ConcreteStrategyA());
        context.method();
        
        context.setStrategy(new ConcreteStrategyB());
        context.method();
        
        context.setStrategy(new ConcreteStrategyC());
        context.method();
    }
}
```

另一个收银的例子

升级版 支持策略叠加

```java
package com.calprice;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

//我们定义一个嵌套注解
@Target(ElementType.ANNOTATION_TYPE)
@Retention(RetentionPolicy.RUNTIME)
public @interface ValidRegion {
    int max() default Integer.MAX_VALUE;
    int min() default Integer.MIN_VALUE;
    
    //既然可以任意组合，我们就需要给策略定义下顺序，就比如刚才说的2000那个例子，按先返后打折的顺序是800，反过来就是600了。
    //所以我们必须支持这一特性，默认0，为最优先
    int order() default 0;
}
```

```java
package com.calprice;
import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

//这是我们的总额有效区间注解，可以给策略添加有效区间的设置
@Target(ElementType.TYPE)//表示只能给类添加该注解
@Retention(RetentionPolicy.RUNTIME)//这个必须要将注解保留在运行时
public @interface TotalValidRegion {
    //我们引用有效区间注解
    ValidRegion value() default @ValidRegion;

}
```

```java
package com.calprice;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

//这是我们针对单次消费的有效区间注解，可以给策略添加有效区间的设置
@Target(ElementType.TYPE)//表示只能给类添加该注解
@Retention(RetentionPolicy.RUNTIME)//这个必须要将注解保留在运行时
public @interface OnceValidRegion{
    //我们引用有效区间注解
    ValidRegion value() default @ValidRegion;
}
```

```java
package com.calprice;

import java.io.File;
import java.io.FileFilter;
import java.lang.annotation.Annotation;
import java.net.URISyntaxException;
import java.util.ArrayList;
import java.util.List;
import java.util.SortedMap;
import java.util.TreeMap;

//我们使用一个标准的简单工厂来改进一下策略模式
public class CalPriceFactory {
    
    private static final String CAL_PRICE_PACKAGE = "com.calprice";//这里是一个常量，表示我们扫描策略的包，这是LZ的包名
    
    private ClassLoader classLoader = getClass().getClassLoader();//我们加载策略时的类加载器，我们任何类运行时信息必须来自该类加载器
    
    private List<Class<? extends CalPrice>> calPriceList;//策略列表
    
    //根据客户的总金额产生相应的策略
    public CalPrice createCalPrice(Customer customer){
        //变化点:为了支持优先级排序，我们采用可排序的MAP支持,这个Map是为了储存我们当前策略的运行时类信息
        SortedMap<Integer, Class<? extends CalPrice>> clazzMap = new TreeMap<Integer, Class<? extends CalPrice>>();
        //在策略列表查找策略
        for (Class<? extends CalPrice> clazz : calPriceList) {
            Annotation validRegion = handleAnnotation(clazz);//获取该策略的注解
            //变化点：根据注解类型进行不同的判断
            if (validRegion instanceof TotalValidRegion) {
                TotalValidRegion totalValidRegion = (TotalValidRegion) validRegion;
                //判断总金额是否在注解的区间
                if (customer.getTotalAmount() > totalValidRegion.value().min() && customer.getTotalAmount() < totalValidRegion.value().max()) {
                    clazzMap.put(totalValidRegion.value().order(), clazz);//将采用的策略放入MAP
                }
            }
            else if (validRegion instanceof OnceValidRegion) {
                OnceValidRegion onceValidRegion = (OnceValidRegion) validRegion;
                //判断单次金额是否在注解的区间，注意这次判断的是客户当次消费的金额
                if (customer.getAmount() > onceValidRegion.value().min() && customer.getAmount() < onceValidRegion.value().max()) {
                    clazzMap.put(onceValidRegion.value().order(), clazz);//将采用的策略放入MAP
                }
            }
        }
        try {
            //我们采用动态代理处理策略重叠的问题，相信看过LZ的代理模式的同学应该都对代理模式的原理很熟悉了，那么下面出现的代理类LZ将不再解释，留给各位自己琢磨。
            return CalPriceProxy.getProxy(clazzMap);
        } catch (Exception e) {
            throw new RuntimeException("策略获得失败");
        }
    }
    
    //处理注解，我们传入一个策略类，返回它的注解
    private Annotation handleAnnotation(Class<? extends CalPrice> clazz){
        Annotation[] annotations = clazz.getDeclaredAnnotations();
        if (annotations == null || annotations.length == 0) {
            return null;
        }
        for (int i = 0; i < annotations.length; i++) {
            //变化点：这里稍微改动了下,如果是TotalValidRegion,OnceValidRegion这两种注解则返回
            if (annotations[i] instanceof TotalValidRegion || annotations[i] instanceof OnceValidRegion) {
                return annotations[i];
            }
        }
        return null;
    }
    
    /*  以下不需要改变  */
    
    //单例，并且我们需要在工厂初始化的时候
    private CalPriceFactory(){
        init();
    }
    
    //在工厂初始化时要初始化策略列表
    private void init(){
        calPriceList = new ArrayList<Class<? extends CalPrice>>();
        File[] resources = getResources();//获取到包下所有的class文件
        Class<CalPrice> calPriceClazz = null;
        try {
            calPriceClazz = (Class<CalPrice>) classLoader.loadClass(CalPrice.class.getName());//使用相同的加载器加载策略接口
        } catch (ClassNotFoundException e1) {
            throw new RuntimeException("未找到策略接口");
        }
        for (int i = 0; i < resources.length; i++) {
            try {
                //载入包下的类
                Class<?> clazz = classLoader.loadClass(CAL_PRICE_PACKAGE + "."+resources[i].getName().replace(".class", ""));
                //判断是否是CalPrice的实现类并且不是CalPrice它本身，满足的话加入到策略列表
                if (CalPrice.class.isAssignableFrom(clazz) && clazz != calPriceClazz) {
                    calPriceList.add((Class<? extends CalPrice>) clazz);
                }
            } catch (ClassNotFoundException e) {
                e.printStackTrace();
            }
        }
    }
    //获取扫描的包下面所有的class文件
    private File[] getResources(){
        try {
            File file = new File(classLoader.getResource(CAL_PRICE_PACKAGE.replace(".", "/")).toURI());
            return file.listFiles(new FileFilter() {
                public boolean accept(File pathname) {
                    if (pathname.getName().endsWith(".class")) {//我们只扫描class文件
                        return true;
                    }
                    return false;
                }
            });
        } catch (URISyntaxException e) {
            throw new RuntimeException("未找到策略资源");
        }
    }
    
    public static CalPriceFactory getInstance(){
        return CalPriceFactoryInstance.instance;
    }
    
    private static class CalPriceFactoryInstance{
        
        private static CalPriceFactory instance = new CalPriceFactory();
    }
}
```

```java
package com.calprice;

import java.lang.reflect.InvocationHandler;
import java.lang.reflect.Method;
import java.lang.reflect.Proxy;
import java.util.SortedMap;

public class CalPriceProxy implements InvocationHandler{

    private SortedMap<Integer, Class<? extends CalPrice>> clazzMap;
    
    private CalPriceProxy(SortedMap<Integer, Class<? extends CalPrice>> clazzMap) {
        super();
        this.clazzMap = clazzMap;
    }

    public Object invoke(Object proxy, Method method, Object[] args)
            throws Throwable {
        Double result = 0D;
        if (method.getName().equals("calPrice")) {
            for (Class<? extends CalPrice> clazz : clazzMap.values()) {
                if (result == 0) {
                    result = (Double) method.invoke(clazz.newInstance(), args);
                }else {
                    result = (Double) method.invoke(clazz.newInstance(), result);
                }
            }
            return result;
        }
        return null;
    }
    
    public static CalPrice getProxy(SortedMap<Integer, Class<? extends CalPrice>> clazzMap){
        return (CalPrice) Proxy.newProxyInstance(CalPriceProxy.class.getClassLoader(), new Class<?>[]{CalPrice.class}, new CalPriceProxy(clazzMap));
    }

}
```

```java
package com.calprice;
//我们使用嵌套注解，并且制定我们打折的各个策略顺序是99，这算是很靠后的
//因为我们最后打折算出来钱是最多的，这个一算就很清楚，LZ不再解释数学问题
@TotalValidRegion(@ValidRegion(max=1000,order=99))
class Common implements CalPrice{

    public Double calPrice(Double originalPrice) {
        return originalPrice;
    }

}
@TotalValidRegion(@ValidRegion(min=1000,max=2000,order=99))
class Vip implements CalPrice{

    public Double calPrice(Double originalPrice) {
        return originalPrice * 0.8;
    }

}
@TotalValidRegion(@ValidRegion(min=2000,max=3000,order=99))
class SuperVip implements CalPrice{

    public Double calPrice(Double originalPrice) {
        return originalPrice * 0.7;
    }

}
@TotalValidRegion(@ValidRegion(min=3000,order=99))
class GoldVip implements CalPrice{

    public Double calPrice(Double originalPrice) {
        return originalPrice * 0.5;
    }

}
@OnceValidRegion(@ValidRegion(min=1000,max=2000,order=40))
class OneTDTwoH implements CalPrice{
    
    public Double calPrice(Double originalPrice) {
        return originalPrice - 200;
    }
    
}

@OnceValidRegion(@ValidRegion(min=2000,order=40))
class TwotDFourH implements CalPrice{
    
    public Double calPrice(Double originalPrice) {
        return originalPrice - 400;
    }
    
}
```

```java
package com.calprice;

//客户端调用
public class Client {

    public static void main(String[] args) {
        Customer customer = new Customer();
        customer.buy(500D);
        System.out.println("客户需要付钱：" + customer.calLastAmount());
        customer.buy(1200D);
        System.out.println("客户需要付钱：" + customer.calLastAmount());
        customer.buy(1200D);
        System.out.println("客户需要付钱：" + customer.calLastAmount());
        customer.buy(1200D);
        System.out.println("客户需要付钱：" + customer.calLastAmount());
        customer.buy(2600D);
        System.out.println("客户需要付钱：" + customer.calLastAmount());
    }
    
}
```

最后总结一下策略模式的使用场景，就是有一系列的可相互替换的算法的时候，我们就可以使用策略模式将这些算法做成接口的实现，并让我们依赖于算法的类依赖于抽象的算法接口，这样可以彻底消除类与具体算法之间的耦合。



## 简单工厂 

```java
Chart chart = ChartFactory.getChart(type); 
```

根据传入参数返回对应的对象， 简单工厂模式存在的问题是当系统引入新产品时， 必定需要修改工厂类的源代码，将违背“开闭原则”；并且工厂类会包含大量的if else代码。

适用场景是：1.工厂类负责创建的对象比较少，不会导致工厂方法中的业务逻辑太多复杂

2.客户端只用知道传入工厂类的参数，对于如何创建对象并不关心

## 工厂方法模式

```java
    //日志记录器接口：抽象产品
    interface Logger {
        public void writeLog();
    }

    //数据库日志记录器：具体产品
    class DatabaseLogger implements Logger {
        public void writeLog() {
            System.out.println("数据库日志记录。");
        }
    }

    //文件日志记录器：具体产品
    class FileLogger implements Logger {
        public void writeLog() {
            System.out.println("文件日志记录。");
        }
    }

    //日志记录器工厂接口：抽象工厂
    interface LoggerFactory {
        public Logger createLogger();
    }

    //数据库日志记录器工厂类：具体工厂
    class DatabaseLoggerFactory implements LoggerFactory {
        public Logger createLogger() {
                //连接数据库，代码省略
                //创建数据库日志记录器对象
                Logger logger = new DatabaseLogger();
                //初始化数据库日志记录器，代码省略
                return logger;
        }
    }

    //文件日志记录器工厂类：具体工厂
    class FileLoggerFactory implements LoggerFactory {
        public Logger createLogger() {
                //创建文件日志记录器对象
                Logger logger = new FileLogger();
                //创建文件，代码省略
                return logger;
        }
    }
```

```java
    class Client {
        public static void main(String args[]) {
            LoggerFactory factory;
            Logger logger;
            factory = new FileLoggerFactory(); //可引入配置文件实现
            logger = factory.createLogger();
            logger.writeLog();
        }
    }
```

```java
    <!— config.xml -->
    <?xml version="1.0"?>
    <config>
        <className>FileLoggerFactory</className>
    </config>
```

```java
    //工具类XMLUtil.java
    import javax.xml.parsers.*;
    import org.w3c.dom.*;
    import org.xml.sax.SAXException;
    import java.io.*;

    public class XMLUtil {
    //该方法用于从XML配置文件中提取具体类类名，并返回一个实例对象
        public static Object getBean() {
            try {
                //创建DOM文档对象
                DocumentBuilderFactory dFactory = DocumentBuilderFactory.newInstance();
                DocumentBuilder builder = dFactory.newDocumentBuilder();
                Document doc;                           
                doc = builder.parse(new File("config.xml"));

                //获取包含类名的文本节点
                NodeList nl = doc.getElementsByTagName("className");
                Node classNode=nl.item(0).getFirstChild();
                String cName=classNode.getNodeValue();

                //通过类名生成实例对象并将其返回
                Class c=Class.forName(cName);
                Object obj=c.newInstance();
                return obj;
            }   
            catch(Exception e) {
                e.printStackTrace();
                return null;
             }
        }
    }
```

```java
    class Client {
        public static void main(String args[]) {
            LoggerFactory factory;
            Logger logger;
            factory = (LoggerFactory)XMLUtil.getBean(); //getBean()的返回类型为Object，需要进行强制类型转换
            logger = factory.createLogger();
            logger.writeLog();
        }
    }
```

优点：使用工厂方法模式的另一个优点是在系统中加入新产品时，无须修改抽象工厂和抽象产品提供的接口，无须修改客户端，也无须修改其他的具体工厂和具体产品，而只要添加一个具体工厂和具体产品就可以了，这样，系统的可扩展性也就变得非常好，完全符合“开闭原则”。

缺点：在添加新产品时，需要编写新的具体产品类，而且还得提供与之对应的具体工厂类，类的个数将成对增加。



