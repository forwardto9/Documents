//
//  PluginProxy.m
//  TestPlugin
//
//  Created by uwei on 2018/10/17.
//  Copyright © 2018 TEG of Tencent. All rights reserved.
//

#import "PluginProxy.h"
@implementation PluginProxy

+ (instancetype)shareInstance {
    
    static dispatch_once_t onceToken;
    static PluginProxy *proxy;
    dispatch_once(&onceToken, ^{
        NSLog(@"shareInstance of proxy");
        proxy = [[self alloc] init];
    });
    return  proxy;
}

- (NSString *)showSomething {
    NSLog(@"showSomething of proxy");
    if (self.delegate) {
        return [self.delegate showSomething];
    } else {
        return nil;
    }
}

- (void)registerRemoteNotification:(void (^)(BOOL, NSError *))handler {
    if ([self.delegate respondsToSelector:@selector(registerRemoteNotification:)]) {
        [self.delegate registerRemoteNotification:handler];
    }
}

- (void)registerPushKitInQueue:(dispatch_queue_t)queue {
    if ([self.pushKitDelegate respondsToSelector:@selector(registerPushKitInQueue:)]) {
        [self.pushKitDelegate registerPushKitInQueue:queue];
    }
}

@end
