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

@interface ServiceManager ()

@property (nonatomic, strong) NSRecursiveLock *lock;

@end


@implementation ServiceManager

+(void)load {
    NSLog(@"%s", __FUNCTION__);
}

+ (instancetype)shareInstance {
    static ServiceManager *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!instance) {
            instance = [[ServiceManager alloc] init];
        }
        if (!instance.lock) {
            instance.lock = [[NSRecursiveLock alloc] init];
        }
        
    });
    
    return instance;
}

- (NSMutableDictionary *)cps {
    [self.lock lock];
    if (!_cps) {
        _cps = [[NSMutableDictionary alloc] init];
    }
    [self.lock unlock];
    return _cps;
}

- (void)registerService:(Protocol *)p withClass:(Class)cls {
    if ([cls conformsToProtocol:@protocol(ServiceProtocol)]) {
        [self.lock lock];
        [self.cps setObject:cls forKey:NSStringFromProtocol(p)];
        [self.lock unlock];
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
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [obj performSelector:sel];
        #pragma clang diagnostic pop
    }
}

@end
