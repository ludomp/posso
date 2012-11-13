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
 CreateUsersViewController.h
 POssO is a portable administration console for OpenSSO.
 
 POssO adds the much desired remote management feature to your corporate identity 
 management infrastructure, enabling you to achieve better efficiency and 
 accessibility in your organization. 
 Learn more about POssO on the http://posso.mobi site.
 */


#import <UIKit/UIKit.h>

@interface CreateUsersViewController : UIViewController <UITextFieldDelegate>
{
   IBOutlet UITextField *userIDField;
   IBOutlet UIButton *createButton;
   IBOutlet UIActivityIndicatorView *creatingIndicator;
   IBOutlet UILabel *resultLabel;
   IBOutlet UIButton *editButton;
   
   NSString *editableUser;
}

@property (nonatomic, retain) IBOutlet UITextField *userIDField;
@property (nonatomic, retain) IBOutlet UIButton *createButton;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *creatingIndicator;
@property (nonatomic, retain) IBOutlet UILabel *resultLabel;
@property (nonatomic, retain) IBOutlet UIButton *editButton;
@property (nonatomic, copy) NSString *editableUser;

// Life cycle

- (void)viewDidLoad;
- (void)didReceiveMemoryWarning;
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 30000
- (void)viewDidUnload;
- (void)setView:(UIView*)toView;
#endif __IPHONE_OS_VERSION_MIN_REQUIRED >= 30000
- (void)clearOutlets;
- (void)dealloc;

// Text field support

- (BOOL)textFieldShouldReturn:(UITextField *)textField;
- (void)textFieldDidEndEditing:(UITextField *)textField;

- (IBAction)createUser:(id)sender;
- (IBAction)editUser:(id)sender;

@end