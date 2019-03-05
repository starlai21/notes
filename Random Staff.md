# Random Staff

## **FizzBuzzWhizz**

你是一名体育老师，在某次课距离下课还有五分钟时，你决定搞一个游戏。此时有100名学生在上课。游戏的规则是：

1. 你首先说出三个不同的特殊数，要求必须是个位数，比如3、5、7。
2. 让所有学生拍成一队，然后按顺序报数。
3. 学生报数时，如果所报数字是第一个特殊数（3）的倍数，那么不能说该数字，而要说Fizz；如果所报数字是第二个特殊数（5）的倍数，那么要说Buzz；如果所报数字是第三个特殊数（7）的倍数，那么要说Whizz。
4. 学生报数时，如果所报数字同时是两个特殊数的倍数情况下，也要特殊处理，比如第一个特殊数和第二个特殊数的倍数，那么不能说该数字，而是要说FizzBuzz, 以此类推。如果同时是三个特殊数的倍数，那么要说FizzBuzzWhizz。
5. 学生报数时，如果所报数字包含了第一个特殊数，那么也不能说该数字，而是要说相应的单词，比如本例中第一个特殊数是3，那么要报13的同学应该说Fizz。如果数字中包含了第一个特殊数，那么忽略规则3和规则4，比如要报35的同学只报Fizz，不报BuzzWhizz。

