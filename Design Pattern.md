# Design Pattern



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

