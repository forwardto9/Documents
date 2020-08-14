//
//  ModuleCore.m
//  ModuleCore
//
//  Created by uweiyuan on 2020/8/12.
//  Copyright © 2020 Tencent. All rights reserved.
//

#import "ServiceManager.h"
#import <objc/runtime.h>
#import <objc/message.h>

@implementation ServiceManager

+(void)load {
    NSLog(@"%s", __FUNCTION__);
}

+ (instancetype)shareInstance {
    static ServiceManager *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[ServiceManager alloc] init];
    });
    
    return instance;
}


- (NSMutableDictionary *)cps {
    if (!_cps) {
        _cps = [[NSMutableDictionary alloc] init];
    }
    return _cps;
}

- (void)registerService:(Protocol *)p withClass:(Class)cls {
    if ([cls conformsToProtocol:@protocol(ServiceProtocol)]) {
        [self.cps setObject:cls forKey:NSStringFromProtocol(p)];
    }
}

- (id)createService:(Protocol *)p {
    Class implClass =  [self.cps objectForKey:NSStringFromProtocol(p)];
    id implInstance = nil;
    if ([[implClass class] respondsToSelector:@selector(isSubModule)]) {
        if ([[implClass class] isSubModule]) {
            if ([[implClass class] respondsToSelector:@selector(shareInstance)])
                implInstance = [[implClass class] shareInstance];
            else
                implInstance = [[implClass alloc] init];
            return implInstance;
        }
    }
    return [[implClass alloc] init];
}


- (void)methodOfModuleA {
//    id <ModuleAService> obj = [self createService:@protocol(ModuleAService)];
//    [obj moduleAMethod];
    
    id obj = [[ServiceManager shareInstance] createService:NSProtocolFromString(@"ModuleAService")];
    
    SEL sel =  NSSelectorFromString(@"moduleAMethod");
    if ([obj respondsToSelector:sel]) {
        [obj performSelector:sel];
    }
}

- (void)methodOfModuleB {
//    id <ModuleBService> obj = [self createService:@protocol(ModuleBService)];
//    [obj moduleBMethod];
    
    id obj = [[ServiceManager shareInstance] createService:NSProtocolFromString(@"ModuleBService")];
    SEL sel = NSSelectorFromString(@"moduleBMethod");
    [obj performSelector:sel];
}

@end
