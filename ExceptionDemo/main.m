//
//  main.m
//  ExceptionDemo
//
//  Created by didi on 2022/8/9.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import "TryCatch.h"

int main(int argc, char * argv[]) {
    NSString * appDelegateClassName;
    [TryCatch test];
    @autoreleasepool {
        // Setup code that might create autoreleased objects goes here.
        appDelegateClassName = NSStringFromClass([AppDelegate class]);
    }
    return UIApplicationMain(argc, argv, nil, appDelegateClassName);
}
