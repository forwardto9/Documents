//
//  Plugin.m
//  Plugin
//
//  Created by uwei on 2018/10/17.
//  Copyright © 2018 TEG of Tencent. All rights reserved.
//

#import "Plugin.h"
#import "PluginProxy.h"

@implementation Plugin

+ (void)load {
    NSLog(@"load of plugin");
    [PluginProxy shareInstance].delegate = [Plugin shareInstance];
}


+ (instancetype)shareInstance {
    NSLog(@"shareInstance of plugin");
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
@end
