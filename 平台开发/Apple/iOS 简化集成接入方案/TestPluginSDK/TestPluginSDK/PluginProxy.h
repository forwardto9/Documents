//
//  PluginProxy.h
//  TestPlugin
//
//  Created by uwei on 2018/10/17.
//  Copyright © 2018 TEG of Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol PluginDelegate <NSObject>
@required
- (nullable NSString *)showSomething;
- (void)registerRemoteNotification:(void (^)(BOOL result, NSError *error))handler;
@end

@protocol PluginPushKitDelegate <NSObject>
@required
- (void)registerPushKitInQueue:(dispatch_queue_t)queue;

@end

@interface PluginProxy : NSObject

+ (nonnull instancetype)shareInstance;

@property (nonatomic, weak, nullable) id <PluginDelegate>delegate;
@property (nonatomic, weak, nullable) id <PluginPushKitDelegate> pushKitDelegate;
- (nullable NSString *)showSomething;
- (void)registerRemoteNotification:(void (^)(BOOL result, NSError *error))handler;
- (void)registerPushKitInQueue:(dispatch_queue_t)queue;

@end
