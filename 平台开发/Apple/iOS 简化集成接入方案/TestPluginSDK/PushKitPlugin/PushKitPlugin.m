//
//  PushKitPlugin.m
//  PushKitPlugin
//
//  Created by uwei on 2019/4/11.
//  Copyright © 2019 TEG of Tencent. All rights reserved.
//
#import <PushKit/PushKit.h>
#import <UserNotifications/UserNotifications.h>
#import <UIKit/UIKit.h>

#import "PushKitPlugin.h"
#import "PluginProxy.h"

@interface PushKitPlugin ()<PKPushRegistryDelegate>

@property (strong, nonatomic) PKPushRegistry *xgVoIPPushRegistry;

@end

@implementation PushKitPlugin

+ (void)load {
    NSLog(@"load of PushKitPlugin");
    [PluginProxy shareInstance].pushKitDelegate = [PushKitPlugin shareInstance];
}


+ (instancetype)shareInstance {
    NSLog(@"shareInstance of PushKitPlugin");
    static dispatch_once_t onceToken;
    static PushKitPlugin *plugin;
    dispatch_once(&onceToken, ^{
        plugin = [[self alloc] init];
    });
    return  plugin;
}

#pragma mark PushKit Register
- (void)registerPushKitInQueue:(dispatch_queue_t)queue {
    self.xgVoIPPushRegistry = [[PKPushRegistry alloc] initWithQueue:queue];
    self.xgVoIPPushRegistry.desiredPushTypes = [NSSet setWithObject:PKPushTypeVoIP];
    self.xgVoIPPushRegistry.delegate = self;
}

#pragma mark - PKPushRegistryDelegate
- (void)pushRegistry:(nonnull PKPushRegistry *)registry didUpdatePushCredentials:(nonnull PKPushCredentials *)pushCredentials forType:(nonnull PKPushType)type {
    NSLog(@"%s", __FUNCTION__);
}

@end
