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
 LogsViewController.m
 POssO is a portable administration console for OpenSSO.
 
 POssO adds the much desired remote management feature to your corporate identity 
 management infrastructure, enabling you to achieve better efficiency and 
 accessibility in your organization. 
 Learn more about POssO on the http://posso.mobi site.
 */

#import "LogsViewController.h"
#import "PossoAppDelegate.h"

@implementation LogsViewController

@synthesize logTextView;
@synthesize uploadButton;
@synthesize eraseButton;

static NSMutableString *_sharedLog = nil;

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
   [super viewWillAppear:animated];
   
	logTextView.text = [LogsViewController sharedLog];
   [logTextView scrollRangeToVisible:NSMakeRange([logTextView.text length], 0)];
}

- (void)didReceiveMemoryWarning
{
   twlog("LogsViewController didReceiveMemoryWarning -- no action");
   [super didReceiveMemoryWarning];
}

#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 30000
- (void)viewDidUnload
{
	[self clearOutlets];
}

- (void)setView:(UIView*)toView
{
	if (!toView)
		[self clearOutlets];
	
	[super setView:toView];
}
#endif __IPHONE_OS_VERSION_MIN_REQUIRED >= 30000

- (void) clearOutlets
{
	self.logTextView = nil;
	self.uploadButton = nil;
	self.eraseButton = nil;
}

- (void)dealloc
{
   [self clearOutlets];
   [super dealloc];
}

#pragma mark -
#pragma mark Logging support

+ (NSMutableString *)sharedLog
{
   if (nil == _sharedLog)
      _sharedLog = [[NSMutableString alloc] init];
   return _sharedLog;
}

+ (void)log:(NSString *)string
{
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	//[dateFormatter setDateFormat:@"yyyyMMdd hhmmss a"];
	[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
   NSString *timeString = [dateFormatter stringFromDate:[NSDate date]];
   
   NSString *logline = [NSString stringWithFormat:@"%@: %@\n", timeString, string];
   
   [[LogsViewController sharedLog] appendString:logline];

   [dateFormatter release];

   // for the moment, we'll assume nothing is logged while visible.
}

+ (void)logWithFormat:(NSString *)format, ...
{
   va_list argList; 
   va_start(argList, format);
   
   NSString* logString = [[NSString alloc] initWithFormat:format arguments:argList];
   
   va_end(argList);

   [LogsViewController log:logString];

   [logString release];
}

- (IBAction)uploadLogs:(id)sender
{
   (void)sender;
   
   BOOL validConfiguration = YES;
   NSString *serverBase = [PossoAppDelegate appDelegate].baseURL;
   validConfiguration &= 0 < serverBase.length;
   NSString *userToken = [PossoAppDelegate appDelegate].token;
   validConfiguration &= 0 < userToken.length;
   twcheck(validConfiguration);
   
   NSString *logText = [logTextView.text stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

   NSString *uploadURLString = [NSString
      stringWithFormat:@"%@/log?appid=%@&subjectid=%@&logname=POssO&message=%@",
      serverBase,
      userToken,
      userToken,
      logText
   ];
   
	NSError* uploadError = nil;
	NSString *uploadResult = [NSString
      stringWithContentsOfURL:[NSURL URLWithString:uploadURLString]
      encoding:NSNonLossyASCIIStringEncoding
      error:&uploadError
   ];
   twlogif(nil != uploadError, "uploading FAIL: %@", uploadError);
   twlog("upload result: %@", uploadResult);
   
   if (!uploadError)
   {
      UIAlertView *alert = [[[UIAlertView alloc] 
         initWithTitle:@"Logs uploaded" 
         message:@"Logs successfully uploaded to server. Resetting local log cache."
         delegate:nil 
         cancelButtonTitle:@"OK" 
         otherButtonTitles:nil
      ] autorelease];
      [alert show];
      
      [self eraseLogs:nil];
   }
}

- (IBAction)eraseLogs:(id)sender
{
   if (nil == sender)
   {
      // assume we don't verify post-upload clear
      [self actionSheet:nil clickedButtonAtIndex:0];
      return;
   }

   // check to make sure!
   
   UIActionSheet *actionSheet = [[[UIActionSheet alloc]
      initWithTitle:@"Confirm Clear Log"
      delegate:self
      cancelButtonTitle:@"Cancel"
      destructiveButtonTitle:@"Clear Log"
      otherButtonTitles:nil
   ] autorelease];
   [actionSheet showFromTabBar:[PossoAppDelegate appDelegate].tabBar];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
   if (actionSheet)
      if (actionSheet.destructiveButtonIndex != buttonIndex)
         return;

   // alrighty, they ok'd it (or it was automatic after upload)

   [_sharedLog release];
   _sharedLog = nil;
   logTextView.text = @"";
}

@end
