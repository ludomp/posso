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
 ResetPasswordFormViewController.m
 POssO is a portable administration console for OpenSSO.
 
 POssO adds the much desired remote management feature to your corporate identity 
 management infrastructure, enabling you to achieve better efficiency and 
 accessibility in your organization. 
 Learn more about POssO on the http://posso.mobi site.
 */


#import "ResetPasswordFormViewController.h"
#import "PossoAppDelegate.h"
#import "LogsViewController.h"
#import "EditRangeTableViewCell.h"

// note that these better match the definitions in passwordItems.plist

NSString *kPWMinLength = @"PWMinLength";
NSString *kPWMaxLength = @"PWMaxLength";
NSString *kPWMinUppercase = @"PWMinUppercase";
NSString *kPWMaxUppercase = @"PWMaxUppercase";
NSString *kPWMinLowercase = @"PWMinLowercase";
NSString *kPWMaxLowercase = @"PWMaxLowercase";
NSString *kPWMinNumerics = @"PWMinNumerics";
NSString *kPWMaxNumerics = @"PWMaxNumerics";
NSString *kPWSpecialsOn = @"PWSpecialsOn";

@implementation ResetPasswordFormViewController

@synthesize userDescription;
@synthesize sendButton;
@synthesize sendingIndicator;
@synthesize resultLabel;
@synthesize emailNotifyButton;
@synthesize phoneNotifyButton;
@synthesize userInfoGivenName;
@synthesize userInfoCn;
@synthesize userInfoSn;
@synthesize userInfoEmail;
@synthesize userInfoPhone;
@synthesize newPassword;
@synthesize passwordItems;

#pragma mark -
#pragma mark Life cycle

- (void)viewDidLoad
{
   [super viewDidLoad];

   self.passwordItems = [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"passwordItems" ofType:@"plist"]];

   [self retrieveInfo];
}

- (void)didReceiveMemoryWarning
{
   twlog("ResetPasswordFormViewController didReceiveMemoryWarning -- no action");
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
	self.userDescription = nil;
	self.sendButton = nil;
	self.sendingIndicator = nil;
	self.resultLabel = nil;
	self.emailNotifyButton = nil;
	self.phoneNotifyButton = nil;
 }

- (void)dealloc
{
   [self clearOutlets];
	self.userInfoGivenName = nil;
	self.userInfoCn = nil;
	self.userInfoSn = nil;
	self.userInfoEmail = nil;
	self.userInfoPhone = nil;
	self.newPassword = nil;
   self.passwordItems = nil;
   [super dealloc];
}

#pragma mark -
#pragma mark Info management

- (void)retrieveInfo
{
   // start a request
   self.sendingIndicator.startAnimating;
   
   BOOL validConfiguration = YES;
   NSString *serverBase = [PossoAppDelegate appDelegate].baseURL;
   validConfiguration &= 0 < serverBase.length;
   NSString *userToken = [PossoAppDelegate appDelegate].token;
   validConfiguration &= 0 < userToken.length;
   twcheck(validConfiguration);
   
   NSString *infoURLString = [NSString
      stringWithFormat:@"%@/read?&name=%@&attributes_names=objecttype&attributes_values_objecttype=user&admin=%@",
      serverBase,
      self.title, // note we assume creator will have set this
      userToken
   ];
   
	NSError* infoError = nil;
	NSString *infoResult = [NSString
      stringWithContentsOfURL:[NSURL URLWithString:infoURLString]
      encoding:NSNonLossyASCIIStringEncoding
      error:&infoError
   ];
   twlogif(nil != infoError, "info getting FAIL: %@", infoError);
   
   self.sendingIndicator.stopAnimating;
   if (!infoError && [self parseInfo:infoResult])
   {
      //"if CN exisis, display CN, if CN does not exist, then display givenname sn"
      if (self.userInfoCn.length)
         self.userDescription.text = self.userInfoCn;
      else if (self.userInfoGivenName.length || self.userInfoSn.length)
         self.userDescription.text = [NSString stringWithFormat:@"%@ %@", self.userInfoGivenName, self.userInfoSn];
      else
         self.userDescription.text = self.title;
      
      self.userDescription.hidden = NO;
      self.sendButton.hidden = NO; // not that ChangePassword overrides this
      
      [self createNewPassword];
   }
   else
   {
      twlog("EditUser info FAIL: %@", infoResult);
      self.resultLabel.text = @"Could not retrieve user info.";
      self.resultLabel.hidden = NO;
      [LogsViewController logWithFormat:@"retrieving user %@ info failed", self.title];
   }
}

