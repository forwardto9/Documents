//
//  ModuleCore.h
//  ModuleCore
//
//  Created by uweiyuan on 2020/8/12.
//  Copyright © 2020 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ServiceProtocol <NSObject>

+ (BOOL)isSubModule;
+ (id)shareInstance;

@end

@interface ServiceManager : NSObject

@property (nonatomic, strong) NSMutableDictionary *cps;

+ (instancetype)shareInstance;

- (void)registerService:(Protocol *)p withClass:(Class)cls;
- (id)createService:(Protocol *)p;


- (void)methodOfModuleA;

- (void)methodOfModuleB;


@end
