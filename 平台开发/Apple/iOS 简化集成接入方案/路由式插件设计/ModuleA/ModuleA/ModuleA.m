//
//  ModuleA.m
//  ModuleA
//
//  Created by uweiyuan on 2020/8/12.
//  Copyright © 2020 Tencent. All rights reserved.
//

#import "ModuleA.h"

@implementation ModuleA

+(void)load {
    NSLog(@"%s", __FUNCTION__);
//    [[ModuleCore shareInstance] registerService:@protocol(ModuleAService) withClass:[self class]];
    
    Class coreModule = NSClassFromString(@"ServiceManager");
    if (coreModule) {
        SEL instanceSEL = NSSelectorFromString(@"shareInstance");
        id sharedInstance = ((id(*)(id, SEL))[coreModule methodForSelector:instanceSEL])(coreModule,instanceSEL);
        SEL reg = NSSelectorFromString(@"registerService:withClass:");
        ((void * (*)(id, SEL, Protocol*, Class))[sharedInstance methodForSelector:reg])(sharedInstance, reg, @protocol(ModuleAService), [self class]);
    }
}

+ (instancetype)shareInstance {
    static ModuleA *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[ModuleA alloc] init];
    });
    return instance;
}

+ (BOOL)isSubModule {
    return YES;
}

- (void)moduleAMethod {
    NSLog(@"%s", __FUNCTION__);
    [self callModuleB];
}

- (void) callModuleB {
    NSLog(@"%s", __FUNCTION__);
//    id <ModuleBService> obj = [[ModuleCore shareInstance] createService:@protocol(ModuleBService)];
//    [obj moduleBMethod];
    
    Class coreModule = NSClassFromString(@"ModuleCore");
    if (coreModule) {
        SEL instanceSEL = NSSelectorFromString(@"shareInstance");
        id sharedInstance = ((id(*)(id, SEL))[coreModule methodForSelector:instanceSEL])(coreModule,instanceSEL);
        SEL creator = NSSelectorFromString(@"createService:");
        id obj =  ((id (*)(id, SEL, Protocol*))[sharedInstance methodForSelector:creator])(sharedInstance, creator, NSProtocolFromString(@"ModuleBService"));
        SEL sel =  NSSelectorFromString(@"moduleBMethod");
        [obj performSelector:sel];
    }
    
//    id obj = [[ModuleCore shareInstance] createService:NSProtocolFromString(@"ModuleBService")];
//    SEL sel =  NSSelectorFromString(@"moduleBMethod");
//    [obj performSelector:sel];
}

@end