- (BOOL)parseInfo:(NSString *)info
{
   if (!info || !info.length)
      return NO;
   if (0 != [info rangeOfString:@"Error report"].length)
      return NO;
   
   // expect a list of names and possible values on separate lines
   NSArray *lineArray = [info componentsSeparatedByString:@"\n"];
   if (2 > lineArray.count)
   {
      twlog("something odd about received info -- no line breaks!");
      return NO;
   }
   
   //twlog("user info to parse: %@", info);
   
   // and these are what we expect each line to start with
   NSString *userNamePrefix = @"identitydetails.name="; // first line 
   NSString *userTypePrefix = @"identitydetails.type="; // second line 
   NSString *userRealmPrefix = @"identitydetails.realm="; // third line 
   NSString *emptyLine = @"identitydetails.attribute="; // ignore
   NSString *namePrefix = @"identitydetails.attribute.name="; // a possible heading, if value(s) follow
   NSString *valuePrefix = @"identitydetails.attribute.value="; // value(s) for the preceding heading
   
   // so we'll go through the lines and construct an array of dictionaries to populate the table with
   NSString *possibleHeading = nil;
   for (NSString *line in lineArray)
   {
      if (2 > line.length)
         continue; // trailing CR, we assume
      if ([emptyLine isEqual:line])
         continue; // instructions are to ignore
      
      if ([line hasPrefix:userNamePrefix])
         continue;
      if ([line hasPrefix:userTypePrefix])
         continue;
      if ([line hasPrefix:userRealmPrefix])
         continue;
      
      if ([line hasPrefix:namePrefix])
      {
         possibleHeading = [line stringByReplacingOccurrencesOfString:namePrefix withString:@""];
         continue;
      }
      
      if ([line hasPrefix:valuePrefix])
      {
         if (!possibleHeading)
            continue;
         
         NSString *rowValue = [line stringByReplacingOccurrencesOfString:valuePrefix withString:@""];
         
         if ([@"givenname" isEqual:possibleHeading])
            self.userInfoGivenName = rowValue;
         else if ([@"cn" isEqual:possibleHeading])
            self.userInfoCn = rowValue;
         else if ([@"sn" isEqual:possibleHeading])
            self.userInfoSn = rowValue;
         else if ([@"mail" isEqual:possibleHeading])
            self.userInfoEmail = rowValue;
         else if ([@"telephonenumber" isEqual:possibleHeading])
            self.userInfoPhone = rowValue;
         
         continue;
      }
      
      twlog("what is this line? -- %@", line);
   }
   
   return YES;
}

- (NSInteger)valueForSetting:(NSString *)setting
{
   NSInteger result = 0;
   
   NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
   if ([defaults objectForKey:setting])
   {
      result = [defaults integerForKey:setting];
      return result;
   }
   else
   {
      for (NSDictionary* dict in self.passwordItems)
      {
         NSString *settingsMinimum = [dict objectForKey:kSettingsItemMinimum];
         if ([settingsMinimum isEqual:setting])
         {
            result = [[dict objectForKey:kDefaultItemMinimum] intValue];
            return result;
         }
         
         NSString *settingsMaximum = [dict objectForKey:kSettingsItemMaximum];
         if ([settingsMaximum isEqual:setting])
         {
            result = [[dict objectForKey:kDefaultItemMaximum] intValue];
            return result;
         }
      }
   }
         
   twlog("couldn't get a value for %@", setting);
   return result;
}

