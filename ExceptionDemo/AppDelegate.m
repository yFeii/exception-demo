//
//  AppDelegate.m
//  ExceptionDemo
//
//  Created by didi on 2022/8/9.
//

#import "AppDelegate.h"
#import <KSCrash/KSCrash.h>
#import <KSCrash/KSSignalInfo.h>
#import <KSCrash/KSCrashInstallationConsole.h>
#import <mach/host_priv.h>
#include "KSLogger.h"
#import "ExceptionHandler.h"
#import "TryCatch.h"
#import <objc/objc-exception.h>
@interface DDClass : NSObject

@property (nonatomic, weak) DDClass *wobj;
@property (nonatomic, strong) NSString *name;
@end

@implementation DDClass
- (void)dealloc {
    self.wobj = self;
}

@end
@interface AppDelegate ()

@end

@implementation AppDelegate


void mySignalHandler(int signal) {

    NSLog(@"##### signal = %d", signal);
    raise(signal);

}

static void handleSignal(int sigNum, siginfo_t* signalInfo, void* userContext)
{
    NSLog(@"#### Trapped signal %d", sigNum);
    // This is technically not allowed, but it works in OSX and iOS.
    raise(sigNum);
}



- (void)installSignal {
    // 信号量截断，当抛出信号时会回调 MySignalHandler 函数
    struct sigaction* __g_previousSignalHandlers = NULL;
    const int* fatalSignals = kssignal_fatalSignals();
    int fatalSignalsCount = kssignal_numFatalSignals();
    if(__g_previousSignalHandlers == NULL)
    {
        __g_previousSignalHandlers = malloc(sizeof(*__g_previousSignalHandlers)
                                          * (unsigned)fatalSignalsCount);
    }
    struct sigaction action = {{0}};
    action.sa_flags = SA_SIGINFO | SA_ONSTACK;
#if KSCRASH_HOST_APPLE && defined(__LP64__)
    action.sa_flags |= SA_64REGSET;
#endif
    sigemptyset(&action.sa_mask);
    action.sa_sigaction = &handleSignal;

    for(int i = 0; i < fatalSignalsCount; i++)
    {

        NSLog(@"#### Assigning handler for signal %d", fatalSignals[i]);
        if(sigaction(fatalSignals[i], &action, &__g_previousSignalHandlers[i]) != 0)
        {
            char sigNameBuff[30];
            const char* sigName = kssignal_signalName(fatalSignals[i]);
            if(sigName == NULL)
            {
                snprintf(sigNameBuff, sizeof(sigNameBuff), "%d", fatalSignals[i]);
                sigName = sigNameBuff;
            }
            NSLog(@"#### sigaction (%s): %s", sigName, strerror(errno));
            // Try to reverse the damage
            for(i--;i >= 0; i--)
            {
                sigaction(fatalSignals[i], &__g_previousSignalHandlers[i], NULL);
            }
        }
    }
    NSLog(@"#### Signal handlers installed.");
        
//    signal(SIGABRT, mySignalHandler);
//    signal(SIGILL, mySignalHandler);
//    signal(SIGSEGV, mySignalHandler);
//    signal(SIGFPE, mySignalHandler);
//    signal(SIGBUS, mySignalHandler);
//    signal(SIGPIPE, mySignalHandler);
}

extern void abort_with_reason(uint32_t reason_namespace, uint64_t reason_code, const char *reason_string, uint64_t reason_flags);

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    KSCrashInstallationConsole* installation = [KSCrashInstallationConsole sharedInstance];
    [installation install];
//    [[KSCrash sharedInstance] setMonitoring:KSCrashMonitorTypeAsyncSafe];
//    [self installSignal];
//    [ExceptionHandler catchMACHExceptions];
    sleep(2);//等待异常处理线程初始化
    [TryCatch test];

    {
        abort();
        //EXC_CRASH signalbrt
//        DDClass *o = [DDClass new];
        NSObject *obj = [NSObject new];
        [obj performSelector:NSSelectorFromString(@"fake")];
    }

    {
        //EXC_BAD_ACCESS
        NSLog(@"before sigsegv");
        int *a = NULL;
        *a = 0;
        NSLog(@"after sigsegv");
    }    
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


@end
