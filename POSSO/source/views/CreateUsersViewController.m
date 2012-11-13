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
 CreateUsersViewController.m
 POssO is a portable administration console for OpenSSO.
 
 POssO adds the much desired remote management feature to your corporate identity 
 management infrastructure, enabling you to achieve better efficiency and 
 accessibility in your organization. 
 Learn more about POssO on the http://posso.mobi site.
 */


#import "CreateUsersViewController.h"
#import "EditUserViewController.h"
#import "PossoAppDelegate.h"
#import "LogsViewController.h"

@implementation CreateUsersViewController

@synthesize userIDField;
@synthesize createButton;
@synthesize creatingIndicator;
@synthesize resultLabel;
@synthesize editButton;
@synthesize editableUser;

#pragma mark -
#pragma mark Life cycle

- (void)viewDidLoad
{
   [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
   twlog("CreateUsersViewController didReceiveMemoryWarning -- no action");
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
	self.userIDField = nil;
	self.createButton = nil;
	self.creatingIndicator = nil;
	self.resultLabel = nil;
	self.editButton = nil;
}

- (void)dealloc
{
   [self clearOutlets];
	self.editableUser = nil;
   [super dealloc];
}

#pragma mark -
#pragma mark Text field support

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
   [textField resignFirstResponder];
   return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
   BOOL hasText = 0 < textField.text.length;
   createButton.enabled = hasText;

   self.editableUser = textField.text;
   self.creatingIndicator.stopAnimating;
   self.editButton.hidden = YES;
   self.resultLabel.hidden = YES;
}

- (IBAction)createUser:(id)sender
{
   (void)sender;
   
   self.createButton.enabled = NO;
   self.creatingIndicator.startAnimating;

   BOOL validConfiguration = YES;
   NSString *serverBase = [PossoAppDelegate appDelegate].baseURL;
   validConfiguration &= 0 < serverBase.length;
   NSString *userToken = [PossoAppDelegate appDelegate].token;
   validConfiguration &= 0 < userToken.length;
   twcheck(validConfiguration);
   
   NSString *createURLString = [NSString
      stringWithFormat:@"%@/create?identity_name=%@&admin=%@",
      serverBase,
      self.editableUser,
      userToken
   ];
   twlog("creating new user with %@", createURLString);

	NSError* createError = nil;
	NSString *createResult = [NSString
      stringWithContentsOfURL:[NSURL URLWithString:createURLString]
      encoding:NSNonLossyASCIIStringEncoding
      error:&createError
   ];
   twlogif(nil != createError, "creating FAIL: %@", createError);
   twlog("create result %@", createResult);
   
   if (!createError)
   {
      NSString *verifyURLString = [NSString
         stringWithFormat:@"%@/read?name=%@&admin=%@",
         serverBase,
         self.editableUser,
         userToken
      ];
      twlog("verifying new user with %@", verifyURLString);

   	NSString *verifyResult = [NSString
        stringWithContentsOfURL:[NSURL URLWithString:verifyURLString]
        encoding:NSNonLossyASCIIStringEncoding
        error:&createError
      ];
      twlogif(nil != createError, "verifying FAIL: %@", createError);
      twlog("verify result %@", verifyResult);
   }
  
   self.creatingIndicator.stopAnimating;
   if (createError)
   {
      self.resultLabel.text = [NSString stringWithFormat:@"Sorry! The user '%@' could not be created.", self.editableUser];
      [LogsViewController logWithFormat:@"creating user %@ failed", self.editableUser];
   }
   else
   {
      self.resultLabel.text = [NSString stringWithFormat:@"New user '%@' successfully created!", self.editableUser];
      self.editButton.hidden = NO;
      [LogsViewController logWithFormat:@"created user %@", self.editableUser];
   }
   self.resultLabel.hidden = NO;
}

- (IBAction)editUser:(id)sender
{
   (void)sender;
   
   UIViewController *userViewController = [[EditUserViewController alloc] initWithNibName:@"EditUserView" bundle:nil];
   userViewController.title = self.editableUser;
	[self.navigationController pushViewController:userViewController animated:YES];
	[userViewController release];
}

@end
