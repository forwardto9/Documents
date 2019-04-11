//
//  Plugin.m
//  Plugin
//
//  Created by uwei on 2018/10/17.
//  Copyright © 2018 TEG of Tencent. All rights reserved.
//

#import <UserNotifications/UserNotifications.h>
#import <UIKit/UIKit.h>

#import "Plugin.h"
#import "PluginProxy.h"

@implementation Plugin

+ (void)load {
    NSLog(@"load of Plugin");
    [PluginProxy shareInstance].delegate = [Plugin shareInstance];
}


+ (instancetype)shareInstance {
    NSLog(@"shareInstance of Plugin");
    static dispatch_once_t onceToken;
    static Plugin *plugin;
    dispatch_once(&onceToken, ^{
        plugin = [[self alloc] init];
    });
    return  plugin;
}

- (NSString *)showSomething {
    NSLog(@"showSomething of plugin");
    return @"plugin";
}

- (void)registerRemoteNotification:(void (^)(BOOL result, NSError *error))handler {
    
    float sysVer = [[[UIDevice currentDevice] systemVersion] floatValue];
    
    if (sysVer >= 10) {
        [self registerNotificationForiOS10Later:handler];
    } else if (sysVer >= 8) {
        [self registerNotificationForiOS8To9:handler];
    } else {
        [self registerNotificationForiOS8Earlier:handler];
    }
}

- (void)registerNotificationForiOS10Later:(void (^)(BOOL result, NSError *error))handler {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    center.delegate = self;
    
    // 请求认证权限
    [center requestAuthorizationWithOptions:UNAuthorizationOptionAlert|UNAuthorizationOptionSound|UNAuthorizationOptionBadge completionHandler:^(BOOL granted, NSError *_Nullable error) {
        if (handler) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!granted && !error) {
                    NSError *tips = [NSError errorWithDomain:NSCocoaErrorDomain code:0 userInfo:@{(NSString *)kCFErrorLocalizedDescriptionKey: @"Notification permission is not allowed" }];
                    handler(granted, tips);
                } else {
                    handler(granted, error);
                }
            });
        }
    }];
    
    [[UIApplication sharedApplication] registerForRemoteNotifications];
#else
    if (handler) {
        NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain code:-1 userInfo:@{(NSString *)kCFErrorLocalizedDescriptionKey: @"System not support"}];
        handler(NO, error);
    }
#endif
}

- (void)registerNotificationForiOS8To9:(void (^)(BOOL result, NSError *error))handler {
    UIUserNotificationType types = UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound;
    UIUserNotificationSettings *notificationSettings = [UIUserNotificationSettings settingsForTypes:types categories:nil];
    [[UIApplication sharedApplication] registerUserNotificationSettings:notificationSettings];
    [[UIApplication sharedApplication] registerForRemoteNotifications];
    if (handler) {
        handler(YES, nil);
    }
}

- (void)registerNotificationForiOS8Earlier:(void (^)(BOOL result, NSError *error))handler {
    __PRAGMA_PUSH_NO_EXTRA_ARG_WARNINGS
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound];
    __PRAGMA_POP_NO_EXTRA_ARG_WARNINGS
}


@end
