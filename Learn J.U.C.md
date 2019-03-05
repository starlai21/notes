# Learn J.U.C 

## [1. CAS Compare And Swap](http://cmsblogs.com/?p=2235)

## CAS 分析

在CAS中有三个参数：内存值V、旧的预期值A、要更新的值B，当且仅当内存值V的值等于旧的预期值A时才会将内存值V的值修改为B，否则什么都不干。其伪代码如下：

```java
if(this.value == A){
    this.value = B
    return true;
}else{
    return false;
}
```

JUC下的atomic类都是通过CAS来实现的，下面就以AtomicInteger为例来阐述CAS的实现。如下：

```java
    private static final Unsafe unsafe = Unsafe.getUnsafe();
    private static final long valueOffset;

    static {
        try {
            valueOffset = unsafe.objectFieldOffset
                (AtomicInteger.class.getDeclaredField("value"));
        } catch (Exception ex) { throw new Error(ex); }
    }

    private volatile int value;
```

Unsafe是CAS的核心类，Java无法直接访问底层操作系统，而是通过本地（native）方法来访问。不过尽管如此，JVM还是开了一个后门：Unsafe，它提供了硬件级别的原子操作。

valueOffset为变量值在内存中的偏移地址，unsafe就是通过偏移地址来得到数据的原值的。

value当前值，使用volatile修饰，保证多线程环境下看见的是同一个。

我们就以AtomicInteger的addAndGet()方法来做说明，先看源代码：

```java
    public final int addAndGet(int delta) {
        return unsafe.getAndAddInt(this, valueOffset, delta) + delta;
    }

    public final int getAndAddInt(Object var1, long var2, int var4) {
        int var5;
        do {
            var5 = this.getIntVolatile(var1, var2);
        } while(!this.compareAndSwapInt(var1, var2, var5, var5 + var4));

        return var5;
    }
```

内部调用unsafe的getAndAddInt方法，在getAndAddInt方法中主要是看compareAndSwapInt方法：

```java
    public final native boolean compareAndSwapInt(Object var1, long var2, int var4, int var5);
```

该方法为本地方法，有四个参数，分别代表：对象、对象的地址、预期值、修改值。

CAS可以保证一次的读-改-写操作是原子操作，在单处理器上该操作容易实现，但是在多处理器上实现就有点儿复杂了。

CPU提供了两种方法来实现多处理器的原子操作：总线加锁或者缓存加锁。

**总线加锁**：总线加锁就是就是使用处理器提供的一个LOCK#信号，当一个处理器在总线上输出此信号时，其他处理器的请求将被阻塞住,那么该处理器可以独占使用共享内存。具体方法是，一旦遇到了Lock指令，就由仲裁器选择一个核心独占总线。其余的CPU核心不能再通过总线与内存通讯。从而达到“原子性”的目的。具体做法是，某一个核心触发总线的“Lock#”那根线，让总线仲裁器工作，把总线完全分给某个核心。但是这种处理方式显得有点儿霸道，不厚道，他把CPU和内存之间的通信锁住了，在锁定期间，其他处理器都不能其他内存地址的数据，其开销有点儿大。所以就有了缓存加锁。

**缓存加锁**：若干个CPU核心通过ringbus连到一起。每个核心都维护自己的Cache的状态。如果对于同一份内存数据在多个核里都有cache，则状态都为S（shared）。一旦有一核心改了这个数据（状态变成了M），其他核心就能瞬间通过ringbus感知到这个修改，从而把自己的cache状态变成I（Invalid），并且从标记为M的cache中读过来。同时，这个数据会被原子的写回到主存。最终，cache的状态又会变为S。

### CAS 缺陷

#### >1. 循环时间太长

如果CAS一直不成功呢？这种情况绝对有可能发生，如果自旋CAS长时间地不成功，则会给CPU带来非常大的开销。在JUC中有些地方就限制了CAS自旋的次数，例如BlockingQueue的SynchronousQueue。

#### **>2. 只能保证一个共享变量原子操作**

看了CAS的实现就知道这只能针对一个共享变量，如果是多个共享变量就只能使用锁了，当然如果你有办法把多个变量整成一个变量，利用CAS也不错。例如读写锁中state的高地位

#### >3. ABA 问题

