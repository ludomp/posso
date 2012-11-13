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
 ConfigureViewController.m
 POssO is a portable administration console for OpenSSO.
 
 POssO adds the much desired remote management feature to your corporate identity 
 management infrastructure, enabling you to achieve better efficiency and 
 accessibility in your organization. 
 Learn more about POssO on the http://posso.mobi site.
 */


#import "ConfigureViewController.h"
#import "PossoAppDelegate.h"
#import "AdvancedConfigureViewController.h"

NSString* kSavedServerHost = @"ServerHost";
NSString* kSavedServerPort = @"ServerPort";
NSString* kSavedServerURI = @"ServerURI";
NSString* kSavedLoginID = @"LoginID";
NSString* kSavedPassword = @"Password";
NSString* kSavedUseSSL = @"UseSSL";

NSString* kLogoutTitle = @"Logout";
NSString* kLoginTitle = @"Login";

const CGFloat kPasswordAnimationHeight = 35;
const CGFloat kPasswordAnimationDuration = 0.3;

/*
 
 Testing Account [ADMINISTRATORS]:
 
 Server Host: server.rohanpinto.com
 Server Port: 8080
 Server URI: opensso
 SSL off
 
 Login ID: amadmin
 Password: adminadmin
 
 */

@implementation ConfigureViewController

@synthesize serverHostField;
@synthesize serverPortField;
@synthesize serverURIField;
@synthesize loginIDField;
@synthesize passwordField;
@synthesize openSSLSwitch;
@synthesize doneButton;
@synthesize advancedButton;

#pragma mark -
#pragma mark Life cycle

- (void)viewDidLoad
 {
    [super viewDidLoad];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.serverHostField.text = [defaults stringForKey:kSavedServerHost];
    self.serverPortField.text = [defaults stringForKey:kSavedServerPort];
    self.serverURIField.text = [defaults stringForKey:kSavedServerURI];
    self.loginIDField.text = [defaults stringForKey:kSavedLoginID];
    self.passwordField.text = [defaults stringForKey:kSavedPassword];
    self.openSSLSwitch.on = [defaults boolForKey:kSavedUseSSL];
}

- (void)viewWillAppear:(BOOL)animated
{
   (void)animated;
   
   if ([PossoAppDelegate appDelegate].token.length)
      [doneButton setTitle:kLogoutTitle forState:UIControlStateNormal];
   else
      [doneButton setTitle:kLoginTitle forState:UIControlStateNormal];
}

- (void)didReceiveMemoryWarning
{
   twlog("ConfigureViewController didReceiveMemoryWarning -- no action");
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
	self.serverHostField = nil;
	self.serverPortField = nil;
	self.serverURIField = nil;
	self.loginIDField = nil;
	self.passwordField = nil;
	self.openSSLSwitch = nil;
	self.doneButton = nil;
	self.advancedButton = nil;
}

- (void)dealloc
{
   [self clearOutlets];
   [super dealloc];
}

#pragma mark -
#pragma mark Text field support

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
   [textField resignFirstResponder];

   UITextField *nextField = nil;
   if (self.serverHostField == textField)
      nextField = self.serverPortField;
   else if (self.serverPortField == textField)
      nextField = self.serverURIField;
   else if (self.serverURIField == textField)
      nextField = self.loginIDField;
   else if (self.loginIDField == textField)
      nextField = self.passwordField;
   
   if (nextField)
      [nextField becomeFirstResponder];
   else
      [self configureDone:textField];
   
   return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
   if (textField != self.passwordField)
      return;
   
   // animate it up to be visible
   
   CGRect viewFrame = self.view.frame;
   viewFrame.origin.y -= kPasswordAnimationHeight;
   [UIView beginAnimations:nil context:NULL];
   [UIView setAnimationBeginsFromCurrentState:YES];
   [UIView setAnimationDuration:0.3];
   [self.view setFrame:viewFrame];
   [UIView commitAnimations];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
   if (textField != self.passwordField)
      return;
   
   // reverse textFieldDidBeginEditing animation
   
   CGRect viewFrame = self.view.frame;
   viewFrame.origin.y += kPasswordAnimationHeight;
   [UIView beginAnimations:nil context:NULL];
   [UIView setAnimationBeginsFromCurrentState:YES];
   [UIView setAnimationDuration:kPasswordAnimationDuration];
   [self.view setFrame:viewFrame];
   [UIView commitAnimations];
}

#pragma mark -
#pragma mark Text field support

- (IBAction)configureDone:(id)sender
{
   (void)sender;

   NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
   [defaults setObject:self.serverHostField.text forKey:kSavedServerHost];
   [defaults setObject:self.serverPortField.text forKey:kSavedServerPort];
   [defaults setObject:self.serverURIField.text forKey:kSavedServerURI];
   [defaults setObject:self.loginIDField.text forKey:kSavedLoginID];
   [defaults setObject:self.passwordField.text forKey:kSavedPassword];
   [defaults setBool:self.openSSLSwitch.on forKey:kSavedUseSSL];
   
   [defaults synchronize];
   
   // fix button
   if ([kLogoutTitle isEqual:doneButton.currentTitle])
      [[PossoAppDelegate appDelegate] logout];
   else
      [[PossoAppDelegate appDelegate] retrieveTokenID];
   [self viewWillAppear:NO];
}

- (IBAction)advancedConfigure:(id)sender
{
   (void)sender;
   
   UIViewController *advancedViewController = [[AdvancedConfigureViewController alloc] initWithNibName:@"AdvancedConfigureView" bundle:nil];
   advancedViewController.title = @"Advanced Configuration";
	[self.navigationController pushViewController:advancedViewController animated:YES];
	[advancedViewController release];
}

@end
