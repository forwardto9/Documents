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
@end

@interface PluginProxy : NSObject

+ (nonnull instancetype)shareInstance;

@property (nonatomic, weak, nullable) id <PluginDelegate>delegate;
- (nullable NSString *)showSomething;

@end
