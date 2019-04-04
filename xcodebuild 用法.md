# xcodebuild 用法

xcodebuild -list

Information about project "testxcommand":

​    Targets:

​        testxcommand

​        testxcommand2



​    Build Configurations:

​        Debug

​        Release



​    If no build configuration is specified and -scheme is not passed then "Release" is used.



​    Schemes:

​        testxcommand

​        testxcommand2



以上命令用来查找当前目录下可以用来编译的项目，一般都会有 Target 和 Scheme





## 基于Target的编译



xcodebuild -project testxcommand.xcodeproj -target testxcommand2 GCC_PREPROCESSOR_DEFINITIONS='KCONDITION2=1'

-project 工程文件名

-target  目标名，也可以使用 -alltargets 来编译当前工程中包含的全部Target

GCC_PREPROCESSOR_DEFINITIONS，用来指定BuildSettings中的Key-Value

- BuildSettings中的 ProcessorMacros 选项的抽象
- 数量与project configuration对应，例如Debug，Release
- 使用形式：GCC_PREPROCESSOR_DEFINITIONS='KCONDITION2=1’，1.如果有多个需要使用空格分割，2.KV是字符串
- 对应工程包含的源文件中的宏条件编译(#if #endif) 
- 设置此命令行参数，会忽略 -configuration的指定
- 使用命令：xcodebuild -project testxcommand.xcodeproj  -target testxcommand2 -configuration Debug -showBuildSettings | grep GCC_PREPROCESSOR_DEFINITIONS，来查看指定project下的指定target下的指定configuration的对应字段的配置信息(如果使用-alltargets，则会列出工程文件和目标文件的BuildSettings)
- 针对工程中的BuildSettings中的其他设置项，于此用法一致





xcodebuild -project testxcommand.xcodeproj -alltargets -configuration Debug -sdk macosx10.13



-sdk的使用

1. 首要是明确当前xcodebuild执行的环境，即xcode-select -p命令会打印的路径
2. 使用xcodebuild -showsdks,在active developer directory中查看已经安装SDK的信息，会显示sdk版本已经sdk名，即 -sdk 之后可以指定的参数名
3. xcode-select会更改active developer directory值
4. 使用绝对路径时，一般都是在当前Xcode的active developer directory中包含的已安装的SDK的路径，例如：/Applications/Xcode9.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.13.sdk
5. 注意工程文件中指定的deploy target指定的SDK的版本
6. 使用xcrun --show-sdk-path 查看选定的SDK安装的路径，基本无用





## 基于Scheme的编译

xcodebuild -project testxcommand.xcodeproj -scheme testxcommand -destination "platform=macOS,arch=x86_64,id=ED5E9702-6B4B-5F70-976B-531448D22E75" -destination-timeout 10 -sdk macosx10.14 -derivedDataPath ~/Desktop/build

1. 指定scheme名称 
2. 通过指定derivedDataPath来指定输出文件的位置



xcodebuild -showdestinations

​                [-project name.xcodeproj | [-workspace name.xcworkspace -scheme schemename]]

查询编译当前项目的可用设备，从而在destination 参数中用指定编译项目



比较Target与Scheme

1. 一次只能编译一个当前处于active的scheme
2. scheme编译时，可以指定derivedDataPath 来修改编译结果输出的位置