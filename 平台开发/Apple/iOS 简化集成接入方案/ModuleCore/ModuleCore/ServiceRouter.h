//
//  ServiceRouter.h
//  ModuleCore
//
//  Created by uweiyuan on 2020/8/13.
//  Copyright © 2020 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ServiceRouter : NSObject

// tpns://call.service/classname.protocolName.selector
+ (BOOL)canOpenURL:(nonnull NSURL *)url;
+ (void)openURL:(nonnull NSURL *)url withData:(nullable NSDictionary *)data completionHandler:(void (*_Nullable) ( id _Nullable target, id _Nullable returnValue))handler;

@end

