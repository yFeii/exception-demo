//
//  ExceptionHandler.m
//  ExceptionDemo
//
//  Created by didi on 2022/8/12.
//

#import "ExceptionHandler.h"
#include "mach_exc.h"
#import <pthread.h>
#import <mach/mach_init.h>
#import <mach/mach_port.h>
#import <mach/task.h>
#import <mach/message.h>
#import <mach/thread_act.h>
#import <mach/mach_host.h>

typedef union MachMessageTag {
  mach_msg_header_t hdr;
  char data[1024];
} MachMessage;

extern "C" boolean_t mach_exc_server(mach_msg_header_t *InHeadP, mach_msg_header_t *OutHeadP);

extern "C" kern_return_t  catch_mach_exception_raise_state(
        mach_port_t exc_port, exception_type_t exc_type, const mach_exception_data_t exc_data,
        mach_msg_type_number_t exc_data_count, int* flavor, const thread_state_t old_state,
        mach_msg_type_number_t old_stateCnt, thread_state_t new_state, mach_msg_type_number_t* new_stateCnt)
{
    NSLog(@"In catch_mach_exception_raise_state");
    return KERN_SUCCESS;
}

extern "C" kern_return_t catch_mach_exception_raise_state_identity(
        mach_port_t exc_port, mach_port_t thread_port, mach_port_t task_port,
        exception_type_t exc_type, mach_exception_data_t exc_data,
        mach_msg_type_number_t exc_data_count, int* flavor, thread_state_t old_state,
        mach_msg_type_number_t old_stateCnt, thread_state_t new_state, mach_msg_type_number_t *new_stateCnt)
{
    NSLog(@"In catch_mach_exception_raise_state_identity");
    return KERN_SUCCESS;
}


extern "C" kern_return_t catch_mach_exception_raise(
        mach_port_t exc_port, mach_port_t thread_port,
        mach_port_t task_port, exception_type_t exc_type,
        mach_exception_data_t exc_data, mach_msg_type_number_t exc_data_count)
{
    NSLog(@"In catch_mach_exception_raise");
    return KERN_SUCCESS;
}


/// 注册捕获异常的端口
// 自定义端口号
mach_port_name_t myExceptionPort = 10086;


/// 接收异常消息
static void *exc_handler(void *ignored) {
    // 结果

    mach_msg_return_t kr;
    // 内核将发送给我们的异常消息的格式，参考 ux_handler() [bsd / uxkern / ux_exception.c] 中对异常消息的定义
    
    // 消息处理循环，这里的死循环不会有问题，因为 exc_handler 函数运行在一个独立的子线程中，而且 mach_msg 函数也是会阻塞的。
    for (;;) {
        MachMessage exc_msg;
        MachMessage reply_msg;

        // 这里会阻塞，直到接收到 exception message，或者线程被中断
        kr = mach_msg(&exc_msg.hdr, MACH_RCV_MSG | MACH_RCV_LARGE, 0, sizeof(exc_msg.data), myExceptionPort, MACH_MSG_TIMEOUT_NONE, MACH_PORT_NULL);
        if (kr != MACH_MSG_SUCCESS) {
            //
            break;
        };
        NSLog(@"##### receive exception");
  
        
        /* Handle the message (calls catch_exception_raise) */
        // we should use mach_exc_server for 64bits
        if (mach_exc_server(&exc_msg.hdr, &reply_msg.hdr) != TRUE)
        {
            NSLog(@"mach_exc_server failde");
            return NULL;
        }
        typedef struct {
            mach_msg_header_t Head;
            NDR_record_t NDR;
            kern_return_t RetCode;
        }Reply;
        Reply *r = (Reply*)&reply_msg;
        r->RetCode = KERN_FAILURE;
        kr = mach_msg(&reply_msg.hdr, MACH_SEND_MSG,
                      reply_msg.hdr.msgh_size, 0, MACH_PORT_NULL,
                MACH_MSG_TIMEOUT_NONE, MACH_PORT_NULL);
        if (kr != MACH_MSG_SUCCESS)
        {
            NSLog(@"mach_msg repy failde");
            return NULL;
        }
    }
    
    return NULL;
}

@implementation ExceptionHandler

+ (void)catchMACHExceptions {
    // 用自定义端口号初始化一个端口
    mach_port_allocate(mach_task_self(), MACH_PORT_RIGHT_RECEIVE, &myExceptionPort);
    // 向端口插入发送权限
    mach_port_insert_right(mach_task_self(), myExceptionPort, myExceptionPort, MACH_MSG_TYPE_MAKE_SEND);
    // 设置 Mach 异常的种类
    exception_mask_t excMask = EXC_MASK_BAD_ACCESS | EXC_MASK_BAD_INSTRUCTION | EXC_MASK_ARITHMETIC | EXC_MASK_SOFTWARE;
    
    // 设置内核接收 Mach 异常消息的 thread Port
    thread_set_exception_ports(mach_thread_self(), excMask, myExceptionPort, EXCEPTION_DEFAULT | MACH_EXCEPTION_CODES, THREAD_STATE_NONE);
    // 新建一个线程处理异常消息
    pthread_t thread;
    pthread_create(&thread, NULL, exc_handler, NULL);
}

@end
