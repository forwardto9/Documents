# Flutter 工作原理简介

## 绘图基本原理

计算机在屏幕上的绘图原理过程：

![x](../../其他文档/resources/computer-drawing.png)

- CPU 将计算好的显示内容提交给 GPU
- GPU 使用 VRAM 中的数据和命令，完成图像渲染
- 将渲染好的结果存入`帧缓冲区` (FrameBuffer)
- 然后`视频控制器`将`帧缓冲区`的数据传递给显示器显示

> 帧缓冲区：简称帧缓存或显存，它是屏幕所显示画面的一个直接映象，又称为位映射图(Bit Map)或光栅。帧缓存的每一存储单元对应屏幕上的一个像素，整个帧缓存对应一帧图像

当然，Android、iOS 的 UI 渲染过程是如此，Flutter 也是如此，在整个 Flutter 架构中，Flutter 只关心向 GPU 提供显示数据，并不关心显示器、视频控制器以及 GPU 是如何工作的。

![Graphics Pipeline](../../其他文档/resources/flutter/flutter-graphics-pipeline.png)

- `GPU`将信号(垂直同步信号（VSync）)同步到 `UI 线程`
- `UI 线程`用`Dart`来构建`图层树`
- `图层树`在`GPU 线程`进行合成
- 合成后的`视图数据`提供给`Skia 引擎`
- `Skia 引擎`通过`OpenGL 或者 Vulkan`将显示内容提供给`GPU`

## Flutter 框架设计

Flutter 整体框架是由 Dart 语言来实现的，它的层次非常清晰，每层（模块）的职责也相对单一，整个结构让 Flutter 框架在使用上来说更加容易和学习。框架的底层是 Flutter 引擎，它负责绘图、动画、网络、Dart 运行时等功能，是由 C++ 实现的:

![flutter-architecture](../../其他文档/resources/flutter/flutter-architecture.png)

- Framework

  是一个纯 Dart实现的 SDK，类似于 React在 JavaScript中的作用。它实现了一套基础库， 用于处理动画、绘图和手势。并且基于绘图封装了一套 UI组件库，然后根据 `Material` 和`Cupertino`两种视觉风格区分开来。这个纯 Dart实现的 SDK被封装为了一个叫作 `dart:ui`的 Dart库。我们在使用 Flutter写 App的时候，直接导入这个库即可使用组件等功能

  - Meterial, Cupertino：针对 Android 的 Meterial 风格，和针对 iOS 的 Cupertino 风格；
  - Widgets：按钮、文本、输入框、图片等组件；
  - Rendering：渲染层，负责布局、绘制、合成等；
  - Animation, Painting, Gestures：动画、绘图、手势；
  - Foundation：最底层，提供上层需要使用的工具类和方法；

- Engine

  纯 C++实现的 SDK，其中囊括了 Skia引擎、Dart运行时、文字排版引擎等。不过说白了，它就是 Dart的一个运行时，它可以以 JIT、JIT Snapshot 或者 AOT的模式运行 Dart代码。在代码调用 `dart:ui`库时，提供 `dart:ui`库中 Native Binding 实现。 不过别忘了，这个运行时还控制着 VSync信号的传递、GPU数据的填充等，并且还负责把客户端的事件传递到运行时中的代码

  - Skia：图形绘制，是Flutter向 GPU提供数据的途径

    Skia是一个 2D的绘图引擎库，其前身是一个向量绘图软件，Chrome和 Android均采用 Skia作为绘图引擎。Skia提供了非常友好的 API，并且在图形转换、文字渲染、位图渲染方面都提供了友好、高效的表现。Skia是跨平台的，所以可以被嵌入到 Flutter的 iOS SDK中，而不用去研究 iOS闭源的 Core Graphics / Core Animation

    > Android自带了 Skia，所以 Flutter Android SDK要比 iOS SDK小很多。

  - Dart：语言运行时

  - Text：纹理

## Flutter 布局机制

Flutter 提供众多的布局组件，这一点和其它 Web 前端框架的差别非常大，种类如下：

- 单个子元素的布局
  - Container
  - Padding
  - Center
  - Align
  - ... 多达18种
- 多个子元素的布局
  - Row
  - Column
  - Stack
  - ... 多达11种

