//
//  AppDelegate.m
//  iOSRunLoop
//
//  Created by uwei on 2020/6/2.
//  Copyright © 2020 TEG of Tencent. All rights reserved.
//

#import "AppDelegate.h"

@interface RunLoopSource : NSObject
{
    CFRunLoopSourceRef runLoopSource;
    NSMutableArray* commands;
}
 
- (id)init;
- (void)addToCurrentRunLoop;
- (void)invalidate;
 
// Handler method
- (void)sourceFired;
 
// Client interface for registering commands to process
- (void)addCommand:(NSInteger)command withData:(id)data;
- (void)fireAllCommandsOnRunLoop:(CFRunLoopRef)runloop;
 
@end

// These are the CFRunLoopSourceRef callback functions.
void RunLoopSourceScheduleRoutine (void *info, CFRunLoopRef rl, CFStringRef mode);
void RunLoopSourcePerformRoutine (void *info);
void RunLoopSourceCancelRoutine (void *info, CFRunLoopRef rl, CFStringRef mode);
 
// RunLoopContext is a container object used during registration of the input source.
@interface RunLoopContext : NSObject
{
    CFRunLoopRef        runLoop;
    RunLoopSource*        source;
}
@property (readonly) CFRunLoopRef runLoop;
@property (readonly) RunLoopSource* source;
 
- (id)initWithSource:(RunLoopSource*)src andLoop:(CFRunLoopRef)loop;
@end

@implementation RunLoopContext

- (id)initWithSource:(RunLoopSource*)src andLoop:(CFRunLoopRef)loop {
    NSLog(@"%s", __FUNCTION__);
    if (self = [super init]) {
        runLoop = loop;
        source = src;
    }
    
    return self;
}

- (CFRunLoopRef)runLoop {
    return runLoop;
}

- (RunLoopSource *)source {
    return  source;
}

@end
    
    // Scheduling a run loop source
void RunLoopSourceScheduleRoutine (void *info, CFRunLoopRef rl, CFStringRef mode)
{
    NSLog(@"%s", __FUNCTION__);
    RunLoopSource* obj = (__bridge RunLoopSource*)info;
    AppDelegate*   del = (AppDelegate *)[UIApplication sharedApplication].delegate;;
    RunLoopContext* theContext = [[RunLoopContext alloc] initWithSource:obj andLoop:rl];
 
    [del performSelectorOnMainThread:@selector(registerSource:)
                                withObject:theContext waitUntilDone:NO];
}

// Performing work in the input source
void RunLoopSourcePerformRoutine (void *info)
{
    NSLog(@"%s", __FUNCTION__);
    RunLoopSource*  obj = (__bridge RunLoopSource*)info;
    [obj sourceFired];
}

// Invalidating an input source
void RunLoopSourceCancelRoutine (void *info, CFRunLoopRef rl, CFStringRef mode)
{
    NSLog(@"%s", __FUNCTION__);
    RunLoopSource* obj = (__bridge RunLoopSource*)info;
    AppDelegate* del = (AppDelegate *)[UIApplication sharedApplication].delegate;
    RunLoopContext* theContext = [[RunLoopContext alloc] initWithSource:obj andLoop:rl];
 
    [del performSelectorOnMainThread:@selector(removeSource:)
                                withObject:theContext waitUntilDone:YES];
}

@implementation RunLoopSource

- (id)init
{
    CFRunLoopSourceContext    context = {0, (__bridge void *)(self), NULL, NULL, NULL, NULL, NULL,
                                        &RunLoopSourceScheduleRoutine,
                                        RunLoopSourceCancelRoutine,
                                        RunLoopSourcePerformRoutine};
 
    runLoopSource = CFRunLoopSourceCreate(NULL, 0, &context);
    commands = [[NSMutableArray alloc] init];
 
    return self;
}
 
- (void)addToCurrentRunLoop
{
    CFRunLoopRef runLoop = CFRunLoopGetCurrent();
    CFRunLoopAddSource(runLoop, runLoopSource, kCFRunLoopDefaultMode);
}

- (void)addCommand:(NSInteger)command withData:(id)data {
    [commands addObject:@(command)];
}

- (void)invalidate {
    CFRunLoopSourceInvalidate(runLoopSource);
}

- (void)fireCommandsOnRunLoop:(CFRunLoopRef)runloop
{
    CFRunLoopSourceSignal(runLoopSource);
    CFRunLoopWakeUp(runloop);
}

- (void)sourceFired {
    NSLog(@"%s", __FUNCTION__);
}

@end

@interface MyWorkerClass : NSObject<NSPortDelegate>
+(void)LaunchThreadWithPort:(id)inData;
- (BOOL)shouldExit;
@property (strong, nonatomic) NSPort *remotePort;
@end

@implementation MyWorkerClass

