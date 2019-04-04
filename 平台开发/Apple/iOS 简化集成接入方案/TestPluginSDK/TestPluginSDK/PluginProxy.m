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
    NSLog(@"shareInstance of proxy");
    static dispatch_once_t onceToken;
    static PluginProxy *proxy;
    dispatch_once(&onceToken, ^{
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

@end
