//
//  ModuleA.m
//  ModuleA
//
//  Created by uweiyuan on 2020/8/12.
//  Copyright © 2020 Tencent. All rights reserved.
//

#import "ModuleA.h"
#import "ServiceRouter.h"

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

    // 方式一，不引用
    Class serviceRouter = NSClassFromString(@"ServiceRouter");
    if (serviceRouter) {
        SEL instanceSEL = NSSelectorFromString(@"openURL:withData:completionHandler:");
        __unused BOOL sharedInstance = ((BOOL(*)(id, SEL, NSURL*, NSDictionary *, id))[serviceRouter methodForSelector:instanceSEL])(serviceRouter,instanceSEL,[NSURL URLWithString:@"tpns://call.service/ModuleB.ModuleBService.moduleBMethod"], nil, nil);
    }
    
    // 方式二，引用
    [ServiceRouter openURL:[NSURL URLWithString:@"tpns://call.service/ModuleB.ModuleBService.moduleBMethod"] withData:nil completionHandler:nil];
}

@end