+(void)LaunchThreadWithPort:(id)inData
{
    // Set up the connection between this thread and the main thread.
    NSPort* distantPort = (NSPort*)inData;
 
    MyWorkerClass*  workerObj = [[self alloc] init];
    [workerObj sendCheckinMessage:distantPort];
 
    // Let the run loop process things.
    do
    {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
    while (![workerObj shouldExit]);
}

// Worker thread check-in method
- (void)sendCheckinMessage:(NSPort*)outPort
{
    // Retain and save the remote port for future use.
    [self setRemotePort:outPort];
 
    // Create and configure the worker thread port.
    NSPort* myPort = [NSMachPort port];
    [myPort setDelegate:self];
    [[NSRunLoop currentRunLoop] addPort:myPort forMode:NSDefaultRunLoopMode];
 
    // Create the check-in message.(macOS)
//    NSPortMessage* messageObj = [[NSPortMessage alloc] initWithSendPort:outPort receivePort:myPort components:nil];
//
//    if (messageObj)
//    {
//        // Finish configuring the message and send it immediately.
//        [messageObj setMsgId:setMsgid:kCheckinMessage];
//        [messageObj sendBeforeDate:[NSDate date]];
//    }
}

@end


@interface AppDelegate () <NSPortDelegate> {
    NSMutableArray *sourcesToPing;
}


@end

void myRunLoopObserver(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info) {
    NSLog(@"%s:%lu", __FUNCTION__, activity);
}

@implementation AppDelegate

- (void)registerSource:(RunLoopContext*)sourceInfo 
{
    NSLog(@"%s", __FUNCTION__);
    [sourcesToPing addObject:sourceInfo];
}
 
- (void)removeSource:(RunLoopContext*)sourceInfo
{
    NSLog(@"%s", __FUNCTION__);
    id    objToRemove = nil;
 
    for (RunLoopContext* context in sourcesToPing)
    {
        if ([context isEqual:sourceInfo])
        {
            objToRemove = context;
            break;
        }
    }
 
    if (objToRemove)
        [sourcesToPing removeObject:objToRemove];
}

- (void)threadMain
{
    // The application uses garbage collection, so no autorelease pool is needed.
    NSRunLoop* myRunLoop = [NSRunLoop currentRunLoop];
 
    // Create a run loop observer and attach it to the run loop.
    CFRunLoopObserverContext  context = {0, (__bridge void *)(self), NULL, NULL, NULL};
    CFRunLoopObserverRef    observer = CFRunLoopObserverCreate(kCFAllocatorDefault,
            kCFRunLoopAllActivities, YES, 0, &myRunLoopObserver, &context);
 
    if (observer)
    {
        CFRunLoopRef    cfLoop = [myRunLoop getCFRunLoop];
        CFRunLoopAddObserver(cfLoop, observer, kCFRunLoopDefaultMode);
    }
 
    // Create and schedule the timer.
    [NSTimer scheduledTimerWithTimeInterval:0.1 target:self
                selector:@selector(doFireTimer:) userInfo:nil repeats:YES];
 
    NSInteger    loopCount = 10;
    do
    {
        // Run the run loop 10 times to let the timer fire.
        [myRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        loopCount--;
    }
    while (loopCount);
}

- (void)doFireTimer:(NSTimer *)timer {
    NSLog(@"%s", __FUNCTION__);
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
//    [self threadMain];
    sourcesToPing = [NSMutableArray array];
    RunLoopSource *sr = [[RunLoopSource alloc] init];
    [sr addToCurrentRunLoop];
    
    [sr fireCommandsOnRunLoop:CFRunLoopGetCurrent()];
    return YES;
}


#pragma mark - UISceneSession lifecycle


- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}


- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions {
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
}



- (void)launchThread
{
    NSPort* myPort = [NSMachPort port];
    if (myPort)
    {
        // This class handles incoming port messages.
        [myPort setDelegate:self];
 
        // Install the port as an input source on the current run loop.
        [[NSRunLoop currentRunLoop] addPort:myPort forMode:NSDefaultRunLoopMode];
 
        // Detach the thread. Let the worker release the port.
        [NSThread detachNewThreadSelector:@selector(LaunchThreadWithPort:) toTarget:[MyWorkerClass class] withObject:myPort];
    }
}


#define kCheckinMessage 100

#pragma mark - NSMachPortDelegate
// Handle responses from the worker thread.(macOS)
- (void)handlePortMessage:(NSPortMessage *)portMessage
{
//    unsigned int message = [portMessage msgid];
//    NSPort* distantPort = nil;
// 
//    if (message == kCheckinMessage)
//    {
//        // Get the worker thread’s communications port.
//        distantPort = [portMessage sendPort];
// 
//        // Retain and save the worker port for later use.
//        [self storeDistantPort:distantPort];
//    }
//    else
//    {
//        // Handle other messages.
//    }
}

@end
