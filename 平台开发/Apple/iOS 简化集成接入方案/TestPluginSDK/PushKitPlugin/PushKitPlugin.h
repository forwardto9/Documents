//
//  PushKitPlugin.h
//  PushKitPlugin
//
//  Created by uwei on 2019/4/11.
//  Copyright © 2019 TEG of Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol PluginPushKitDelegate;
@interface PushKitPlugin : NSObject<PluginPushKitDelegate>
+ (instancetype)shareInstance;
- (void)registerPushKitInQueue:(dispatch_queue_t)queue;
@end
