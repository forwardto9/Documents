//
//  Plugin.h
//  Plugin
//
//  Created by uwei on 2018/10/17.
//  Copyright © 2018 TEG of Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol PluginDelegate;
@interface Plugin : NSObject<PluginDelegate>
+ (instancetype)shareInstance;
- (NSString *)showSomething;
- (void)registerRemoteNotification:(void (^)(BOOL result, NSError *error))handler;
@end