- (void)createNewPassword
{
   srandom(time(NULL));
   
   NSInteger minLength = [self valueForSetting:kPWMinLength];
   NSInteger maxLength = [self valueForSetting:kPWMaxLength];
   NSInteger passwordLength = (((float)random() / RAND_MAX) * ( maxLength - minLength ) ) + minLength;
   if (passwordLength > maxLength)
      passwordLength = minLength;
 
   NSInteger minUppercase = [self valueForSetting:kPWMinUppercase];
   NSInteger maxUppercase = [self valueForSetting:kPWMaxUppercase];
   NSInteger minLowercase = [self valueForSetting:kPWMinLowercase];
   NSInteger maxLowercase = [self valueForSetting:kPWMaxLowercase];
   NSInteger minNumerics = [self valueForSetting:kPWMinNumerics];
   NSInteger maxNumerics = [self valueForSetting:kPWMaxNumerics];

   NSMutableString *tempString = [NSMutableString stringWithCapacity:passwordLength];
   NSInteger uppercaseLetters = 0;
   NSInteger lowercaseLetters = 0;
   NSInteger numerics = 0;
   for (NSInteger j = 0; j < passwordLength; j++ )
   {
      BOOL numericOK = (numerics < maxNumerics);
      BOOL uppercaseOK = (uppercaseLetters < maxUppercase);
      BOOL lowercaseOK = (lowercaseLetters < maxLowercase);
      if (numerics >= minNumerics)
         if ((uppercaseLetters < minUppercase) || (lowercaseLetters < minLowercase))
            numericOK = NO;
      if (uppercaseLetters >= minUppercase)
         if ((numerics < minNumerics) || (lowercaseLetters < minLowercase))
            uppercaseOK = NO;
      if (lowercaseLetters >= minLowercase)
         if ((numerics < minNumerics) || (uppercaseLetters < minUppercase))
            lowercaseOK = NO;
      
      char thisCharacter = random() % 62;
      if (numericOK && ((!uppercaseOK && !lowercaseOK) || (9 >= thisCharacter)))
      {
         thisCharacter = '0' + (thisCharacter % 10);
         numerics++;
      }
      else if (uppercaseOK && (!lowercaseOK || (35 >= thisCharacter)))
      {
         thisCharacter = 'A' + (thisCharacter % 26);
         uppercaseLetters++;
      }
      else if (lowercaseOK)
      {
         thisCharacter = 'a' + (thisCharacter % 26);
         lowercaseLetters++;
      }
      else
      {
         twlog("warning: password rules are apparently unsatisfiable!");
         thisCharacter = 'a' + (thisCharacter % 26);
         lowercaseLetters++;
      }
      [tempString appendFormat:@"%c", thisCharacter];
   }
   
   self.newPassword = tempString;
   twcheck([self isPasswordValid:self.newPassword]);
   twlog("generated password: %@", self.newPassword);
}

- (BOOL)isPasswordValid:(NSString *)password
{
   NSUInteger minLength = [self valueForSetting:kPWMinLength];
   if (password.length < minLength)
      return NO;
   NSUInteger maxLength = [self valueForSetting:kPWMaxLength];
   if (password.length > maxLength)
      return NO;
   
   NSInteger minUppercase = [self valueForSetting:kPWMinUppercase];
   NSInteger maxUppercase = [self valueForSetting:kPWMaxUppercase];
   NSInteger minLowercase = [self valueForSetting:kPWMinLowercase];
   NSInteger maxLowercase = [self valueForSetting:kPWMaxLowercase];
   NSInteger minNumerics = [self valueForSetting:kPWMinNumerics];
   NSInteger maxNumerics = [self valueForSetting:kPWMaxNumerics];
   BOOL specialsOn = 1 == [self valueForSetting:kPWSpecialsOn];
   NSCharacterSet *specials = [NSCharacterSet characterSetWithCharactersInString:@"!@#$%^&*(){}[]"];
   NSInteger uppercase = 0;
   NSInteger lowercase = 0;
   NSInteger numerics = 0;
   for (NSUInteger i = 0; i < password.length; i++)
   {
      unichar character = [password characterAtIndex:i];
      if ([[NSCharacterSet decimalDigitCharacterSet] characterIsMember:character])
         numerics++;
      else if ([[NSCharacterSet lowercaseLetterCharacterSet] characterIsMember:character])
         lowercase++;
      else if ([[NSCharacterSet uppercaseLetterCharacterSet] characterIsMember:character])
         uppercase++;
      else if (!specialsOn || ![specials characterIsMember:character])
         return NO;
   }

   if (uppercase < minUppercase)
      return NO;
   if (uppercase > maxUppercase)
      return NO;
   if (lowercase < minLowercase)
      return NO;
   if (lowercase > maxLowercase)
      return NO;
   if (numerics < minNumerics)
      return NO;
   if (numerics > maxNumerics)
      return NO;
   
   return YES;
}

