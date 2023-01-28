//
//  TryCatch.m
//  ExceptionDemo
//
//  Created by didi on 2023/1/28.
//

#import "TryCatch.h"
#include <string>
#include <exception>

@implementation TryCatch

+ (void)test {
    [self testOC];
    [self testCpp];
    [self testCatchAll];
}
+ (void)testCpp {
    
    try {
        std::string str = "test";
        char ch2 = str.at(100);  //下标越界，抛出异常
    } catch (std::exception e) {
        NSLog(@"testCpp: catch cpp exception = %s", e.what());
    }
}

+ (void)testOC {
    
    @try {
        NSObject *obj = [NSObject new];
        [obj performSelector:NSSelectorFromString(@"undefinedFunc")];
        
    } @catch (NSException *e) {
        NSLog(@"testOC: e = %@",e);
    } @finally {
            
    }
}

+ (void)testCatchAll {
    
    @try {
        
        std::string str = "test";
        char ch2 = str.at(100);  //下标越界，抛出异常

    } @catch (...) {
        
        NSLog(@"testCatchAll: catch cpp exception");
        
        @try {
            NSObject *obj = [NSObject new];
            [obj performSelector:NSSelectorFromString(@"undefinedFunc")];
        }@catch (...) {
            NSLog(@"testCatchAll: catch oc exception");
        }        
    } @finally {
            
    }
}
@end
