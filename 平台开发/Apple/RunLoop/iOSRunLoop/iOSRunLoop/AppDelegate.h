//
//  AppDelegate.h
//  iOSRunLoop
//
//  Created by uwei on 2020/6/2.
//  Copyright © 2020 TEG of Tencent. All rights reserved.
//

#import <UIKit/UIKit.h>
@class RunLoopContext;
@interface AppDelegate : UIResponder <UIApplicationDelegate>

- (void)removeSource:(RunLoopContext*)sourceInfo;
- (void)registerSource:(RunLoopContext*)sourceInfo;
@end

