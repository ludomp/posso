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
 ChangePasswordFormViewController.m
 POssO is a portable administration console for OpenSSO.
 
 POssO adds the much desired remote management feature to your corporate identity 
 management infrastructure, enabling you to achieve better efficiency and 
 accessibility in your organization. 
 Learn more about POssO on the http://posso.mobi site.
 */


#import "ChangePasswordFormViewController.h"
#import "LogsViewController.h"

@implementation ChangePasswordFormViewController

@synthesize newPassword1;
@synthesize newPassword2;

#pragma mark -
#pragma mark Life cycle

- (void) clearOutlets
{
   [super clearOutlets];
	self.newPassword1 = nil;
	self.newPassword1 = nil;
}

#pragma mark -
#pragma mark Info management

- (void)retrieveInfo
{
   [super retrieveInfo];
   self.sendButton.hidden = YES;
}

- (void)displayFailure
{
   self.resultLabel.text = @"Changing password failed.";
   [LogsViewController logWithFormat:@"change/reset user %@ password failed", self.title];
}

- (void)displaySuccess
{
   self.resultLabel.text = @"Changing password succeeded!";
   [LogsViewController logWithFormat:@"changed user %@ password", self.title];
}

#pragma mark -
#pragma mark Text field support

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
   BOOL result = YES;
   
   if (self.newPassword1 == textField)
   {
      if ([self isPasswordValid:self.newPassword1.text])
      {
         result = YES;
         [textField resignFirstResponder];
         [self.newPassword2 becomeFirstResponder];
      }
      else
      {
         result = NO;
         textField.text = @"";
         UIAlertView *alert = [[[UIAlertView alloc] 
            initWithTitle:@"" 
            message:@"Sorry, that is not a valid password."
            delegate:nil 
            cancelButtonTitle:@"OK" 
            otherButtonTitles:nil
         ] autorelease];
         [alert show];
      }
   }
   else
   {
      result = YES;
      [textField resignFirstResponder];
      [self checkPasswordsMatch];
   }
   
   return result;
}

- (void)checkPasswordsMatch
{
   if ([self.newPassword1.text isEqual:self.newPassword2.text])
   {
      self.newPassword = self.newPassword1.text;
      self.sendButton.hidden = NO;
   }
   else
   {
      self.newPassword = @"";
      self.sendButton.hidden = YES;
      
      UIAlertView *alert = [[[UIAlertView alloc] 
         initWithTitle:@"" 
         message:@"Those passwords do not match!"
         delegate:nil 
         cancelButtonTitle:@"OK" 
         otherButtonTitles:nil
      ] autorelease];
      [alert show];
   }
}

@end
