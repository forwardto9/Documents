//
//  main.m
//  Demo
//
//  Created by uweiyuan on 2020/8/12.
//  Copyright © 2020 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ServiceRouter.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // insert code here...
        NSLog(@"Hello, World!");
        
        NSURL *url = [NSURL URLWithString:@"tpns://call.service/classname.service_name.selector"];
        NSLog(@"%@\n, %@\n,%@\n, %@\n,%@\n, %@\n, %@\n, %@\n, %@\n, %@\n",
              url.scheme,
              url.user,
              url.password,
              url.host,
              url.port,
              url.path,
              url.pathExtension,
              url.pathComponents,
              url.query,
              url.fragment);
        
        
        [ServiceRouter openURL:[NSURL URLWithString:@"tpns://call.service/ModuleA.ModuleAService.moduleAMethod"] withData:nil completionHandler:nil];
        [ServiceRouter openURL:[NSURL URLWithString:@"tpns://call.service/ModuleA.ModuleAService.moduleAMethodWithRetVal:"] withData:@{@"key0":@"value0", @"key1":@"value1",@"key2":@"value2"} completionHandler:^(id  _Nullable target, id  _Nullable returnValue) {
            NSLog(@"%@----------------%@", target, returnValue);
        }];
        
    }
    [ServiceRouter openURL:[NSURL URLWithString:@"tpns://call.service/ModuleA.ModuleAService.moduleAMethodWithRetVal:"] withData:@{@"key0":@"value0", @"key1":@"value1",@"key2":@"value2"} completionHandler:^(id  _Nullable target, id  _Nullable returnValue) {
        NSLog(@"%@----------------%@", target, returnValue);
    }];
    
    return 0;
}
