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
 EditRangeTableViewCell.m
 POssO is a portable administration console for OpenSSO.
 
 POssO adds the much desired remote management feature to your corporate identity 
 management infrastructure, enabling you to achieve better efficiency and 
 accessibility in your organization. 
 Learn more about POssO on the http://posso.mobi site.
 */



#import "EditRangeTableViewCell.h"
#import "EditUserViewController.h"
#import "PossoAppDelegate.h"
#import "LogsViewController.h"

// https://developer.apple.com/webapps/docs/documentation/AppleApplications/Reference/SafariWebContent/DesigningForms/DesigningForms.html
//const int kPortraitKeyboardOffset = 216 - 49; 

NSString* kRangeItemText = @"text";
NSString* kDefaultItemMinimum = @"min";
NSString* kDefaultItemMaximum = @"max";
NSString* kSettingsItemMinimum = @"minSetting";
NSString* kSettingsItemMaximum = @"maxSetting";
const int kOnOrOff = -1; // for default minimum

const int kLabelWidth = 150;
const int kLabelInset = 5;
const int kRangeFieldWidth = 40;
const int kToLabelWidth = 25;

@implementation EditRangeTableViewCell

@synthesize label;
@synthesize minimumValue;
@synthesize toLabel;
@synthesize maximumValue;
@synthesize valueSwitch;
@synthesize itemInfo;

#pragma mark -
#pragma mark Life cycle

- (id)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier
{
    if ( (self = [super initWithFrame:frame reuseIdentifier:reuseIdentifier]) )
    {
       self.selectionStyle = UITableViewCellSelectionStyleNone;

       self.label = [[[UILabel alloc] initWithFrame:CGRectMake(kLabelInset, 7, kLabelWidth, 28)] autorelease];
       self.label.font = [UIFont boldSystemFontOfSize:20];
       //self.label.backgroundColor = [UIColor redColor];
       self.label.adjustsFontSizeToFitWidth = YES; 
       self.label.minimumFontSize = 8;
       [self.contentView addSubview:self.label];
   }
   return self;
}

- (void)dealloc
{
	self.label = nil;
	self.minimumValue = nil;
	self.toLabel = nil;
	self.maximumValue = nil;
	self.valueSwitch = nil;
	self.itemInfo = nil;
   [super dealloc];
}
   
#pragma mark -
#pragma mark Editability management
   
