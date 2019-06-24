# Flutter Guide

## Flutter 之 What

它是Google开发的用于全端(iOS、Android、Web)的混合开发框架

[Flutter: 适用于移动、Web、嵌入式和桌面平台的便携式界面框架](https://mp.weixin.qq.com/s/xVmilQeiveA8XZNU0g668Q)

[用 Flutter 在 Android 和 iOS 上构筑精彩](https://mp.weixin.qq.com/s/5KCxFBam0n3MWh0vZL_XEw)



## Why Dart

flutter使用 Dart 语言进行开发，为什么会选择 Dart 这门语言呢？[Why Flutter Uses Dart](https://hackernoon.com/why-flutter-uses-dart-dd635a054ebf)

以下是大致的翻译

早期的 Flutter 团队评估了十多种语言，并选择了 Dart，因为它符合他们构建用户界面的方式

以下是使 Dart 成为 Flutter 不可或缺的一部分的特性：

- Dart 是 AOT（Ahead Of Time）编译的，编译成快速、可预测的本地代码，使 Flutter 几乎都可以使用 Dart 编写。这不仅使 Flutter 变得更快，而且几乎所有的东西（包括所有的小部件）都可以定制。
- Dart 也可以 JIT（Just In Time）编译，开发周期异常快，工作流颠覆常规（包括 Flutter 流行的亚秒级有状态热重载）。
- Dart 可以更轻松地创建以 60fps 运行的流畅动画和转场。Dart 可以在没有锁的情况下进行对象分配和垃圾回收。就像 JavaScript 一样，Dart 避免了抢占式调度和共享内存（因而也不需要锁）。由于 Flutter 应用程序被编译为本地代码，因此它们不需要在领域之间建立缓慢的桥梁（例如，JavaScript 到本地代码）。它的启动速度也快得多。
- Dart 使 Flutter 不需要单独的声明式布局语言，如 JSX 或 XML，或单独的可视化界面构建器，因为 Dart 的声明式编程布局易于阅读和可视化。所有的布局使用一种语言，聚集在一处，Flutter 很容易提供高级工具，使布局更简单。
- 开发人员发现 Dart 特别容易学习，因为它具有静态和动态语言用户都熟悉的特性。

并非所有这些功能都是 Dart 独有的，但它们的组合却恰到好处，使 Dart 在实现 Flutter 方面独一无二。因此，没有 Dart，很难想象 Flutter 像现在这样强大。

本文接下来将深入探讨使 Dart 成为**实现 Flutter 的最佳语言**的许多特性（包括其标准库）。

### 编译和执行

[如果你已经了解静态语言与动态语言、AOT 与 JIT 编译以及虚拟机等主题，可以跳过本节。]

历史上，计算机语言分为两组：[静态语言](https://en.wikipedia.org/wiki/Compiled_language)（例如，Fortran 和 C，其中变量类型是在编译时静态指定的）和[动态语言](https://en.wikipedia.org/wiki/Interpreted_language)（例如，Smalltalk 和 JavaScript，其中变量的类型可以在运行时改变）。静态语言通常编译成目标机器的本地机器代码（或**汇编代码**）程序，该程序在运行时直接由硬件执行。动态语言由解释器执行，不产生机器语言代码。

当然，事情后来变得复杂得多。[虚拟机](https://en.wikipedia.org/wiki/Virtual_machine)（VM）的概念开始流行，它其实只是一个高级的解释器，用软件模拟硬件设备。虚拟机使语言移植到新的硬件平台更容易。因此，VM 的输入语言常常是[中间语言](https://en.wikipedia.org/wiki/Intermediate_representation#Intermediate_language)。例如，一种编程语言（如[Java](https://en.wikipedia.org/wiki/Java_(programming_language))）被编译成中间语言（[字节码](https://en.wikipedia.org/wiki/Java_bytecode)），然后在 VM（[JVM](https://en.wikipedia.org/wiki/Java_virtual_machine)）中执行。

另外，现在有[**即时**（JIT）编译器](https://en.wikipedia.org/wiki/Just-in-time_compilation)。JIT 编译器在程序执行期间运行，即时编译代码。原先在程序创建期间（运行时之前）执行的编译器现在称为[AOT 编译器](https://en.wikipedia.org/wiki/Ahead-of-time_compilation)。

一般来说，只有静态语言才适合 AOT 编译为本地机器代码，因为机器语言通常需要知道数据的类型，而动态语言中的类型事先并不确定。因此，动态语言通常被解释或 JIT 编译。

在开发过程中 AOT 编译，开发周期（从更改程序到能够执行程序以查看更改结果的时间）总是很慢。但是 AOT 编译产生的程序可以更可预测地执行，并且运行时不需要停下来分析和编译。AOT 编译的程序也更快地开始执行（因为它们已经被编译）。

相反，JIT 编译提供了更快的开发周期，但可能导致执行速度较慢或时快时慢。特别是，JIT 编译器启动较慢，因为当程序开始运行时，JIT 编译器必须在代码执行之前进行分析和编译。研究表明，[如果开始执行需要超过几秒钟，许多人将放弃应用](https://www.google.com/search?q=slow startup times lead to abandonment)。

以上就是背景知识。将 AOT 和 JIT 编译的优点结合起来不是很棒吗？请继续阅读。

### 编译与执行 Dart

在创造 Dart 之前，Dart 团队成员在高级编译器和虚拟机上做了开创性的工作，包括动态语言（如 JavaScript 的[V8 引擎](https://en.wikipedia.org/wiki/Chrome_V8)和 Smalltalk 的[Strongtalk](https://en.wikipedia.org/wiki/Strongtalk)）以及静态语言（如用于 Java 的[Hotspot 编译器](https://en.wikipedia.org/wiki/HotSpot)）。他们利用这些经验使 Dart 在编译和执行方面非常灵活。

Dart 是同时非常适合 AOT 编译和 JIT 编译的少数语言之一（也许是唯一的“主流”语言）。支持这两种编译方式为 Dart 和（特别是）Flutter 提供了显著的优势。

JIT 编译在开发过程中使用，编译器速度特别快。然后，当一个应用程序准备发布时，它被 AOT 编译。因此，借助先进的工具和编译器，Dart 具有两全其美的优势：极快的开发周期、快速的执行速度和极短启动时间。

Dart 在编译和执行方面的灵活性并不止于此。例如，Dart 可以[编译成 JavaScript](https://webdev.dartlang.org/tools/dart2js)，所以浏览器可以执行。这允许在移动应用和网络应用之间重复使用代码。开发人员报告他们的移动和网络应用程序之间的[代码重用率高达 70％](https://medium.com/@matthew.smith_66715/why-we-chose-flutter-and-how-its-changed-our-company-for-the-better-271ddd25da60)。通过将 Dart 编译为本地代码，或者编译为 JavaScript 并将其与[node.js](https://nodejs.org/en/)一起使用，Dart 也可以在服务器上使用。

最后，[Dart 还提供了一个独立的虚拟机](https://www.dartlang.org/dart-vm/tools/dart-vm)（本质上就像解释器一样），虚拟机使用 Dart 语言本身作为其中间语言。

Dart 可以进行高效的 AOT 编译或 JIT 编译、解释或转译成其他语言。Dart 编译和执行不仅非常灵活，而且速度**特别快**。

下一节将介绍 Dart 编译速度的颠覆性的例子。

### 有状态热重载

Flutter 最受欢迎的功能之一是其极速**热重载**。在开发过程中，Flutter 使用 JIT 编译器，通常可以在一秒之内重新加载并继续执行代码。只要有可能，应用程序状态在重新加载时保留下来，以便应用程序可以从停止的地方继续。

除非自己亲身体验过，否则很难理解在开发过程中快速（且可靠）的热重载的重要性。开发人员报告称，它改变了他们创建应用的方式，将其描述为[像将应用绘制成生活](https://github.com/zilongc/blog/issues/3)一样。

[以下是一位移动应用程序开发人员对 Flutter 热重载的评价](https://medium.com/@lets4r/the-fluture-is-now-6040d7dcd9f3)：

> 我想测试热重载，所以我改变了颜色，保存修改，结果……就喜欢上它了❤！
>
> 这个功能真的很棒。我曾认为 Visual Studio 中**编辑和继续**（Edit & Continue）很好用，但这简直**令人惊叹**。有了这个功能，我认为移动开发者的生产力可以提高两倍。
>
> 这对我来说真的是翻天覆地的变化。当我部署代码并花费很长时间时，我分心了，做了其他事情，当我回到模拟器 / 设备时，我就忘了想测试的内容。有什么比花 5 分钟将控件移动 2px 更令人沮丧？有了 Flutter，这不再存在。

Flutter 的热重载也使得尝试新想法或尝试替代方案变得更加容易，从而为创意提供了巨大的推动力。

到目前为止，我们讨论了 Dart 给开发人员带来的好处。下一节将介绍 Dart 如何使创建满足用户需求的顺畅的应用程序更加轻松。

### 避免卡顿

应用程序**速度快**很不错，但**流畅**则更加了不起。即使是一个超快的动画，如果它不稳定，也会看起来很糟糕。但是，防止[卡顿](https://afasterweb.com/2015/08/29/what-the-jank/)可能很困难，因为因素太多。Dart 有许多功能可以避免许多常见的导致卡顿的因素。

当然，像任何语言一样，Flutter 也可能写出来卡顿的应用程序；Dart 通过提高可预测性，帮助开发人员更好地控制应用程序的流畅性，从而更轻松地提供最佳的用户体验。

**以 60fps 运行，使用 Flutter 创建的用户界面的性能远远优于使用其他跨平台开发框架创建的用户界面**

不仅仅比跨平台的应用程序好，而且和最好的原生应用程序一样好：

> UI 像黄油一样顺滑……我从来没有见过这样流畅的 Android 应用程序。

### AOT 编译和“桥”

我们讨论过一个有助于保持顺畅的特性，那就是 Dart 能 AOT 编译为本地机器码。预编译的 AOT 代码比 JIT 更具可预测性，因为在运行时不需要暂停执行 JIT 分析或编译。

然而，AOT 编译代码还有一个更大的优势，那就是避免了“JavaScript 桥梁”。当动态语言（如 JavaScript）需要与平台上的本地代码互操作时，[它们必须通过桥进行通信](https://hackernoon.com/whats-revolutionary-about-flutter-946915b09514)，这会导致[上下文切换](https://medium.com/@talkol/performance-limitations-of-react-native-and-how-to-overcome-them-947630d7f440)，从而必须保存特别多的状态（可能会存储到辅助存储）。这些[上下文切换](https://en.wikipedia.org/wiki/Context_switch)具有双重打击，因为它们不仅会减慢速度，还会导致严重的卡顿。

[![img](https://static001.infoq.cn/resource/image/99/61/996d739dce634dfc091edef86433a461.png)](https://s3.amazonaws.com/infoq.content.live.0/articles/why-flutter-uses-dart/zh/resources/4022-1520961763674.png)

注意：即使编译后的代码也可能需要一个接口来与平台代码进行交互，并且这也可以称为桥，但它通常比动态语言所需的桥快几个数量级。另外，由于 Dart 允许将小部件等内容移至应用程序中，因此减少了桥接的需求。

### 抢占式调度、时间分片和共享资源

大多数支持多个并发执行线程的计算机语言（包括 Java、Kotlin、Objective-C 和 Swift）都使用[抢占式](https://en.wikipedia.org/wiki/Preemption_(computing))来切换线程。每个线程都被分配一个时间分片来执行，如果超过了分配的时间，线程将被上下文切换抢占。但是，如果在线程间共享的资源（如内存）正在更新时发生抢占，则会导致[竞态条件](https://en.wikipedia.org/wiki/Race_condition)。

竞态条件具有双重不利，因为它可能会导致严重的错误，包括应用程序崩溃并导致数据丢失，而且由于它取决于[独立线程的时序](https://en.wikipedia.org/wiki/Race_condition#Software)，所以它特别难以找到并修复。在调试器中运行应用程序时，竞态条件常常消失不见。

解决竞态条件的典型方法是使用[锁](https://en.wikipedia.org/wiki/Lock_(computer_science))来保护共享资源，阻止其他线程执行，但锁本身可能导致卡顿，甚至[更严重的问题](https://en.wikipedia.org/wiki/Dining_philosophers_problem)（包括[死锁](https://en.wikipedia.org/wiki/Deadlock)和[饥饿](https://en.wikipedia.org/wiki/Starvation_(computer_science))）。

Dart 采取了不同的方法来解决这个问题。Dart 中的线程称为 isolate，不共享内存，从而避免了大多数锁。isolate 通过在通道上传递消息来通信，这与[Erlang](https://www.erlang.org/)中的 actor 或 JavaScript 中的 Web Worker 相似。

Dart 与 JavaScript 一样，是[单线程](https://en.wikipedia.org/wiki/Thread_(computing)#Single_threading)的，这意味着它根本不允许抢占。相反，线程显式让出（使用[async/await、Future](https://www.dartlang.org/tutorials/language/futures)和[Stream](https://www.dartlang.org/tutorials/language/streams)）CPU。这使开发人员能够更好地控制执行。单线程有助于开发人员确保关键功能（包括动画和转场）完成而无需抢占。这通常不仅是用户界面的一大优势，而且还是客户端——服务器代码的一大优势。

当然，如果开发人员忘记了让出 CPU 的控制权，这可能会延迟其他代码的执行。然而我们发现，忘记让出 CPU 通常比忘记加锁更容易找到和修复（因为竞态条件很难找到）。

### 对象分配和垃圾回收

另一个严重导致卡顿的原因是垃圾回收。事实上，这只是访问共享资源（内存）的一种特殊情况，在很多语言中都需要使用锁。但在回收可用内存时，[锁会阻止整个应用程序运行](https://en.wikipedia.org/wiki/Tracing_garbage_collection#Stop-the-world_vs._incremental_vs._concurrent)。但是，Dart 几乎可以在没有锁的情况下执行垃圾回收。

Dart 使用先进的[分代垃圾回收和对象分配方案](https://en.wikipedia.org/wiki/Tracing_garbage_collection#Generational_GC_.28ephemeral_GC.29)，该方案对于分配许多短暂的对象（对于 Flutter 这样的反应式用户界面来说非常完美，Flutter 为每帧重建不可变视图树）都特别快速。Dart 可以用一个指针凹凸分配一个对象（不需要锁）。这也会带来流畅的滚动和动画效果，而不会出现卡顿。

### 统一的布局

Dart 的另一个好处是，Flutter 不会从程序中拆分出额外的模板或布局语言，如 JSX 或 XML，也不需要单独的可视布局工具。以下是一个简单的 Flutter 视图，用 Dart 编写： 

```dart
new Center(child:
  new Column(children: [
    new Text('Hello, World!'),
    new Icon(Icons.star, color: Colors.green),
  ])
)
```

[![img](https://static001.infoq.cn/resource/image/9a/da/9a46c4db863696a9185396ff878e9bda.png)](https://s3.amazonaws.com/infoq.content.live.0/articles/why-flutter-uses-dart/zh/resources/3323-1520961763899.png)

Dart 编写的视图及其效果

注意，可视化这段代码产生的效果是多么容易（即使你没有使用 Dart 的经验）。

[Dart 2](https://www.dartlang.org/dart-2)即将发布，这将变得更加简单，因为`new`和`const`关键字变得可选，所以静态布局看起来像是用声明式布局语言编写的： 

```dart
Center(child:
  Column(children: [
    Text('Hello, World!'),
    Icon(Icons.star, color: Colors.green),
  ])
)
```

然而，我知道你可能在想什么——缺乏专门的布局语言怎么会被称为优势呢？但它确实是颠覆性的。以下是一名开发人员在一篇题为“[为什么原生应用程序开发人员应认真看待 Flutter](https://hackernoon.com/why-native-app-developers-should-take-a-serious-look-at-flutter-e97361a1c073)”的文章中写的内容。

> 在 Flutter 里，界面布局直接通过 Dart 编码来定义，不需要使用 XML 或模板语言，也不需要使用可视化设计器之类的工具。
>
> 说到这里，大家可能会一脸茫然，就像我当初的反应一样。使用可视化工具不是更容易吗？如果把所有的逻辑都写到代码里不是会让事情变复杂吗？
>
> 结果不然。天啊，它简直让我大开眼界。

首先是上面提到的热重载。

> 这比 Android 的 Instant Run 和任何类似解决方案不知道要领先多少年。对于大型的应用同样适用。如此快的速度，正是 Dart 的优势所在。
>
> 实际上，可视化编辑器就变得多余了。我一点都不怀恋 XCode 的自动重布局。

Dart 创建的布局简洁且易于理解，而“超快”的热重载可立即看到结果。这包括布局的非静态部分。

> 结果，在 Flutter 中进行布局要比在 Android/XCode 中快得多。一旦你掌握了它（我花了几个星期），由于很少发生上下文切换，因此会节省大量的开销。不必切换到设计模式，选择鼠标并开始点击，然后想是否有些东西必须通过编程来完成，如何实现等等。因为一切都是程序化的。而且这些 API 设计得非常好。它很直观，并且比自动布局 XML 更强大。

例如，下面是一个简单的列表布局，在每个项目之间添加一个分隔线（水平线），以编程方式定义： 

```dart
return new ListView.builder(itemBuilder: (context, i) {
  if (i.isOdd) return new Divider(); 
  // rest of function
});
```

在 Flutter 中，无论是静态布局还是编程布局，所有布局都存在于同一个位置。[新的 Dart 工具](https://groups.google.com/forum/#!topic/flutter-dev/lKtTQ-45kc4)，包括 Flutter Inspector 和大纲视图（利用所有的布局定义都在代码里）使复杂而美观的布局更加容易。

### Dart 语言标准和 license

不，Dart（如 Flutter）是完全开源的，具备清楚的许可证，同时也是[ECMA 标准](https://www.ecma-international.org/publications/standards/Ecma-408.htm)的。Dart 在 Google 内外很受欢迎。在谷歌内部，它是增长最快的语言之一，并被 Adwords、Flutter、[Fuchsia](https://github.com/fuchsia-mirror)和其他产品使用；在谷歌外部，Dart 代码库有超过 100 个外部提交者。

Dart 开放性的更好指标是 Google 之外的社区的发展。例如，我们看到来自第三方的关于 Dart（包括 Flutter 和 AngularDart）的文章和视频源源不断，我在本文中引用了其中的一些内容。

除了 Dart 本身的外部提交者之外，[公共 Dart 包仓库](https://pub.dartlang.org/)中还有超过 3000 个包，其中包括 Firebase、Redux、RxDart、国际化、加密、数据库、路由、集合等方面的库。

### 秘诀在于专注

Dart 2 的改进集中在优化客户端开发。但 Dart 仍然是构建服务器端、桌面、嵌入式系统和其他程序的绝佳语言。

专注是一件好事。几乎所有持久受欢迎的语言都受益于非常专注。例如：

- C 是编写操作系统和编译器的系统编程语言。
- Java 是为嵌入式系统设计的语言。
- JavaScript 是网页浏览器的脚本语言。
- 即使是饱受非议的 PHP 也成功了，因为它专注于编写个人主页（它的名字来源）。

另一方面，许多语言已经明确地尝试过（并且失败了）成为完全是通用的，例如 PL/1 和 Ada 等等。最常见的问题是，如果没有重点，这些语言就成了众所周知的厨房洗碗槽。

许多使 Dart 成为好的客户端语言的特性也使其成为更好的服务器端语言。例如，Dart 避免了抢占式多任务处理，这一点与服务器上的 Node 具有相同的优点，但是数据类型更好更安全。

编写用于嵌入式系统的软件也是一样的。Dart 能够可靠地处理多个并发输入是关键。

最后，Dart 在客户端上的成功将不可避免地引起用户对服务器上使用的更多兴趣——就像 JavaScript 和 Node 一样。为什么强迫人们使用两种不同的语言来构建客户端——服务器软件呢？

## Dart 语言

[A tour of the Dart language](https://dart.dev/guides/language/language-tour)

## Flutter 开发

[Get Start](https://flutter.dev/docs/get-started/install)

Flutter开发安装包下载[GitHub地址](https://github.com/flutter)，上面还有很多用例可以参照



### For View

iOS，UIView

Android， View

Flutter，Widget

Widget 是基于 State， 当state或者是Widget被改变，Flutter框架重新创建Widget树，相比较 iOS则不会

Widget相比 UIView，更加轻量，因为Widget是不可修改的，且Widget不是 view，不直接参与绘制，只是描述UI的结构

Cupertino Widget是推荐的UI框架

#### Update View

StatelessWidget

StatefulWidget

State of Widget

#### Layout

Only in Code by composing a widget tree

|        | iOS                                         | Android                                 | Flutter                  |
| ------ | ------------------------------------------- | --------------------------------------- | ------------------------ |
| List   | UITableView，UICollectionView，UIScrollView | LinearLayout等类，ScrollView， ListView | ListView，ListView.build |
| select | didSelect                                   | onItemClickListener                     | onTap                    |
| update | reloadData                                  | notifyDataSetChanged                    | setState                 |

![sample-flutter-layout](../../其他文档/resources/sample-flutter-layout.png)

#### Add & Remove(modify view's hierarchy) 

iOS，addSubview、removeFromParentView

Android，addChild，removeChild

Flutter,替代方法是：将创建Widget的方法作为参数传递到父类，使用一个flag开关来控制子控件的创建

```dart
class _SampleAppPageState extends State<SampleAppPage> {
  // Default value for toggle
  bool toggle = true; // 开关，用于控制控件创建的逻辑
  void _toggle() {
    setState(() {
      toggle = !toggle;
    });
  }

  // 创建Widget的方法
  _getToggleChild() {
    if (toggle) {
      return Text('Toggle One');
    } else {
      return CupertinoButton(
        onPressed: () {},
        child: Text('Toggle Two'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Sample App"),
      ),
      body: Center(
        child: _getToggleChild(), // 创建Widget的方法作为参数
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _toggle,
        tooltip: 'Update Text',
        child: Icon(Icons.update),
      ),
    );
  }
}
```

#### Animation

iOS, Animation类，UIView实例的animate方法

Android，XML，或者是 View 实例的animate方法

Flutter，使用 Animation Library 封装 一个 Widget 到一个可以动画的 Widget中

Animation Controller，

Animation 类簇

Ticker 类簇（发送垂直信号）

```dart
// Mixins是一种在多个类层次结构中重用类代码的方法
// 要使用mixin，请使用with关键字后跟一个或多个mixin名称
// TickerProviderStateMixin, 使用Ticker
class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {

  AnimationController controller; //  Animation Controller
  CurvedAnimation curve; // Animation 类簇
  bool toggle = true; // 开关
  
  void _toggle() { // 触发动画的向前和后置
    setState(() {
      if (toggle) {
        controller.forward();
      } else {
        controller.reverse();
      }
      toggle = !toggle;
    });
  }

  @override
  void initState() { // 初始化
    super.initState();
    controller = AnimationController(duration: const Duration(milliseconds: 2000), vsync: this);
    curve = CurvedAnimation(parent: controller, curve: Curves.easeIn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
          child: Container(
              child: FadeTransition(
                  opacity: curve, // 使用 Animation
                  child: FlutterLogo(
                    size: 100.0,
                  )
              )
          )
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Fade',
        child: Icon(Icons.brush),
        onPressed: () {
          controller.forward();
          _toggle();
        },
      ),
    );
  }
  
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
```



#### Drawing

iOS，CoreGraphics Framework

Android，Canvas，Drawable 类

Flutter，Canvas，CustomPaint， CustomPainter

```dart
import 'package:flutter/material.dart';

class SignaturePainter extends CustomPainter {
  SignaturePainter(this.points);

  final List<Offset> points;

  void paint(Canvas canvas, Size size) {
    Paint paint = new Paint()
      ..color = Colors.black
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5.0;
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null)
        canvas.drawLine(points[i], points[i + 1], paint);
    }
  }

  bool shouldRepaint(SignaturePainter other) => other.points != points;
}

class Signature extends StatefulWidget {
  SignatureState createState() => new SignatureState();
}

class SignatureState extends State<Signature> {
  List<Offset> _points = <Offset>[];

  Widget build(BuildContext context) {
    return new Stack(
      children: [
        GestureDetector(
          onPanUpdate: (DragUpdateDetails details) {
            RenderBox referenceBox = context.findRenderObject();
            Offset localPosition =
                referenceBox.globalToLocal(details.globalPosition);
            setState(() {
              _points = new List.from(_points)..add(localPosition);
            });
          },
          onPanEnd: (DragEndDetails details) => _points.add(null),
        ),
        
        // CustomPaint(painter: SignaturePainter(_points), size: Size.infinite), 
        // 上面的代码无效，为什么要 new ？
        CustomPaint(painter: new SignaturePainter(_points))
      ],
    );
  }
}

class DemoApp extends StatelessWidget {
  Widget build(BuildContext context) => new Scaffold(body: new Signature());
}

void main() => runApp(new MaterialApp(home: new DemoApp()));
```



#### Opacity

iOS，property，opacity、alhpa

Flutter，Opacity widget



#### Custom Widget

iOS，继承UIView

Android，继承View，或者是使用已经存在的View，然后override相应的方法来达到想要的效果

Flutter，组合多个Widget到一个Widget

```dart
// 创建方法
class CustomButton extends StatelessWidget {
  final String label;

  CustomButton(this.label);

  @override
  Widget build(BuildContext context) {
    return RaisedButton(onPressed: () {}, child: Text(label));
  }
}

// 使用方法
@override
Widget build(BuildContext context) {
  return Center(
    child: CustomButton("Hello"),
  );
}
```

### For Navigation

#### between pages

iOS, UINavigationController

Android，Intent，在Activity之间切换或者是组件之间传递数据，调用外部组件（照相机等）

Flutter，Navigator，Router

Router，类似UIViewController，Navigator 类似UINavigationController（pop，push）

```dart
void main() {
  runApp(CupertinoApp(
    home: MyAppHome(), // becomes the route named '/'
    routes: <String, WidgetBuilder> {
      '/a': (BuildContext context) => MyPage(title: 'page A'),
      '/b': (BuildContext context) => MyPage(title: 'page B'),
      '/c': (BuildContext context) => MyPage(title: 'page C'),
    },
  ));
}
```

导航到指定页的代码：

```dart
Navigator.of(context).pushNamed('/b');
```



Android,startActivityForResult()

Flutter,

```dart
// start
Map coordinates = await Navigator.of(context).pushNamed('/location');

// pop
Navigator.of(context).pop({"lat":43.821757,"long":-79.226392});
```

#### between Apps

iOS，URL Scheme

Flutter，使用原生或者是封装原生的插件，比如url_lanucher

 #### Pop to iOS native VC

SystemNavigator.pop()， 不管用的话，就使用Platform channel 去调用原生

### Threading & asynchronicity

#### async

参照dart语言中的 async 关键字来标识函数

#### background thread

iOS, 除了VoIP应用外，其他不允许长时间的后台用户级的线程存在

Android, AsyncTask，LiveData，IntentService，JobScheduler，RxJava Pipeline

参照dart语言中的 async、await 关键字来标识函数，如果是CPU密集任务，则使用 Isolate进行任务线程隔离，来避免事件Loop被阻塞，但是这里就不能更新UI，但是可以通过setState()来更新UI

```dart
loadData() async {
  String dataURL = "https://jsonplaceholder.typicode.com/posts";
  http.Response response = await http.get(dataURL);
  setState(() {
    widgets = json.decode(response.body);
  });
}
```



#### network request

iOS，URL Loading System

Android，OkHttp

Flutter，http package



### Project structure, localization, dependencies and assets

#### Images

iOS，image resources, assets

Android，image resources, assets， res/drawable-*, no dp, logiccal pixel

| Android density qualifier | Flutter pixel ratio |
| ------------------------- | ------------------- |
| `ldpi`                    | `0.75x`             |
| `mdpi`                    | `1.0x`              |
| `hdpi`                    | `1.5x`              |
| `xhdpi`                   | `2.0x`              |
| `xxhdpi`                  | `3.0x`              |
| `xxxhdpi`                 | `4.0x`              |

Flutter, assets, 不仅仅是图片，其他文件也可以

声明方式：pubspec.yaml

```yaml
assets:
 - my-assets/data.json
```

引用方式：AssetBundle

```dart
import 'dart:async' show Future;
import 'package:flutter/services.dart' show rootBundle;

Future<String> loadAsset() async {
  return await rootBundle.loadString('my-assets/data.json');
}
```

使用不同分辨率的图片，使用类似iOS的命名方式：1.0x, 2.0x, 3.0x，创建任意文件夹，比如images，文件放置目录的方式：

```
images/my_icon.png       // Base: 1.0x image
images/2.0x/my_icon.png  // 2.0x image
images/3.0x/my_icon.png  // 3.0x image
```

声明图片：pubspec.yaml

```yaml
assets:
 - images/my_icon.png
```

引用方式：AssetImage/Image

```dart
// 方式一
return AssetImage("images/a_dot_burr.jpeg");

// 方式二
@override
Widget build(BuildContext context) {
  return Image.asset("images/my_image.png");
}
```

#### Localization

iOS, Localizable.strings 文件

Flutter，使用类似Java的常量类来封装字符串，默认只支持En，如果需要，需要引用 flutter_localizations、intl package

```dart
import 'package:flutter_localizations/flutter_localizations.dart';

MaterialApp(
 localizationsDelegates: [
   // Add app-specific localization delegate[s] here
   GlobalMaterialLocalizations.delegate,
   GlobalWidgetsLocalizations.delegate,
 ],
 supportedLocales: [
    const Locale('en', 'US'), // English
    const Locale('he', 'IL'), // Hebrew
    // ... other locales the app supports
  ],
  // ...
)
```

要访问本地化资源，请使用 Localizations.of() 方法访问由给定委托提供的特定本地化类。 使用intl_translation包将可翻译的副本提取到arb文件进行翻译，然后将它们导回到应用程序中以便与intl一起使用

#### Dependency

iOS,CocoaPods,一般原生依赖使用

Android, Gradle,一般原生依赖使用

Flutter, 主要依赖pubspec.yaml文件来解决依赖包



### Liftcycle Event

iOS, override the object method

Android, override the object method,或者是在Application类上注册ActivityLifecycleCallbacks

Flutter，hook WidgetBinging 观察者和监听 didChangeAppLifecycleState() 改变事件

- inactive，Android 没有
- paused，不可见，不响应用户输入，但是在后台运行
- resumed
- suspending，iOS 没有



### Gesture & Touch

#### 监听 Widget

iOS， GestureRecogniezer

Android，在setOnClickListener中调用onClick

Flutter，GestureDetector

两种方式：

1. 支持事件的控件，实现响应事件类型的处理方法即可

   ```dart
   @override
   Widget build(BuildContext context) {
     return RaisedButton(
       onPressed: () {
         print("click");
       },
       child: Text("Button"),
     );
   }
   ```

   

2. 不支持事件的控件，将Widget封装到一个GestureDetector中，然后传递一个方法到onTap参数

   ```dart
   class SampleApp extends StatelessWidget {
     @override
     Widget build(BuildContext context) {
       return Scaffold(
         body: Center(
           child: GestureDetector(
             child: FlutterLogo(
               size: 200.0,
             ),
             onTap: () {
               print("tap");
             },
           ),
         ),
       );
     }
   }
   ```

   #### 支持的事件类型

   - Taping

     - onTapDown
     - onTapUp
     - onTap
     - onTapCancel

   - Double tap

     - onDoubleTap

   - Long Press

     - onLongPress

   - Vertical dragging

     - onVerticalDragStart
     - onVerticalDragUpdate
     - onVerticalDragEnd

   - Horizontal dragging

     同上

### Theming And Text

#### Theme

- MaterialApp， 支持自定义子控件的颜色和样式，传递一个ThemeData对象
- Cupertino 库

#### Text

iOS，ttf文件，在info.plist文件中创建引用即可

Android，创建Font resource文件，并传递给TextView的FontFamily参数

Flutter，ttf文件，工程目录中任意位置，在pubspec.yaml文件中声明引用，类似图片一样

```yaml
fonts:
   - family: MyCustomFont
     fonts:
       - asset: fonts/MyCustomFont.ttf
       - style: italic
```

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text("Sample App"),
    ),
    body: Center(
      child: Text(
        'This is a custom font text',
        style: TextStyle(fontFamily: 'MyCustomFont'),
      ),
    ),
  );
}
```

### Form Input

```dart
class _MyFormState extends State<MyForm> {
  // Create a text controller and use it to retrieve the current value.
  // of the TextField!
  final myController = TextEditingController();

  @override
  void dispose() {
    // Clean up the controller when disposing of the Widget.
    myController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Retrieve Text Input'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: TextField(
          controller: myController,
          decoration: InputDecoration(hintText: "placeholder"), // 默认占位符
        ),
      ),
      floatingActionButton: FloatingActionButton(
        // When the user presses the button, show an alert dialog with the
        // text the user has typed into our text field.
        onPressed: () {
          return showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                // Retrieve the text the user has typed in using our
                // TextEditingController
                content: Text(myController.text),
              );
            },
          );
        },
        tooltip: 'Show me the value!',
        child: Icon(Icons.text_fields),
      ),
    );
  }
}
```

### 集成硬件、第三方服务和平台

Flutter不直接在底层平台上运行代码; 相反，构成Flutter应用程序的Dart代码在本地设备上运行，“回避”平台提供的SDK。 这意味着，例如，当在Dart中执行网络请求时，它将直接在Dart上下文中运行。 在编写本地应用程序时，通常不利用的Android或iOS API。 Flutter应用程序在本地应用程序的ViewController中仍作为视图托管，但无法直接访问ViewController本身或本地框架。

Flutter 提供 Platform channel 来与原生 API进行通信

优先使用 dart plugin

### 缓存

| iOS             | Android                 | Flutter                | Note |
| --------------- | ----------------------- | ---------------------- | ---- |
| UserDefaults    | SharedPreferences       | SharePreference plugin |      |
| CoreData/SQLite | android.database.sqlite | SQFlite plugin         |      |