CAS需要检查操作值有没有发生改变，如果没有发生改变则更新。但是存在这样一种情况：如果一个值原来是A，变成了B，然后又变成了A，那么在CAS检查的时候会发现没有改变，但是实质上它已经发生了改变，这就是所谓的ABA问题。对于ABA问题其解决方案是加上版本号，即在每个变量都加上一个版本号，每次改变时加1，即A —> B —> A，变成1A —> 2B —> 3A。

CAS的ABA隐患问题，解决方案则是版本号，Java提供了`AtomicStampedReference`来解决。`AtomicStampedReference`通过包装[E,Integer]的元组来对对象标记版本戳stamp，从而避免ABA问题。



```java
public class Test {
    private static AtomicInteger atomicInteger = new AtomicInteger(100);
    private static AtomicStampedReference atomicStampedReference = new AtomicStampedReference(100,1);

    public static void main(String[] args) throws InterruptedException {

        //AtomicInteger
        Thread at1 = new Thread(new Runnable() {
            @Override
            public void run() {
                atomicInteger.compareAndSet(100,110);
                atomicInteger.compareAndSet(110,100);
            }
        });

        Thread at2 = new Thread(new Runnable() {
            @Override
            public void run() {
                try {
                    TimeUnit.SECONDS.sleep(2);      // at1,执行完
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
                System.out.println("AtomicInteger:" + atomicInteger.compareAndSet(100,120));
            }
        });

        at1.start();
        at2.start();

        at1.join();
        at2.join();

        //AtomicStampedReference

        Thread tsf1 = new Thread(new Runnable() {
            @Override
            public void run() {
                try {
                    //让 tsf2先获取stamp，导致预期时间戳不一致
                    TimeUnit.SECONDS.sleep(2);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
                // 预期引用：100，更新后的引用：110，预期标识getStamp() 更新后的标识getStamp() + 1
                atomicStampedReference.compareAndSet(100,110,atomicStampedReference.getStamp(),atomicStampedReference.getStamp() + 1);
                atomicStampedReference.compareAndSet(110,100,atomicStampedReference.getStamp(),atomicStampedReference.getStamp() + 1);
            }
        });

        Thread tsf2 = new Thread(new Runnable() {
            @Override
            public void run() {
                int stamp = atomicStampedReference.getStamp();

                try {
                    TimeUnit.SECONDS.sleep(2);      //线程tsf1执行完
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
                System.out.println("AtomicStampedReference:" +atomicStampedReference.compareAndSet(100,120,stamp,stamp + 1));
            }
        });

        tsf1.start();
        tsf2.start();
    }

}
```

运行结果：

`AtomicInteger:true`

`AtomicStampedReference:false`



## [2. ReentrantLock 实现原理](https://crossoverjie.top/2018/01/25/ReentrantLock/)

使用 `synchronize` 来做同步处理时，锁的获取和释放都是隐式的，实现的原理是通过编译后加上不同的机器指令来实现。

而 `ReentrantLock` 就是一个普通的类，它是基于 `AQS(AbstractQueuedSynchronizer)`来实现的。

是一个**重入锁**：一个线程获得了锁之后仍然可以**反复**的加锁，不会出现自己阻塞自己的情况。

`AQS` 是 `Java` 并发包里实现锁、同步的一个重要的基础框架。

### 锁类型

ReentrantLock 分为**公平锁**和**非公平锁**，可以通过构造方法来指定具体类型：

```java
//默认非公平锁
public ReentrantLock() {
    sync = new NonfairSync();
}

//公平锁
public ReentrantLock(boolean fair) {
    sync = fair ? new FairSync() : new NonfairSync();
}
```

默认一般使用**非公平锁**，它的效率和吞吐量都比公平锁高的多(后面会分析具体原因)。

### 获取锁

```java
private ReentrantLock lock = new ReentrantLock();
public void run() {
    lock.lock();
    try {
        //do bussiness
    } catch (InterruptedException e) {
        e.printStackTrace();
    } finally {
        lock.unlock();
    }
}
```

### 公平锁获取锁

```java
public void lock() {
    sync.lock();
}
```

可以看到是使用 `sync`的方法，而这个方法是一个抽象方法，具体是由其子类(`FairSync`)来实现的，以下是公平锁的实现:

```java
   final void lock() {
       acquire(1);
   }
   
   //AbstractQueuedSynchronizer 中的 acquire()
   public final void acquire(int arg) {
   if (!tryAcquire(arg) &&
       acquireQueued(addWaiter(Node.EXCLUSIVE), arg))
       selfInterrupt();
}
```