![](https://www.plantuml.com/plantuml/img/ZLAx3i8m3Dpp5HxBm0yWXWh4naE2WTbD0usKEYXnXH3mxwGlaOAew9QxyvrzQkeP7LUb4K8JAtT2gM23B0lbH8njgp9Jxe2t1XVH4-QFQJiIQpu5EpV6BYr9v375IXPsk4EtPSD6pABI9kyl-87NCrDOwt0Scf3DgCd_DREn-RkTOGqpEB3JT0QFjoGK1zIGa_UcCyYiDGe9T9isb4c3tdyrUHSGljwYxC9hh8ihyNAqBXTFqLlyk21oYlVcGj5USUKewHolmMvI-wMAyl1ll000)



@startuml

interface Matcher


interface NumberSayer



NumberSayer <|- MatchNumberSayer
NumberSayer <|- OrNumberSayer
NumberSayer <|- ConcatNumberSayer
NumberSayer <|- EchoNumberSayer


Matcher <|- NumberSayerBuildMatcher
NumberSayerBuildMatcher <|-- LiteralContainsMatcher
NumberSayerBuildMatcher <|-- ModMatcher




NumberSayer : String say(int number)

Matcher : boolean isMatch(int number)

class MatchNumberSayer{
    Matcher matcher
    String mapWord
}


class NumberSayerBuildMatcher{
    MatchNumberSayer thenReturn(String word)
}

@enduml

### ConcatNumberSayer

```java
public class ConcatNumberSayer implements NumberSayer {

    private List<NumberSayer> numberSayers;

    protected ConcatNumberSayer(List<NumberSayer> numberSayers) {
        this.numberSayers = numberSayers;
    }

    @Override
    public String say(int number) {
        StringBuilder accum = new StringBuilder();
        for (NumberSayer numberSayer : numberSayers) {
            String say = numberSayer.say(number);
            if (say != null) {
                accum.append(say);
            }
        }
        if (accum.length() > 0) {
            return accum.toString();
        } else {
            return null;
        }
    }
}
```

### EchoNumberSayer

```java
public class EchoNumberSayer implements NumberSayer {

    @Override
    public String say(int number) {
        return String.valueOf(number);
    }
}
```

### LiteralContainsMatcher

```java
public class LiteralContainsMatcher extends NumberSayerBuildMatcher {

    private int matchNumber;

    public LiteralContainsMatcher(int matchNumber) {
        this.matchNumber = matchNumber;
    }

    @Override
    public boolean isMatch(int number) {
        return String.valueOf(number).contains(String.valueOf(matchNumber));
    }
}
```

### Matcher

```java
public interface Matcher {

    public boolean isMatch(int number);

}
```

### MatchNumberSayer

```java
public class MatchNumberSayer implements NumberSayer {

    private Matcher matcher;

    private final String mapWord;

    protected MatchNumberSayer(Matcher matcher, String mapWord) {
        this.matcher = matcher;
        this.mapWord = mapWord;
    }

    public String getMapWord() {
        return mapWord;
    }

    @Override
    public String say(int number) {
        if (matcher.isMatch(number)) {
            return getMapWord();
        } else {
            return null;
        }
    }

}
```

### ModMatcher

```java
public class ModMatcher extends NumberSayerBuildMatcher {

    private int divisor;

    private int remainder;

    protected ModMatcher(int divisor, int remainder) {
        this.divisor = divisor;
        this.remainder = remainder;
    }

    @Override
    public boolean isMatch(int number) {
        return number % divisor == remainder;
    }

    public static class Mod{
        private int divisor;
        Mod(int divisor){
            this.divisor = divisor;
        }
        public NumberSayerBuildMatcher is(int remainder){
            return new ModMatcher(this.divisor,remainder);
        }
    }

}

```

### NumberSayer

```java
public interface NumberSayer {

    /**
     * Say a number
     * @param number
     * @return
     */
    public String say(int number);
}
```

### NumberSayerBuildMatcher

```java
public abstract class NumberSayerBuildMatcher implements Matcher {

    public MatchNumberSayer thenReturn(String word) {
        return new MatchNumberSayer(this, word);
    }
}
```

### NumberSayers

```java
public abstract class NumberSayers {

    public static ConcatNumberSayer concat(NumberSayer... numberSayerArray) {
        List<NumberSayer> numberSayerList = new ArrayList<NumberSayer>(numberSayerArray.length);
        for (NumberSayer numberSayer : numberSayerArray) {
            numberSayerList.add(numberSayer);
        }
        return new ConcatNumberSayer(numberSayerList);
    }

    public static OrNumberSayer or(NumberSayer... sayerArray) {
        List<NumberSayer> numberSayers = new ArrayList<NumberSayer>(sayerArray.length);
        for (NumberSayer numberSayer : sayerArray) {
            numberSayers.add(numberSayer);
        }
        return new OrNumberSayer(numberSayers);
    }

    public static ModMatcher.Mod mod(int divisor) {
        return new ModMatcher.Mod(divisor);
    }

    public static NumberSayerBuildMatcher contains(int matchNumber) {
        return new LiteralContainsMatcher(matchNumber);
    }

    public static NumberSayer echoInputNumber() {
        return new EchoNumberSayer();
    }

}
```

### OrNumberSayer

```java
public class OrNumberSayer implements NumberSayer {

    private List<NumberSayer> sayers;

    protected OrNumberSayer(List<NumberSayer> sayers) {
        this.sayers = sayers;
    }

    @Override
    public String say(int number) {
        for (NumberSayer sayer : sayers) {
            String say = sayer.say(number);
            if (say != null) {
                return say;
            }
        }
        return null;
    }

    public OrNumberSayer or(NumberSayer numberSayer){
        sayers.add(numberSayer);
        return this;
    }
}
```

### NumberSequenceSayer

```java
public class NumberSequenceSayer {

    private final NumberSayer numberSayer;

    private final int startNumber;

    private final int endNumber;

    private static String SEPARATOR = System.getProperty("line.separator");

    public NumberSequenceSayer(NumberSayer numberSayer, int startNumber, int endNumber) {
        this.numberSayer = numberSayer;
        this.startNumber = startNumber;
        this.endNumber = endNumber;
    }

    public String say() {
        StringBuilder accum = new StringBuilder();
        for (int i = startNumber; i <= endNumber; i++) {
            String say = numberSayer.say(i);
            if (say != null) {
                accum.append(say).append(SEPARATOR);
            }
        }
        return accum.toString();
    }
}
```

### NumberSequenceSayerBuilder

```java
public class NumberSequenceSayerBuilder {

    private NumberSayer numberSayer;

    private int startNumber;

    private int endNumber;

    private NumberSequenceSayerBuilder() {
    }

    public static NumberSequenceSayerBuilder custom(){
        return new NumberSequenceSayerBuilder();
    }

    public NumberSequenceSayerBuilder setNumberSayer(NumberSayer numberSayer) {
        this.numberSayer = numberSayer;
        return this;
    }

    public NumberSequenceSayerBuilder setStartNumber(int startNumber) {
        this.startNumber = startNumber;
        return this;
    }

    public NumberSequenceSayerBuilder setEndNumber(int endNumber) {
        this.endNumber = endNumber;
        return this;
    }

    public NumberSequenceSayer get() {
        return new NumberSequenceSayer(numberSayer, startNumber, endNumber);
    }
}
```

### NumberSequenceSayerTest

```java
public class NumberSequenceSayerTest {

    @Test
    public void testAll() throws Exception {
        NumberSequenceSayer numberSequenceSayer = NumberSequenceSayerBuilder.custom()
           .setNumberSayer(
               or(contains(3).thenReturn("Fizz"))
               .or(
                   concat(
                      mod(3).is(0).thenReturn("Fizz"),
                      mod(5).is(0).thenReturn("Buzz"),
                      mod(7).is(0).thenReturn("Whizz")
                   )
               )
               .or(echoInputNumber())
           )
           .setStartNumber(1).setEndNumber(100).get();
        System.out.println(numberSequenceSayer.say());
    }
}
```