Flutter 如此繁多的布局组件，对于开发者来说学习难度非常大，并且在不同的页面采用适合的组件非常难选，并且在复杂的布局结构中组件的嵌套非常的深和复杂，这几点绝对让一个 Web 前端开发人员鄙视。或许未来 Flutter 会有更加对开发人员友好的布局设计。

## Flutter Widget 生命周期&状态控制

Flutter 框架的 UI 是基于 Widget 的，一切皆 Widget，与 Vue、React 等前端框架一样，部件有自己的生命周期：

![flutter-state-lifecycle](../../其他文档/resources/flutter/flutter-state-lifecycle.png)

## Flutter 渲染

Flutter 界面渲染分三个阶段：布局、绘制和合成。布局和绘制是在 Flutter 框架层完成的，合成则是由 Flutter 引擎来完成的。

![flutter-rendering-pipeline](/Users/uwei/GitHub/forwardto9/Documents/其他文档/resources/flutter/flutter-rendering-pipeline.png)

- `动画`的运行会改变部件状态（update state）
- 状态的改变会触发`图层树`的重建
- 根据新旧`图层树`的差异更新`渲染树`
- 新的`渲染树`合成新的`图层列表`
- 重新输出`图层树`

## Flutter 引擎

Flutter 引擎是由 C++ 实现的，主要包含：Skia、Dart和Text 三大部分：

- Skia：是由 Google 提供的二维图形框架，包含字型、坐标转换，以及点阵图都有高效能且简洁的表现。它运用在在 Chrome、Android、Firefox 等产品上
- Dart：是 Dart 语言的运行时
- Text：纹理处理库

## Flutter 工程结构简介

通过 Flutter 插件可以自动创建 Flutter 项目，目录结构如下：

- android：Android 原生项目
- build
- ios：iOS 原生项目
- lib：Flutter 项目源代码
- test：单元测试
- .metadata
- .packages
- pubspec.lock：项目所有依赖，一颗依赖树
- pubspec.yaml：项目主依赖配置

## Flutter vs WebView vs ReactNative

### WebView

最早的跨平台解决方案，是借助 App 内部的 WebView 组件来实现的，也就是 App 内部的浏览器。但是由于它的性能、兼容性、稳定性都表现不够出色，并且在联调上有太多的障碍，导致这个技术已经不再流行。

![flutter-webview](../../其他文档/resources/flutter/flutter-webview.png)

说白了，其实它仅仅只是 Web 的开发，UI 和业务逻辑都是 Web 的部分，如果要调取 Native 的硬件设备，需要 Native 拦截特殊的 Http 请求从而获取硬件设备信息。当然它有自己的好处，更新快，有问题随时发布。

### ReactNative

ReactNative 在 WebView 的方案上更进一步，借助 App 内置 Javascrpit 引擎，将 JavaScript 和 Native 进行桥接，直接通过 JavaScript 来调取 Native 的相关组件，在性能上比 WebView 要更胜一筹。

![flutter-reactnative](../../其他文档/resources/flutter/flutter-reactnative.png)

这种形势的跨平台并非真正意义的跨平台，如果要做 UI 或者新的组件时，还是需要在 iOS 和 Android 两端上都有对应接口的实现才行。由于有 JavaScript 桥接这一层，在性能上还是稍差于纯 Native 开发。但是即便于此，它低廉的学习成本，与 Web 前端开发方式一样有着直观易懂，以及极高的开发效率，得到了开发人员（尤其是 Web 前端）的青睐。

### Flutter

Flutter 可以说是跨平台解决方案的再一次进化，它直接借助 OpenGL 通过 GPU 来绘制 UI，并且通过 C++ 直接和系统层交互。

![flutter-pattern](../../其他文档/resources/flutter/flutter-pattern.png)

Flutter 可以说在性能更加的高，在跨平台解决方案上更加彻底，但是它的学习曲线相对陡峭，并且刚刚起步，生态还为形成，不过潜力还是非常大。



## 参考

[Flutter 原理简解](https://juejin.im/entry/5afa9769518825428630a61c)

[Flutter 工作原理简介](https://github.com/lijiakof/flutter-tutorial/blob/master/docs/flutter-principle.md)

[跨平台技术演进](https://juejin.im/post/5ca1671651882567d41ebf6d)

