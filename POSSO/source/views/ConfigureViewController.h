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
 ConfigureViewController.h
 POssO is a portable administration console for OpenSSO.
 
 POssO adds the much desired remote management feature to your corporate identity 
 management infrastructure, enabling you to achieve better efficiency and 
 accessibility in your organization. 
 Learn more about POssO on the http://posso.mobi site.
 */


#import <UIKit/UIKit.h>

extern NSString* kSavedServerHost;
extern NSString* kSavedServerPort;
extern NSString* kSavedServerURI;
extern NSString* kSavedLoginID;
extern NSString* kSavedPassword;
extern NSString* kSavedUseSSL;

@interface ConfigureViewController : UIViewController <UITextFieldDelegate>
{
   IBOutlet UITextField *serverHostField;
   IBOutlet UITextField *serverPortField;
   IBOutlet UITextField *serverURIField;
   IBOutlet UITextField *loginIDField;
   IBOutlet UITextField *passwordField;
   IBOutlet UISwitch *openSSLSwitch;
   IBOutlet UIButton *doneButton;
   IBOutlet UIButton *advancedButton;
}

@property (nonatomic, retain) IBOutlet UITextField *serverHostField;
@property (nonatomic, retain) IBOutlet UITextField *serverPortField;
@property (nonatomic, retain) IBOutlet UITextField *serverURIField;
@property (nonatomic, retain) IBOutlet UITextField *loginIDField;
@property (nonatomic, retain) IBOutlet UITextField *passwordField;
@property (nonatomic, retain) IBOutlet UISwitch *openSSLSwitch;
@property (nonatomic, retain) IBOutlet UIButton *doneButton;
@property (nonatomic, retain) IBOutlet UIButton *advancedButton;

// Life cycle

- (void)viewDidLoad;
- (void)didReceiveMemoryWarning;
- (void)viewWillAppear:(BOOL)animated;
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 30000
- (void)viewDidUnload;
- (void)setView:(UIView*)toView;
#endif __IPHONE_OS_VERSION_MIN_REQUIRED >= 30000
- (void)clearOutlets;
- (void)dealloc;

// Text field support

- (BOOL)textFieldShouldReturn:(UITextField *)textField;
- (void)textFieldDidBeginEditing:(UITextField *)textField;
- (void)textFieldDidEndEditing:(UITextField *)textField;

// Action support

- (IBAction)configureDone:(id)sender;

- (IBAction)advancedConfigure:(id)sender;

@end
