//
//  TWDebugging.h
//  Trollwerks Library
//
//  Created by alex on 08/07/08.
//  Copyright 2008 Trollwerks Inc. All rights reserved.
//

#define likely(x)  __builtin_expect((x),1)
#define unlikely(x) __builtin_expect((x),0)

#ifdef DEBUG

#define DEBUG_ASSERT_PRODUCTION_CODE 0

// note for Objective-C only we could simplify like
// #define ALog(format, ...) NSLog(@"%s:%@", __PRETTY_FUNCTION__,[NSString stringWithFormat:format, ## __VA_ARGS__]);
// http://www.alexcurylo.com/blog/2009/04/17/snippet-debug-macros/

#define twlog TWLog
#define twlogif(assertion, ...) do { if (unlikely(assertion)) TWLog(__VA_ARGS__); } while (0)
#define twlogtouchset TWLogTouchSet
#define twmark	TWLog("MARK: %s", __PRETTY_FUNCTION__);  
#define twtimerstart NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate]
#define twtimerend(msg) NSTimeInterval stop = [NSDate timeIntervalSinceReferenceDate]; TWLog("%s -- time: %f", msg, stop-start)

#define twcheck(assertion)                          \
   do                                               \
   {                                                \
       if (unlikely(!(assertion)))                  \
       {                                            \
           TWFail(                                  \
               #assertion,                          \
               __PRETTY_FUNCTION__,                 \
               __FILE__,                            \
               __LINE__                             \
           );                                       \
       }                                            \
   } while (0)
#define twcheck_noerr(x) twcheck(0 == (x))

#else

#define twlog(...)
#define twlogif(...)
#define twlogtouchset(...)
#define twmark
#define twtimerstart
#define twtimerend(...)

#define twcheck(...)
#define twcheck_noerr(x) (void)(x)

#endif DEBUG

#define DEBUG_ASSERT_MESSAGE TWAssertMessage
#import <AssertMacros.h>

#pragma mark *** universal stderr logging

// see string format specifiers here
// http://developer.apple.com/DOCUMENTATION/Cocoa/Conceptual/Strings/Articles/formatSpecifiers.html

#ifdef __cplusplus
extern "C" {
#endif __cplusplus

// can be called transparently from .c/.cpp/.m/.mm files
void TWLog(const char* format, ...);
void TWFail(const char* assertion, const char* function, const char* filePath, int lineNumber);

// implements DEBUG_ASSERT_MESSAGE in AssertMacros.h
void TWAssertMessage(
   const char *componentNameString, 
   const char *assertionString, 
   const char *exceptionLabelString, 
   const char *errorString, 
   const char *fileName, 
   long lineNumber, 
   int errorCode
);

#ifdef __cplusplus
}
#endif __cplusplus

#pragma mark *** Cocoa/iPhone specific logging

#ifdef __OBJC__

#import <Foundation/Foundation.h>

#if TARGET_OS_IPHONE

#import <UIKit/UIKit.h>

void TWLogTouchSet(const char* action, NSSet* set, UIEvent* event);

#endif TARGET_OS_IPHONE

#endif __OBJC__