- (void)setItemInfo:(NSDictionary *)newInfo
{
   NSDictionary *oldInfo = itemInfo;
   itemInfo = [newInfo retain];
   [oldInfo release];
   if (!newInfo) // deallocating, presumably
      return;
   
   self.label.text = [itemInfo objectForKey:kRangeItemText];
   
   NSInteger defaultMinimum = [[newInfo objectForKey:kDefaultItemMinimum] intValue];
   NSInteger defaultMaximum = [[newInfo objectForKey:kDefaultItemMaximum] intValue];
   
   NSString *settingsMinimum = [newInfo objectForKey:kSettingsItemMinimum];
   NSString *settingsMaximum = [newInfo objectForKey:kSettingsItemMaximum];
   NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
   NSInteger currentMinimum = defaultMinimum;
   if (settingsMinimum && [defaults objectForKey:settingsMinimum])
      currentMinimum = [defaults integerForKey:settingsMinimum];
   NSInteger currentMaximum = defaultMaximum;
   if (settingsMaximum && [defaults objectForKey:settingsMaximum])
      currentMaximum = [defaults integerForKey:settingsMaximum];

   if (kOnOrOff == defaultMinimum)
   {
      // note 94 x 27 is system enforced size (as of 2.2.1...)
      self.valueSwitch = [[[UISwitch alloc] initWithFrame:CGRectMake(kLabelWidth + kLabelInset + 3, 8, 94, 27)] autorelease];
      self.valueSwitch.on = currentMaximum;
      [self.valueSwitch addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
      [self.contentView addSubview:self.valueSwitch];
   }
   else
   {
      self.minimumValue = [[[UITextField alloc] initWithFrame:CGRectMake(kLabelWidth + kLabelInset, 9, kRangeFieldWidth, 28)] autorelease];
      self.minimumValue.font = [UIFont systemFontOfSize:20];
      //self.minimumValue.backgroundColor = [UIColor greenColor];
      self.minimumValue.textColor = [UIColor colorWithRed:0.192157 green:0.309804 blue:0.521569 alpha:1.0];
      self.minimumValue.textAlignment = UITextAlignmentCenter; 
      self.minimumValue.text = [NSString stringWithFormat:@"%i", currentMinimum]; 
      self.minimumValue.delegate = self; 
      [self.contentView addSubview:self.minimumValue];

      self.toLabel = [[[UILabel alloc] initWithFrame:CGRectMake(kLabelWidth + kLabelInset + kRangeFieldWidth, 7, kToLabelWidth, 28)] autorelease];
      self.toLabel.font = [UIFont boldSystemFontOfSize:20];
      //self.toLabel.backgroundColor = [UIColor blueColor];
      self.toLabel.textAlignment = UITextAlignmentCenter; 
      self.toLabel.text = @"to"; 
      [self.contentView addSubview:self.toLabel];
      
      self.maximumValue = [[[UITextField alloc] initWithFrame:CGRectMake(kLabelWidth + kLabelInset + kRangeFieldWidth + kToLabelWidth, 9, kRangeFieldWidth, 28)] autorelease];
      self.maximumValue.font = [UIFont systemFontOfSize:20];
      //self.maximumValue.backgroundColor = [UIColor orangeColor];
      self.maximumValue.textColor = [UIColor colorWithRed:0.192157 green:0.309804 blue:0.521569 alpha:1.0];
      self.maximumValue.textAlignment = UITextAlignmentCenter; 
      self.maximumValue.text = [NSString stringWithFormat:@"%i", currentMaximum]; 
      self.maximumValue.delegate = self; 
      [self.contentView addSubview:self.maximumValue];
   }
}

- (IBAction)switchChanged:(id)sender
{
   NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
   NSString *settingsMaximum = [self.itemInfo objectForKey:kSettingsItemMaximum];
   NSInteger newValue = [sender isOn];
   [defaults setInteger:newValue forKey:settingsMaximum];
   [defaults synchronize];
}

#pragma mark -
#pragma mark Picking support

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
   (void)textField;
   
   editingMinimum = (self.minimumValue == textField);
   
   UIActionSheet *menuSheet = [[[UIActionSheet alloc]
      initWithTitle:nil
      delegate:self
      cancelButtonTitle:@"Done"
      destructiveButtonTitle:nil
      otherButtonTitles:nil
   ] autorelease];
   // note 320 x 216 is system enforced size (as of 2.2.1...)
   UIPickerView *pickerView = [[[UIPickerView alloc] initWithFrame:CGRectMake(0, 84, 320, 216)] autorelease];
   pickerView.dataSource = self;
   pickerView.delegate = self;
   pickerView.showsSelectionIndicator = YES;
   [pickerView selectRow:([textField.text intValue] - 1) inComponent:0 animated:NO]; 
   [menuSheet addSubview:pickerView];
   [menuSheet showFromTabBar:[PossoAppDelegate appDelegate].tabBar];
   [menuSheet setBounds:CGRectMake(0, 0, 320, 510)];
 
   // scroll if needed to show editing cell
   
   UITableView *owner = (UITableView *)self.superview;
   NSIndexPath *ourPath = [owner indexPathForCell:self];
   CGRect ourFrame = [owner rectForRowAtIndexPath:ourPath];
   editScrollOffset = CGRectGetMaxY(ourFrame) - 97; // eyeballed from resource
   if (editScrollOffset > 0)
   {
      CGRect viewFrame = owner.frame;
      viewFrame.origin.y -= editScrollOffset;
      [UIView beginAnimations:nil context:NULL];
      [UIView setAnimationBeginsFromCurrentState:YES];
      [UIView setAnimationDuration:0.3];
      [owner setFrame:viewFrame];
      [UIView commitAnimations];
   }
   
   return NO;
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
   (void)actionSheet;
   (void)buttonIndex;
   
   NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
   if (editingMinimum)
   {
      NSString *settingsMinimum = [self.itemInfo objectForKey:kSettingsItemMinimum];
      [defaults setInteger:[self.minimumValue.text intValue] forKey:settingsMinimum];
   }
   else
   {
      NSString *settingsMaximum = [self.itemInfo objectForKey:kSettingsItemMaximum];
      [defaults setInteger:[self.maximumValue.text intValue] forKey:settingsMaximum];
   }
   [defaults synchronize];
   
   // reverse scroll if any
   
   if (editScrollOffset > 0)
   {
      UITableView *owner = (UITableView *)self.superview;
      CGRect viewFrame = owner.frame;
      viewFrame.origin.y += editScrollOffset;
      [UIView beginAnimations:nil context:NULL];
      [UIView setAnimationBeginsFromCurrentState:YES];
      [UIView setAnimationDuration:0.3];
      [owner setFrame:viewFrame];
      [UIView commitAnimations];
   }
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
   (void)pickerView;
   return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
   (void)pickerView;
   (void)component;
   
   return 24;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
   (void)pickerView;
   (void)component;
   
   return [NSString stringWithFormat:@"%s %i characters", (editingMinimum ? "Minimum" : "Maximum"), row + 1];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
   (void)pickerView;
   (void)component;
   
   UITextField *editingField = editingMinimum ? self.minimumValue : self.maximumValue;
   editingField.text = [NSString stringWithFormat:@"%i", row + 1];
}

