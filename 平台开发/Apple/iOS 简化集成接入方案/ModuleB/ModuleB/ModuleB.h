//
//  ModuleB.h
//  ModuleB
//
//  Created by uweiyuan on 2020/8/12.
//  Copyright © 2020 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ModuleBService <NSObject>

- (void)moduleBMethod;

@end

@protocol ServiceProtocol;
@interface ModuleB : NSObject <ModuleBService, ServiceProtocol>
@end
