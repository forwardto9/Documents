//
//  ServiceRouter.m
//  ModuleCore
//
//  Created by uweiyuan on 2020/8/13.
//  Copyright © 2020 Tencent. All rights reserved.
//

#import "ServiceRouter.h"
#import "ServiceManager.h"

@interface NSObject (TPNSReturnType)

+ (id)tpnsGetReturnFromInv:(NSInvocation *)inv withSig:(NSMethodSignature *)sig;

@end

@implementation NSObject (TPNSReturnType)

+ (id)tpnsGetReturnFromInv:(NSInvocation *)inv withSig:(NSMethodSignature *)sig {
    NSUInteger length = [sig methodReturnLength];
    if (length == 0) return nil;
    
    char *type = (char *)[sig methodReturnType];
    while (*type == 'r' || // const
           *type == 'n' || // in
           *type == 'N' || // inout
           *type == 'o' || // out
           *type == 'O' || // bycopy
           *type == 'R' || // byref
           *type == 'V') { // oneway
        type++; // cutoff useless prefix
    }
    
#define return_with_number(_type_) \
do { \
_type_ ret; \
[inv getReturnValue:&ret]; \
return @(ret); \
} while (0)
    
    switch (*type) {
        case 'v': return nil; // void
        case 'B': return_with_number(bool);
        case 'c': return_with_number(char);
        case 'C': return_with_number(unsigned char);
        case 's': return_with_number(short);
        case 'S': return_with_number(unsigned short);
        case 'i': return_with_number(int);
        case 'I': return_with_number(unsigned int);
        case 'l': return_with_number(int);
        case 'L': return_with_number(unsigned int);
        case 'q': return_with_number(long long);
        case 'Q': return_with_number(unsigned long long);
        case 'f': return_with_number(float);
        case 'd': return_with_number(double);
        case 'D': { // long double
            long double ret;
            [inv getReturnValue:&ret];
            return [NSNumber numberWithDouble:ret];
        };
            
        case '@': { // id
            id ret = nil;
            [inv getReturnValue:&ret];
            return ret;
        };
            
        case '#': { // Class
            Class ret = nil;
            [inv getReturnValue:&ret];
            return ret;
        };
            
        default: { // struct / union / SEL / void* / unknown
            const char *objCType = [sig methodReturnType];
            char *buf = calloc(1, length);
            if (!buf) return nil;
            [inv getReturnValue:buf];
            NSValue *value = [NSValue valueWithBytes:buf objCType:objCType];
            free(buf);
            return value;
        };
    }
#undef return_with_number
}

@end


@implementation ServiceRouter

+ (BOOL)canOpenURL:(NSURL *)url {
    if (!url) return NO;
    if (!url.scheme.length) return NO;
    if (!url.host.length) return NO;
    NSArray<NSString *> *pathComponents = url.pathComponents;
    if (!pathComponents.count) return NO;
    NSArray<NSString *> * subPaths = [pathComponents.lastObject componentsSeparatedByString:@"."];
    if (subPaths.count != 3) return NO;
    NSString *class = subPaths.firstObject;
    NSString *protocolStr = subPaths[1];
    NSString *selectorStr = subPaths.lastObject;
    Protocol *protocol = NSProtocolFromString(protocolStr);
    SEL selector = NSSelectorFromString(selectorStr);
    Class mClass = NSClassFromString(class);
    if (!protocol ||
        !selector ||
        ![mClass conformsToProtocol:@protocol(ServiceProtocol)] ||
        ![mClass conformsToProtocol:protocol] ||
        ![mClass instancesRespondToSelector:selector]) {
        return NO;
    }
    return YES;
}

+ (void)openURL:(NSURL *)url withData:(NSDictionary *)data completionHandler:(void (*)(id  _Nullable __strong, id  _Nullable __strong))handler {
    if (![self canOpenURL:url]) return;
    
    NSArray<NSString *> *pathComponents = url.pathComponents;
    NSArray<NSString *> * subPaths = [pathComponents.lastObject componentsSeparatedByString:@"."];
    NSString *protocolStr = subPaths[1];
    NSString *selectorStr = subPaths.lastObject;
    Protocol *protocol = NSProtocolFromString(protocolStr);
    SEL selector = NSSelectorFromString(selectorStr);
    id obj = [[ServiceManager shareInstance] createService:protocol];
    id returnValue = [self safePerformAction:selector forTarget:obj withParams:data];
    !handler?:handler(obj, returnValue);
}


+ (id)safePerformAction:(SEL)action
              forTarget:(NSObject *)target
             withParams:(NSDictionary *)params
{
    NSMethodSignature * sig = [target methodSignatureForSelector:action];
    if (!sig) { return nil; }
    NSInvocation *inv = [NSInvocation invocationWithMethodSignature:sig];
    if (!inv) { return nil; }
    [inv setTarget:target];
    [inv setSelector:action];
    NSArray<NSString *> *keys = params.allKeys;
    keys = [keys sortedArrayUsingComparator:^NSComparisonResult(NSString *  _Nonnull obj1, NSString *  _Nonnull obj2) {
        if (obj1.integerValue < obj2.integerValue) {
            return NSOrderedAscending;
        } else if (obj1.integerValue == obj2.integerValue) {
            return NSOrderedSame;
        } else {
            return NSOrderedDescending;
        }
    }];
    [keys enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        id value = params[obj];
        [inv setArgument:&value atIndex:idx+2];
    }];
    [inv invoke];
    return [NSObject tpnsGetReturnFromInv:inv withSig:sig];
}

@end
