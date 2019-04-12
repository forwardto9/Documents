//
//  TestPluginSDK.m
//  TestPluginSDK
//
//  Created by uwei on 2018/10/17.
//  Copyright © 2018 TEG of Tencent. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "TestPluginSDK.h"
#import "PluginProxy.h"
#import "XGPushApplicationDelegateInjectionProtocol.h"
#import "XGPushCheckSuper.h"
#import <objc/message.h>

@interface TestPluginSDK () <XGPushApplicationDelegateInjectionProtocol>
@property (class, nonatomic, copy) NSArray *observeClasses;
@end

@implementation TestPluginSDK


+ (NSArray *)observeClasses {
    return @[@"Plugin", @"PushKitPlugin"];
}

+ (void)load {
    NSLog(@"load TestPluginSDK");
}

+ (void)method {
//    int numClasses;
//    Class * classes = NULL;
//
//    classes = NULL;
//    numClasses = objc_getClassList(NULL, 0);
//
//    if (numClasses > 0 )
//    {
//        classes = (Class *)malloc(sizeof(Class) * numClasses);
//        numClasses = objc_getClassList(classes, numClasses);
//        for (Class *c = classes ; *c != NULL; c++) {
//            if ([TestPluginSDK.observeClasses containsObject:NSStringFromClass(*c)]) {
//                NSLog(@"Find target Class [%@]", NSStringFromClass(*c));
//            }
//        }
//        free(classes);
//    }
    
//    Class plugin = NSClassFromString(@"Plugin");
    id plugin = objc_getClass("Plugin");
    if (plugin) {
        unsigned int methodCount = 0;
        Method* logicMethodList= class_copyMethodList(plugin, &methodCount);
        for (int i = 0; i < methodCount; i++) {
            Method m = logicMethodList[i];
            
            NSLog(@"Plugin instance method (%@) type encode (%s) type encode without size (%@)", NSStringFromSelector(method_getName(m)), method_getTypeEncoding(m), [[[NSString stringWithCString:method_getTypeEncoding(m) encoding:NSUTF8StringEncoding] componentsSeparatedByCharactersInSet:[NSCharacterSet decimalDigitCharacterSet]] componentsJoinedByString:@""]);
            if ([[[[NSString stringWithCString:method_getTypeEncoding(m) encoding:NSUTF8StringEncoding] componentsSeparatedByCharactersInSet:[NSCharacterSet decimalDigitCharacterSet]] componentsJoinedByString:@""] isEqualToString:@"@@:"]) {
                method_invoke(plugin, m);
            }
        }
    }
    
    // 以下插件化动态调用示例，可以不需要在TestPluginSDK中设计接口相关的代码
    // 优点： 代码少，组件更新迭代隔离，维护成本小，执行顺序的控制可以通过新增标识优先级的参数
    // 缺点：代码晦涩，不适合参数较多或者是带有复杂结构的参数的方法
    id pluginWithoutProxy = objc_getClass("PluginWithoutProxy");
    if (pluginWithoutProxy) {
        unsigned int methodCount = 0;
        Method* logicMethodList= class_copyMethodList(pluginWithoutProxy, &methodCount);
        for (int i = 0; i < methodCount; i++) {
            Method m = logicMethodList[i];
            
            NSLog(@"Plugin instance method (%@) type encode (%s) type encode without size (%@)", NSStringFromSelector(method_getName(m)), method_getTypeEncoding(m), [[[NSString stringWithCString:method_getTypeEncoding(m) encoding:NSUTF8StringEncoding] componentsSeparatedByCharactersInSet:[NSCharacterSet decimalDigitCharacterSet]] componentsJoinedByString:@""]);
            if ([[[[NSString stringWithCString:method_getTypeEncoding(m) encoding:NSUTF8StringEncoding] componentsSeparatedByCharactersInSet:[NSCharacterSet decimalDigitCharacterSet]] componentsJoinedByString:@""] isEqualToString:@"v@:"]) {
                method_invoke(pluginWithoutProxy, m);
            }
        }
    }
    
    NSLog(@"%@", [[PluginProxy shareInstance] showSomething]);
}

+ (void)registerRemoteNotification {
    [[PluginProxy shareInstance] registerRemoteNotification:^(BOOL result, NSError *error) {
        NSLog(@"%d, %@", result, error);
    }];
}

+ (void)registerPushKit {
    [[PluginProxy shareInstance] registerPushKitInQueue:dispatch_get_main_queue()];
}

#pragma mark - XGPush Inject Token Method
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)token {
    NSLog(@"%s", __FUNCTION__);
    if (__XGPushSuperImplatationCurrentCMD__) {
        XGPushPrepareSendSuper(void, id, id);
        XGPushSendSuper(application, token);
    }
}

@end