第一步是尝试获取锁(`tryAcquire(arg)`),这个也是由其子类实现：

```java
    protected final boolean tryAcquire(int acquires) {
        final Thread current = Thread.currentThread();
        int c = getState();
        if (c == 0) {
            if (!hasQueuedPredecessors() &&
                compareAndSetState(0, acquires)) {
                setExclusiveOwnerThread(current);
                return true;
            }
        }
        else if (current == getExclusiveOwnerThread()) {
            int nextc = c + acquires;
            if (nextc < 0)
                throw new Error("Maximum lock count exceeded");
            setState(nextc);
            return true;
        }
        return false;
    }
}
```

首先会判断 `AQS` 中的 `state` 是否等于 0，0 表示目前没有其他线程获得锁，当前线程就可以尝试获取锁。

**注意**:尝试之前会利用 `hasQueuedPredecessors()` 方法来判断 AQS 的队列中中是否有其他线程，如果有则不会尝试获取锁(**这是公平锁特有的情况**)。

如果队列中没有线程就利用 CAS 来将 AQS 中的 state 修改为1，也就是获取锁，获取成功则将当前线程置为获得锁的独占线程(`setExclusiveOwnerThread(current)`)。

如果 `state` 大于 0 时，说明锁已经被获取了，则需要判断获取锁的线程是否为当前线程(`ReentrantLock` 支持重入)，是则需要将 `state + 1`，并将值更新。

#### 写入队列

如果 `tryAcquire(arg)` 获取锁失败，则需要用 `addWaiter(Node.EXCLUSIVE)` 将当前线程写入队列中。

写入之前需要将当前线程包装为一个 `Node` 对象(`addWaiter(Node.EXCLUSIVE)`)。

> AQS 中的队列是由 Node 节点组成的双向链表实现的。

包装代码:

```java
private Node addWaiter(Node mode) {
    Node node = new Node(Thread.currentThread(), mode);
    // Try the fast path of enq; backup to full enq on failure
    Node pred = tail;
    if (pred != null) {
        node.prev = pred;
        if (compareAndSetTail(pred, node)) {
            pred.next = node;
            return node;
        }
    }
    enq(node);
    return node;
}
```

首先判断队列是否为空，不为空时则将封装好的 `Node` 利用 `CAS` 写入队尾，如果出现并发写入失败就需要调用 `enq(node);` 来写入了。

```java
private Node enq(final Node node) {
    for (;;) {
        Node t = tail;
        if (t == null) { // Must initialize
            if (compareAndSetHead(new Node()))
                tail = head;
        } else {
            node.prev = t;
            if (compareAndSetTail(t, node)) {
                t.next = node;
                return t;
            }
        }
    }
}
```

这个处理逻辑就相当于`自旋`加上 `CAS` 保证一定能写入队列。

#### 挂起等待线程

写入队列之后需要将当前线程挂起(利用`acquireQueued(addWaiter(Node.EXCLUSIVE), arg)`)：

```java
final boolean acquireQueued(final Node node, int arg) {
    boolean failed = true;
    try {
        boolean interrupted = false;
        for (;;) {
            final Node p = node.predecessor();
            if (p == head && tryAcquire(arg)) {
                setHead(node);
                p.next = null; // help GC
                failed = false;
                return interrupted;
            }
            if (shouldParkAfterFailedAcquire(p, node) &&
                parkAndCheckInterrupt())
                interrupted = true;
        }
    } finally {
        if (failed)
            cancelAcquire(node);
    }
}
```

首先会根据 `node.predecessor()` 获取到上一个节点是否为头节点，如果是则尝试获取一次锁，获取成功就万事大吉了。

如果不是头节点，或者获取锁失败，则会根据上一个节点的 `waitStatus` 状态来处理(`shouldParkAfterFailedAcquire(p, node)`)。

`waitStatus` 用于记录当前节点的状态，如节点取消、节点等待等。

`shouldParkAfterFailedAcquire(p, node)` 返回当前线程是否需要挂起，如果需要则调用 `parkAndCheckInterrupt()`：

```java
private final boolean parkAndCheckInterrupt() {
    LockSupport.park(this);
    return Thread.interrupted();
}
```

