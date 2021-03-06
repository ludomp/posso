/*
 Copyright (c) 2009, Rohan Pinto. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.
 
 Neither the name of the author nor the names of its contributors may be used
 to endorse or promote products derived from this software without specific
 prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 PossoAppDelegate.m
 POssO is a portable administration console for OpenSSO.
 
 POssO adds the much desired remote management feature to your corporate identity 
 management infrastructure, enabling you to achieve better efficiency and 
 accessibility in your organization. 
 Learn more about POssO on the http://posso.mobi site.
 */



#import "PossoAppDelegate.h"
#import "ConfigureViewController.h"
#import "LogsViewController.h"

static void uncaughtExceptionHandler(NSException *exception)
{
	twlog("uncaughtExceptionHandler caught a CRASH! -- %@", exception);
}

@implementation PossoAppDelegate

@synthesize window;
@synthesize tabBarController;
@synthesize tabBar;
@synthesize token;

#pragma mark -
#pragma mark Life cycle

- (void)applicationDidFinishLaunching:(UIApplication *)application
{
   (void)application;
   
   NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);

   [window addSubview:tabBarController.view];
   
   [self retrieveTokenID];
   
   // let's automatically go to configure (assume last tab) if needed
   if (!self.token.length)
      self.tabBarController.selectedIndex = self.tabBarController.viewControllers.count - 1;
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application;
{
   (void)application;
   twlog("applicationDidReceiveMemoryWarning!! -- no action");
}

- (void)applicationWillTerminate:(UIApplication *)application
{
	(void)application;
   
   [[NSUserDefaults standardUserDefaults] synchronize];
   
   [self logout];
}

- (void)dealloc
{
   self.tabBarController = nil;
   self.tabBar = nil;
   self.window = nil;
   self.token = nil;
   [super dealloc];
}

#pragma mark -
#pragma mark Application support

+ (PossoAppDelegate *)appDelegate
{
  return (PossoAppDelegate *)[[UIApplication sharedApplication] delegate];
}

- (NSString *)baseURL
{
   NSString *result = nil;
   
   BOOL validConfiguration = YES;
   
   NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
   NSString *scheme = [defaults boolForKey:kSavedUseSSL] ? @"https" : @"http";
   NSString *host = [defaults stringForKey:kSavedServerHost];
   validConfiguration &= 0 < host.length;
   NSString *port = [defaults stringForKey:kSavedServerPort];
   validConfiguration &= 0 < port.length;
   NSString *uri = [defaults stringForKey:kSavedServerURI];
   validConfiguration &= 0 < uri.length;
   
   if (validConfiguration)
   {
      result = [NSString
         stringWithFormat:@"%@://%@:%@/%@/identity",
         scheme,
         host,
         port,
         uri
      ];
   }
   
   return result;
}

- (void)retrieveTokenID
{
   [self logout];   
   
   BOOL validConfiguration = YES;
   
   NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
   NSString *login = [defaults stringForKey:kSavedLoginID];
   validConfiguration &= 0 < login.length;
   NSString *password = [defaults stringForKey:kSavedPassword];
   validConfiguration &= 0 < password.length;
   NSString *serverBase = self.baseURL;
   validConfiguration &= 0 < serverBase.length;
   twcheck(validConfiguration);

   NSString *tokenResult = nil;
   if (validConfiguration)
   {
      NSString *tokenURLString = [NSString
         stringWithFormat:@"%@/authenticate?username=%@&password=%@",
         serverBase,
         login,
         password
      ];
      //twlog("calling %@ for token", tokenURLString);

      NSError *error = nil;
      tokenResult = [NSString
         stringWithContentsOfURL:[NSURL URLWithString:tokenURLString]
         encoding:NSNonLossyASCIIStringEncoding
         error:&error
      ];
      twlogif(nil != error, "token getting FAIL: %@", error);
   }
   
   if (tokenResult)
   {
      self.token = tokenResult;
      // looks like our result is sent with a prefix
      if ([self.token hasPrefix:@"token.id="])
      {
         // note that there is apparently also a trailing CR!
         self.token = [[self.token substringFromIndex:9] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
      }

      // and it looks like stringByAddingPercentEscapesUsingEncoding isn't sufficient,
      // so we'll preprocess it here to remove '+' '/' and whatever other reserved characters might appear
      //twlog("receive token: %@", [PossoAppDelegate appDelegate].token);
      self.token = [(NSString *)CFURLCreateStringByAddingPercentEscapes(
         kCFAllocatorDefault, 
         (CFStringRef)self.token, 
         NULL, // escape all URL-illegal characters
         CFSTR(";/?:@&=+$,'"), // also escape URL-legal reserved characters
         kCFStringEncodingUTF8
     ) autorelease];
      
      //twlog("saved token: %@", [PossoAppDelegate appDelegate].token);
      [LogsViewController log:@"logged in"];
  }
   else
      [LogsViewController log:@"failed to log in"];
}

- (void)logout
{
   if (!self.token.length)
      return;

   BOOL validConfiguration = YES;
   NSString *serverBase = self.baseURL;
   validConfiguration &= 0 < serverBase.length;
   validConfiguration &= 0 < self.token.length;
   twcheck(validConfiguration);

   NSString *logoutURLString = [NSString
      stringWithFormat:@"%@/logout?subjectid=%@",
      serverBase,
      self.token
    ];

   // now we escape token on retrieval, including reserved but not illegal characters
   //logoutURLString = [logoutURLString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

   NSError *error = nil;
	NSString *logoutResult = [NSString
      stringWithContentsOfURL:[NSURL URLWithString:logoutURLString]
      encoding:NSNonLossyASCIIStringEncoding
      error:&error
   ];
   twlogif(nil != error, "logout getting FAIL: %@", error);
   // there's no result text returned by design
   (void)logoutResult;

   self.token = @"";
   
   [LogsViewController log:@"logged out"];
}

@end