#pragma mark -
#pragma mark User actions

- (IBAction)sendPassword:(id)sender
{
   (void)sender;

   BOOL validConfiguration = YES;
   NSString *serverBase = [PossoAppDelegate appDelegate].baseURL;
   validConfiguration &= 0 < serverBase.length;
   NSString *userToken = [PossoAppDelegate appDelegate].token;
   validConfiguration &= 0 < userToken.length;
   twcheck(validConfiguration);
   
   NSString *editURLString = [NSString
      stringWithFormat:@"%@/update?identity_name=%@&identity_attribute_names=userpassword&identity_attribute_values_userpassword=%@&admin=%@",
      serverBase,
      self.title,
      self.newPassword,
      userToken
   ];
   twlog("change/reset password: %@", editURLString);
      
	NSError* editError = nil;
	NSString *editResult = [NSString
      stringWithContentsOfURL:[NSURL URLWithString:editURLString]
      encoding:NSNonLossyASCIIStringEncoding
      error:&editError
   ];
   twlogif(nil != editError, "password change/reset FAIL: %@", editError);
   
   twlog("password change/reset result: %@", editResult);
   
   if (editError)
   {
      [self displayFailure];
   }
   else
   {
      [self displaySuccess];
      self.sendButton.enabled = NO;
      if (self.userInfoEmail.length)
         self.emailNotifyButton.hidden = NO;
      if (self.userInfoPhone.length)
         self.phoneNotifyButton.hidden = NO;
   }
   self.resultLabel.hidden = NO;
}

- (void)displayFailure
{
   self.resultLabel.text = @"Resetting password failed.";
   [LogsViewController logWithFormat:@"reset user %@ password failed", self.title];
}

- (void)displaySuccess
{
   self.resultLabel.text = @"Resetting password succeeded!";
   [LogsViewController logWithFormat:@"reset user %@ password", self.title];
}

// http://developer.apple.com/iphone/library/featuredarticles/iPhoneURLScheme_Reference/Introduction/Introduction.html

- (IBAction)notifyEmail:(id)sender
{
   (void)sender;
   
   NSString *emailBody =[NSString stringWithFormat:@"Hello %@,\nYour password for userid '%@' has been reset to '%@'.\n\nIn order to safeguard privacy and security, you are requested to change your password immediately.",
      self.userDescription.text,
      self.title,
      self.newPassword
   ];  
   NSString *emailPrefix = [NSString stringWithFormat:@"mailto:%@?subject=Password Reset Notification&body=", self.userInfoEmail];  
   NSString *mailtoString = [[emailPrefix stringByAppendingString:emailBody] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];  
      
   NSURL *url = [NSURL URLWithString:mailtoString];
   [[UIApplication sharedApplication] openURL:url];	
}

- (IBAction)notifyPhone:(id)sender
{
   (void)sender;

   NSString *phoneString =[NSString stringWithFormat:@"tel:%@", self.userInfoPhone];  
   NSURL *url = [[NSURL alloc] initWithString:phoneString];
   [[UIApplication sharedApplication] openURL:url];	
}

@end
