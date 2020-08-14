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
        
        
    }
    return 0;
}
