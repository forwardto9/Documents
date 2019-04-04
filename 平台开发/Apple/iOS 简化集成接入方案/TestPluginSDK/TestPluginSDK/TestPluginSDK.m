//
//  TestPluginSDK.m
//  TestPluginSDK
//
//  Created by uwei on 2018/10/17.
//  Copyright © 2018 TEG of Tencent. All rights reserved.
//

#import "TestPluginSDK.h"
#import "PluginProxy.h"
@implementation TestPluginSDK

+ (void)load {
    NSLog(@"load TestPluginSDK");
}

+ (void)method {
    NSLog(@"%@", [[PluginProxy shareInstance] showSomething]);
}

@end
