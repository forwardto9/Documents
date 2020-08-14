//
//  ModuleB.m
//  ModuleB
//
//  Created by uweiyuan on 2020/8/12.
//  Copyright © 2020 Tencent. All rights reserved.
//

#import "ModuleB.h"

@implementation ModuleB

+(void)load {
    NSLog(@"%s", __FUNCTION__);
    Class coreModule = NSClassFromString(@"ServiceManager");
    if (coreModule) {
        SEL instanceSEL = NSSelectorFromString(@"shareInstance");
        id sharedInstance = ((id(*)(id, SEL))[coreModule methodForSelector:instanceSEL])(coreModule,instanceSEL);
        SEL reg = NSSelectorFromString(@"registerService:withClass:");
        ((void * (*)(id, SEL, Protocol*, Class))[sharedInstance methodForSelector:reg])(sharedInstance, reg, @protocol(ModuleBService), [self class]);
    }
}

+ (instancetype)shareInstance {
    static ModuleB *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[ModuleB alloc] init];
    });
    return instance;
}

+ (BOOL)isSubModule {
    return YES;
}

- (void)moduleBMethod {
    NSLog(@"%s", __FUNCTION__);
}

@end