他是利用 `LockSupport` 的 `part` 方法来挂起当前线程的，直到被唤醒。

### 非公平锁获取锁

公平锁与非公平锁的差异主要在获取锁：

公平锁就相当于买票，后来的人需要排到队尾依次买票，**不能插队**。

而非公平锁则没有这些规则，是**抢占模式**，每来一个人不会去管队列如何，直接尝试获取锁。

非公平锁:

```java
final void lock() {
    //直接尝试获取锁
    if (compareAndSetState(0, 1))
        setExclusiveOwnerThread(Thread.currentThread());
    else
        acquire(1);
}
```

公平锁:

```java
final void lock() {
    acquire(1);
}
```

还要一个重要的区别是在尝试获取锁时`tryAcquire(arg)`，非公平锁是不需要判断队列中是否还有其他线程，也是直接尝试获取锁：

```java
final boolean nonfairTryAcquire(int acquires) {
    final Thread current = Thread.currentThread();
    int c = getState();
    if (c == 0) {
        //没有 !hasQueuedPredecessors() 判断
        if (compareAndSetState(0, acquires)) {
            setExclusiveOwnerThread(current);
            return true;
        }
    }
    else if (current == getExclusiveOwnerThread()) {
        int nextc = c + acquires;
        if (nextc < 0) // overflow
            throw new Error("Maximum lock count exceeded");
        setState(nextc);
        return true;
    }
    return false;
}
```

### 释放锁

公平锁和非公平锁的释放流程都是一样的：

```java
public void unlock() {
    sync.release(1);
}

public final boolean release(int arg) {
    if (tryRelease(arg)) {
        Node h = head;
        if (h != null && h.waitStatus != 0)
        	   //唤醒被挂起的线程
            unparkSuccessor(h);
        return true;
    }
    return false;
}

//尝试释放锁
protected final boolean tryRelease(int releases) {
    int c = getState() - releases;
    if (Thread.currentThread() != getExclusiveOwnerThread())
        throw new IllegalMonitorStateException();
    boolean free = false;
    if (c == 0) {
        free = true;
        setExclusiveOwnerThread(null);
    }
    setState(c);
    return free;
}
```

首先会判断当前线程是否为获得锁的线程，由于是重入锁所以需要将 `state` 减到 0 才认为完全释放锁。

释放之后需要调用 `unparkSuccessor(h)` 来唤醒被挂起的线程。

### 总结

由于公平锁需要关心队列的情况，得按照队列里的先后顺序来获取锁(会造成大量的线程上下文切换)，而非公平锁则没有这个限制。

所以也就能解释非公平锁的效率会被公平锁更高。



## 3. [Volatile](https://crossoverjie.top/2018/03/09/volatile/)

### 内存可见性

由于 `Java` 内存模型(`JMM`)规定，所有的变量都存放在主内存中，而每个线程都有着自己的工作内存(高速缓存)。

线程在工作时，需要将主内存中的数据拷贝到工作内存中。这样对数据的任何操作都是基于工作内存(效率提高)，并且不能直接操作主内存以及其他线程工作内存中的数据，之后再将更新之后的数据刷新到主内存中。

> 这里所提到的主内存可以简单认为是**堆内存**，而工作内存则可以认为是**栈内存**。

如下图所示：