/*
- (void)textFieldDidBeginEditing:(UITextField *)textField
{
   //self.previousText = textField.text;

    // we'll always scroll to editing cell at top of keyboard
   // by moving cell to table bottom and table to top of keyboard
   UITableView *owner = (UITableView *)self.superview;
   CGRect smallFrame = owner.frame;
   smallFrame.size.height -= kPortraitKeyboardOffset;
   [UIView beginAnimations:nil context:NULL];
   [UIView setAnimationDuration:0.3];
   [owner setFrame:smallFrame];
   [UIView commitAnimations];
*/
/*
 NSIndexPath *ourPath = [owner indexPathForCell:self];
	[owner scrollToRowAtIndexPath:ourPath atScrollPosition:UITableViewScrollPositionBottom animated:NO];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
 */
  /* // reset table size, which will scroll or not as needed
   UITableView *owner = (UITableView *)self.superview;
   CGRect normalFrame = owner.frame;
   normalFrame.size.height += kPortraitKeyboardOffset;
   [UIView beginAnimations:nil context:NULL];
   [UIView setAnimationDuration:0.3];
   [owner setFrame:normalFrame];
   [UIView commitAnimations];
*/
   /*
    if ([textField.text isEqual:self.previousText])
      return;

   // we'll treat empty as cancel for now
   if (!textField.text.length)
   {
      textField.text = self.previousText;
      return;
   }
   
   // sort out what was changed
   
   EditUserViewController *ourController = (EditUserViewController *)owner.delegate;
   twcheck([ourController isKindOfClass:[EditUserViewController class]]);
   NSIndexPath *ourPath = [owner indexPathForCell:self];
   NSString *userID = ourController.navigationItem.title;
   NSDictionary *sectionInfo = [ourController.lastRetrievedInfo objectAtIndex:ourPath.section];
   NSString *sectionTitle = [sectionInfo objectForKey:kEditUserSectionName];
   NSString *newValue = textField.text;

   // account for comma separated fields displayed on separate rows
   NSArray *sectionValues = [sectionInfo objectForKey:kEditUserSectionValue];
   if (1 < sectionValues.count)
   {
      NSString *oldValue = [sectionValues componentsJoinedByString:@","];
      // note assumption that the old value of this field will be a unique string
      // should that be false, ourPath.row tells us the exact array index to substitute
      newValue = [oldValue stringByReplacingOccurrencesOfString:self.previousText withString:textField.text];
   }
   
   twlog("for user %@", userID);
   twlog("in section %@", sectionTitle);
   twlog("edit to new value %@!", newValue);
     
   // save edits to server

   BOOL validConfiguration = YES;
   NSString *serverBase = [PossoAppDelegate appDelegate].baseURL;
   validConfiguration &= 0 < serverBase.length;
   NSString *userToken = [PossoAppDelegate appDelegate].token;
   validConfiguration &= 0 < userToken.length;
   twcheck(validConfiguration);
   
   NSString *editURLString = [NSString
      stringWithFormat:@"%@/update?identity_name=%@&identity_attribute_names=%@&identity_attribute_values_%@=%@&admin=%@",
      serverBase,
      userID,
      sectionTitle, 
      sectionTitle,
      [newValue stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
      userToken
   ];
   twlog("editing: %@", editURLString);

   [LogsViewController logWithFormat:@"edited user %@ field %@ to %@", userID, sectionTitle, newValue];

	NSError* editError = nil;
	NSString *editResult = [NSString
      stringWithContentsOfURL:[NSURL URLWithString:editURLString]
      encoding:NSNonLossyASCIIStringEncoding
      error:&editError
   ];
   twlogif(nil != editError, "editing FAIL: %@", editError);
  
   twlog("edit result: %@", editResult);

   // make owner reload so we can see if edit took...
   
   [ourController retrieveInfo];
}
    */

@end
