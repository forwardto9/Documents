//
//  ModuleA.h
//  ModuleA
//
//  Created by uweiyuan on 2020/8/12.
//  Copyright © 2020 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
//#import "ModuleCore.h"

@protocol ModuleAService <NSObject>

- (void)moduleAMethod;
- (NSString *)moduleAMethodWithRetVal:(id)x;

@end

@protocol ServiceProtocol;
@interface ModuleA : NSObject<ModuleAService, ServiceProtocol>
+ (instancetype)shareInstance;

@end