[![img](https://ws2.sinaimg.cn/large/006tKfTcly1fmouu3fpokj31ae0osjt1.jpg)](https://ws2.sinaimg.cn/large/006tKfTcly1fmouu3fpokj31ae0osjt1.jpg)

所以在并发运行时可能会出现线程 B 所读取到的数据是线程 A 更新之前的数据。

显然这肯定是会出问题的，因此 `volatile` 的作用出现了：

> 当一个变量被 `volatile` 修饰时，任何线程对它的写操作都会立即刷新到主内存中，并且会强制让缓存了该变量的线程中的数据清空，必须从主内存重新读取最新数据。





*volatile 修饰之后并不是让线程直接从主内存中获取数据，依然需要将变量拷贝到工作内存中*。

### 内存可见性的应用

当我们需要在两个线程间依据主内存通信时，通信的那个变量就必须的用 `volatile` 来修饰：

```Java
public class Volatile implements Runnable{

    private static volatile boolean flag = true ;

    @Override
    public void run() {
        while (flag){
        }
        System.out.println(Thread.currentThread().getName() +"执行完毕");
    }

    public static void main(String[] args) throws InterruptedException {
        Volatile aVolatile = new Volatile();
        new Thread(aVolatile,"thread A").start();


        System.out.println("main 线程正在运行") ;

        Scanner sc = new Scanner(System.in);
        while(sc.hasNext()){
            String value = sc.next();
            if(value.equals("1")){

                new Thread(new Runnable() {
                    @Override
                    public void run() {
                        aVolatile.stopThread();
                    }
                }).start();

                break ;
            }
        }

        System.out.println("主线程退出了！");

    }

    private void stopThread(){
        flag = false ;
    }

}
```

主线程在修改了标志位使得线程 A 立即停止，如果没有用 `volatile` 修饰，就有可能出现延迟。

但这里有个误区，这样的使用方式容易给人的感觉是：

> 对 `volatile` 修饰的变量进行并发操作是线程安全的。

这里要重点强调，`volatile` 并**不能**保证线程安全性！

如下程序:

```java
public class VolatileInc implements Runnable{

    private static volatile int count = 0 ; //使用 volatile 修饰基本数据内存不能保证原子性

    //private static AtomicInteger count = new AtomicInteger() ;

    @Override
    public void run() {
        for (int i=0;i<10000 ;i++){
            count ++ ;
            //count.incrementAndGet() ;
        }
    }

    public static void main(String[] args) throws InterruptedException {
        VolatileInc volatileInc = new VolatileInc() ;
        Thread t1 = new Thread(volatileInc,"t1") ;
        Thread t2 = new Thread(volatileInc,"t2") ;
        t1.start();
        //t1.join();

        t2.start();
        //t2.join();
        for (int i=0;i<10000 ;i++){
            count ++ ;
            //count.incrementAndGet();
        }


        System.out.println("最终Count="+count);
    }
}
```

当我们三个线程(t1,t2,main)同时对一个 `int` 进行累加时会发现最终的值都会小于 30000。

> 这是因为虽然 `volatile` 保证了内存可见性，每个线程拿到的值都是最新值，但 `count ++` 这个操作并不是原子的，这里面涉及到获取值、自增、赋值的操作并不能同时完成。

- 所以想到达到线程安全可以使这三个线程串行执行(其实就是单线程，没有发挥多线程的优势)。
- 也可以使用 `synchronize` 或者是锁的方式来保证原子性。
- 还可以用 `Atomic` 包中 `AtomicInteger` 来替换 `int`，它利用了 `CAS` 算法来保证了原子性。

### 指令重排

内存可见性只是 `volatile` 的其中一个语义，它还可以防止 `JVM` 进行指令重排优化。

举一个伪代码:

`int a=10 ;//1`

`int b=20 ;//2`

`int c= a+b ;//3`

一段特别简单的代码，理想情况下它的执行顺序是：`1>2>3`。但有可能经过 JVM 优化之后的执行顺序变为了 `2>1>3`。

可以发现不管 JVM 怎么优化，前提都是保证单线程中最终结果不变的情况下进行的。

可能这里还看不出有什么问题，那看下一段伪代码:

```java
private static Map<String,String> value ;
private static volatile boolean flag = fasle ;

//以下方法发生在线程 A 中 初始化 Map
public void initMap(){
	//耗时操作
	value = getMapValue() ;//1
	flag = true ;//2
}


//发生在线程 B中 等到 Map 初始化成功进行其他操作
public void doSomeThing(){
	while(!flag){
		sleep() ;
	}
	//dosomething
	doSomeThing(value);
}
```

这里就能看出问题了，当 `flag` 没有被 `volatile` 修饰时，`JVM` 对 1 和 2 进行重排，导致 `value` 都还没有被初始化就有可能被线程 B 使用了。

所以加上 `volatile` 之后可以防止这样的重排优化，保证业务的正确性。

### 指令重排的的应用

一个经典的使用场景就是双重懒加载的单例模式了:

```java
public class Singleton {

    private static volatile Singleton singleton;

    private Singleton() {
    }

    public static Singleton getInstance() {
        if (singleton == null) {
            synchronized (Singleton.class) {
                if (singleton == null) {
                    //防止指令重排
                    singleton = new Singleton();
                }
            }
        }
        return singleton;
    }
}
```

这里的 `volatile` 关键字主要是为了防止指令重排。

如果不用 ，`singleton = new Singleton();`，这段代码其实是分为三步：

- 分配内存空间。(1)
- 初始化对象。(2)
- 将 `singleton` 对象指向分配的内存地址。(3)

加上 `volatile` 是为了让以上的三步操作顺序执行，反之有可能第二步在第三步之前被执行就有可能某个线程拿到的单例对象是还没有初始化的，以致于报错。

### 总结

`volatile` 在 `Java` 并发中用的很多，比如像 `Atomic` 包中的 `value`、以及 `AbstractQueuedLongSynchronizer` 中的 `state` 都是被定义为 `volatile` 来用于保证内存可见性。

将这块理解透彻对我们编写并发程序时可以提供很大帮助。



## 4. 并发编程的简单分类

**第一种是利用JVM的内部机制。**

**第二种是利用JVM外部的机制，比如JDK或者一些类库。**

### JVM内部机制

#### static 的强制同步机制

```java
public class Static {
 
     private static String someField1 = someMethod1();
     
     private static String someField2;
     
     static {
         someField2 = someMethod2();
     }
     
}
```

上面的代码在编译之后变为

```java
public class Static {

    private static String someField1;
    
    private static String someField2;
    
    static {
        someField1 = someMethod1();
        someField2 = someMethod2();
    }
    
}
```

不过在JVM真正执行这段代码时变为 

```java
public class Static {

    private static String someField1;

    private static String someField2;

    private static volatile boolean isCinitMethodInvoked = false;

    static {
        synchronized (Static.class) {
            if (!isCinitMethodInvoked) {
                someField1 = someMethod1();
                someField2 = someMethod2();
                isCinitMethodInvoked = true;
            }
        }
    }

}
```

也就是说在实际执行一个类的静态初始化代码块时，虚拟机内部其实对其进行了同步，这就保证了无论多少个线程同时加载一个类，静态块中的代码执行且只执行一次

#### synchronized 同步机制

synchronized是JVM提供的同步机制，它可以修饰方法或者代码块。此外，在修饰代码块的时候，synchronized可以指定锁定的对象，比如常用的有this，类字面常量等。在使用synchronized的时候，通常情况下，我们会针对特定的属性进行锁定，有时也会专门建立一个加锁对象。

```java
public class Synchronized {

    private List<String> someFields;
    
    public void add(String someText) {
        //some code
        synchronized (someFields) {
            someFields.add(someText);
        }
        //some code
    }
    
    public Object[] getSomeFields() {
        //some code
        synchronized (someFields) {
            return someFields.toArray();
        }
    }
    
}
```

这种方式一般要优于使用this或者类字面常量进行锁定的方式，因为synchronized修饰的非静态成员方法默认是使用的this进行锁定，而synchronized修饰的静态成员方法默认是使用的类字面常量进行的锁定，因此如果直接在synchronized代码块中使用this或者类字面常量，可能会不经意的与synchronized方法产生互斥。通常情况下，使用属性进行加锁，能够更加有效的提高并发度，从而在保证程序正确的前提下尽可能的提高性能。

### JVM外部机制

#### ReentrantLock

ReentrantLock是JDK并发包中locks当中的一个类，专门用于弥补synchronized关键字的一些不足。接下来咱们就看一下synchronized关键字都有哪些不足，接着咱们再尝试使用ReentrantLock去解决这些问题。

**1）synchronized关键字同步的时候，等待的线程将无法控制，只能死等。**

解决方式：ReentrantLock可以使用tryLock(timeout, unit)方法去控制等待获得锁的时间，也可以使用无参数的tryLock方法立即返回，这就避免了死锁出现的可能性。

**2）synchronized关键字同步的时候，不保证公平性，因此会有线程插队的现象。**

解决方式：ReentrantLock可以使用构造方法ReentrantLock(fair)来强制使用公平模式，这样就可以保证线程获得锁的顺序是按照等待的顺序进行的，而synchronized进行同步的时候，是默认非公平模式的，但JVM可以很好的保证线程不被饿死

```java
public class Lock {

    private ReentrantLock nonfairLock = new ReentrantLock();

    private ReentrantLock fairLock = new ReentrantLock(true);

    private List<String> someFields;

    public void add(String someText) {
        // 等待获得锁，与synchronized类似
        nonfairLock.lock();
        try {
            someFields.add(someText);
        } finally {
            // finally中释放锁是无论如何都不能忘的
            nonfairLock.unlock();
        }
    }

    public void addTimeout(String someText) {
        // 尝试获取，如果10秒没有获取到则立即返回
        try {
            if (!fairLock.tryLock(10, TimeUnit.SECONDS)) {
                return;
            }
        } catch (InterruptedException e) {
            return;
        }
        try {
            someFields.add(someText);
        } finally {
            // finally中释放锁是无论如何都不能忘的
            fairLock.unlock();
        }
    }

}
```

### JVM内部条件等待机制

Java当中的类有一个共同的父类Object，而在Object中，有一个wait的本地方法，这是一个神奇的方法。

```Java
public class ObjectWait {

    private volatile static boolean lock;

    public static void main(String[] args) throws InterruptedException {
        final Object object = new Object();

        Thread thread1 = new Thread(new Runnable() {

            @Override
            public void run() {
                System.out.println("等待被通知！");
                try {
                    synchronized (object) {
                        while (!lock) {
                            object.wait();
                        }
                    }
                } catch (InterruptedException e) {
                    throw new RuntimeException(e);
                }
                System.out.println("已被通知");
            }
        });
        Thread thread2 = new Thread(new Runnable() {

            @Override
            public void run() {
                System.out.println("马上开始通知！");
                synchronized (object) {
                    object.notify();
                    lock = true;
                }
                System.out.println("已通知");
            }
        });
        thread1.start();
        thread2.start();
        Thread.sleep(100000);
    }
}
```

PS：await, wait 会释放锁， notify 不会

wait,notify和notifyAll方法在使用前，必须获取到当前对象的锁，否则会告诉你非法的监控状态异常。还有一点，则是如果有多个线程在wait等待，那么调用notify会随机通知其中一个线程，而不会按照顺序通知。换句话说，notify的通知机制是非公平的，notify并不保证先调用wait方法的线程优先被唤醒。notifyAll方法则不存在这个问题，它将通知所有处于wait等待的线程。

### JVM外部条件等待机制

上面咱们已经看过JVM自带的条件控制机制，是使用的本地方法wait实现的。那么在JDK的类库中，也有这样的一个类Condition，来弥补wait方法本身的不足。与之前一样，说到这里，咱们就来谈谈wait到底有哪些不足。

**1）wait方法当使用带参数的方法wait(timeout)或者wait(timeout,nanos)时，无法反馈究竟是被唤醒还是到达了等待时间，大部分时候，我们会使用循环（就像上面的例子一样）来检测是否达到了条件**

解决方式：Condition可以使用返回值标识是否达到了超时时间。

**2）由于wait,notify,notifyAll方法都需要获得当前对象的锁，因此当出现多个条件等待时，则需要依次获得多个对象的锁，这是非常恶心麻烦且繁琐的事情。**

解决方式：Condition之需要获得Lock的锁即可，一个Lock可以拥有多个条件。

```java
package concurrent;

import java.util.concurrent.locks.Condition;
import java.util.concurrent.locks.ReentrantLock;

/**
 * @author zuoxiaolong
 *
 */
public class ConditionTest {

    private static ReentrantLock lock = new ReentrantLock();
    
    public static void main(String[] args) throws InterruptedException {
        final Condition condition1 = lock.newCondition();
        final Condition condition2 = lock.newCondition();
        Thread thread1 = new Thread(new Runnable() {
            public void run() {
                lock.lock();
                try {
                    System.out.println("等待condition1被通知！");
                    condition1.await();
                    System.out.println("condition1已被通知，马上开始通知condition2！");
                    condition2.signal();
                    System.out.println("通知condition2完毕！");
                } catch (InterruptedException e) {
                    throw new RuntimeException(e);
                } finally {
                    lock.unlock();
                }
            }
        });
        Thread thread2 = new Thread(new Runnable() {
            public void run() {
                lock.lock();
                try {
                    System.out.println("马上开始通知condition1！");
                    condition1.signal();
                    System.out.println("通知condition1完毕，等待condition2被通知！");
                    condition2.await();
                    System.out.println("condition2已被通知！");
                } catch (InterruptedException e) {
                    throw new RuntimeException(e);
                } finally {
                    lock.unlock();
                }
            }
        });
        thread1.start();
        Thread.sleep(1000);
        thread2.start();
    }

}
```

可以看到，我们只需要获取lock一次就可以了，在内部咱们可以使用两个或多个条件而不再需要多次获得锁。这种方式会更加直观，大大增加程序的可读性。

### JVM外部机制  线程协作

#### CountDownLatch

这个类是为了帮助猿友们方便的实现一个这样的场景，就是某一个线程需要等待其它若干个线程完成某件事以后才能继续进行。比如下面的这个程序。

```java
public class CountDownLatchTest {

    public static void main(String[] args) throws InterruptedException {
        final CountDownLatch countDownLatch = new CountDownLatch(10);
        for (int i = 0; i < 10; i++) {
            final int number = i + 1;
            Runnable runnable = new Runnable() {
                public void run() {
                    try {
                        Thread.sleep(1000);
                    } catch (InterruptedException e) {}
                    System.out.println("执行任务[" + number + "]");
                    countDownLatch.countDown();
                    System.out.println("完成任务[" + number + "]");
                }
            };
            Thread thread = new Thread(runnable);
            thread.start();
        }
        System.out.println("主线程开始等待...");
        countDownLatch.await();
        System.out.println("主线程执行完毕...");
    }
    
}
```

这个程序的主线程会等待CountDownLatch进行10次countDown方法的调用才会继续执行。

#### CyclicBarrier

这个类是为了帮助猿友们方便的实现多个线程一起启动的场景，就像赛跑一样，只要大家都准备好了，那就开始一起冲。比如下面这个程序，所有的线程都准备好了，才会一起开始执行

```java
public class CyclicBarrierTest {

    public static void main(String[] args) {
        final CyclicBarrier cyclicBarrier = new CyclicBarrier(10);
        for (int i = 0; i < 10; i++) {
            final int number = i + 1;
            Runnable runnable = new Runnable() {
                public void run() {
                    try {
                        Thread.sleep(1000);
                    } catch (InterruptedException e) {}
                    System.out.println("等待执行任务[" + number + "]");
                    try {
                        cyclicBarrier.await();
                    } catch (InterruptedException e) {
                    } catch (BrokenBarrierException e) {
                    }
                    System.out.println("开始执行任务[" + number + "]");
                }
            };
            Thread thread = new Thread(runnable);
            thread.start();
        }
    }
    
}
```

#### Semephore

这个类是为了帮助猿友们方便的实现控制数量的场景，可以是线程数量或者任务数量等等。来看看下面这段简单的代码

```java
public class SemaphoreTest {

    public static void main(String[] args) throws InterruptedException {
        final Semaphore semaphore = new Semaphore(10);
        final AtomicInteger number = new AtomicInteger();
        for (int i = 0; i < 100; i++) {
            Runnable runnable = new Runnable() {
                public void run() {
                    try {
                        Thread.sleep(1000);
                    } catch (InterruptedException e) {}
                    try {
                        semaphore.acquire();
                        number.incrementAndGet();
                    } catch (InterruptedException e) {}
                }
            };
            Thread thread = new Thread(runnable);
            thread.start();
        }
        Thread.sleep(10000);
        System.out.println("共" + number.get() + "个线程获得到信号");
        System.exit(0);
    }
    
}
```









#### Exchanger

这个类是为了帮助猿友们方便的实现两个线程交换数据的场景，使用起来非常简单，看看下面这段代码。

```java
public class ExchangerTest {

    public static void main(String[] args) throws InterruptedException {
        final Exchanger<String> exchanger = new Exchanger<String>();
        Thread thread1 = new Thread(new Runnable() {
            public void run() {
                try {
                    System.out.println("线程1等待接受");
                    String content = exchanger.exchange("thread1");
                    System.out.println("线程1收到的为：" + content);
                } catch (InterruptedException e) {}
            }
        });
        Thread thread2 = new Thread(new Runnable() {
            public void run() {
                try {
                    System.out.println("线程2等待接受并沉睡3秒");
                    Thread.sleep(3000);
                    String content = exchanger.exchange("thread2");
                    System.out.println("线程2收到的为：" + content);
                } catch (InterruptedException e) {}
            }
        });
        thread1.start();
        thread2.start();
    }
    
}
```

两个线程在只有一个线程调用exchange方法的时候调用方会被挂起，当都调用完毕时，双方会交换数据。在任何一方没调用exchange之前，线程都会处于挂起状态。

