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

@interface TestPluginSDK () <XGPushApplicationDelegateInjectionProtocol>

@end

@implementation TestPluginSDK

+ (void)load {
    NSLog(@"load TestPluginSDK");
}

+ (void)method {
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
