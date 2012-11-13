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
 ResetPasswordFormViewController.h
 POssO is a portable administration console for OpenSSO.
 
 POssO adds the much desired remote management feature to your corporate identity 
 management infrastructure, enabling you to achieve better efficiency and 
 accessibility in your organization. 
 Learn more about POssO on the http://posso.mobi site.
 */


#import <UIKit/UIKit.h>


@interface ResetPasswordFormViewController : UIViewController
{
   IBOutlet UILabel *userDescription;
   IBOutlet UIButton *sendButton;
   IBOutlet UIActivityIndicatorView *sendingIndicator;
   IBOutlet UILabel *resultLabel;
   IBOutlet UIButton *emailNotifyButton;
   IBOutlet UIButton *phoneNotifyButton;
   
   NSString *userInfoGivenName;
   NSString *userInfoCn;
   NSString *userInfoSn;
   NSString *userInfoEmail;
   NSString *userInfoPhone;

   NSString *newPassword;
   
   NSArray *passwordItems;
}

@property (nonatomic, retain) IBOutlet UILabel *userDescription;
@property (nonatomic, retain) IBOutlet UIButton *sendButton;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *sendingIndicator;
@property (nonatomic, retain) IBOutlet UILabel *resultLabel;
@property (nonatomic, retain) IBOutlet UIButton *emailNotifyButton;
@property (nonatomic, retain) IBOutlet UIButton *phoneNotifyButton;
@property (nonatomic, copy) NSString *userInfoGivenName;
@property (nonatomic, copy) NSString *userInfoCn;
@property (nonatomic, copy) NSString *userInfoSn;
@property (nonatomic, copy) NSString *userInfoEmail;
@property (nonatomic, copy) NSString *userInfoPhone;
@property (nonatomic, copy) NSString *newPassword;
@property (nonatomic, retain) NSArray *passwordItems;

// Life cycle

- (void)viewDidLoad;
- (void)didReceiveMemoryWarning;
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 30000
- (void)viewDidUnload;
- (void)setView:(UIView*)toView;
#endif __IPHONE_OS_VERSION_MIN_REQUIRED >= 30000
- (void)clearOutlets;
- (void)dealloc;

// Info management

- (void)retrieveInfo;
- (BOOL)parseInfo:(NSString *)info;

- (NSInteger)valueForSetting:(NSString *)setting;

- (void)createNewPassword;

- (BOOL)isPasswordValid:(NSString *)password;

// User actions

- (IBAction)sendPassword:(id)sender;

- (void)displayFailure;
- (void)displaySuccess;

- (IBAction)notifyEmail:(id)sender;
- (IBAction)notifyPhone:(id)sender;

@end
