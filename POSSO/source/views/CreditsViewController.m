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
 CreditsViewController.m
 POssO is a portable administration console for OpenSSO.
 
 POssO adds the much desired remote management feature to your corporate identity 
 management infrastructure, enabling you to achieve better efficiency and 
 accessibility in your organization. 
 Learn more about POssO on the http://posso.mobi site.
 */


#import "CreditsViewController.h"

@implementation CreditsViewController

@synthesize creditsTable;
@synthesize applicationItems;
@synthesize peopleItems;

#pragma mark -
#pragma mark Fields in item description plists

NSString *kCreditCellText = @"text";
NSString *kCreditCellURL = @"url";
NSString *kCreditCellHeight = @"height";
NSString *kCreditCellImage = @"image";

#pragma mark -
#pragma mark Life cycle

- (void)viewDidLoad
{
   [super viewDidLoad];
   
   self.creditsTable.backgroundColor = [UIColor clearColor];
   
   self.applicationItems = [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"applicationItems" ofType:@"plist"]];
   self.peopleItems = [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"peopleItems" ofType:@"plist"]];
}

- (void)didReceiveMemoryWarning
{
   twlog("CreditsViewController didReceiveMemoryWarning -- no action");
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
   self.creditsTable = nil;
}

- (void)dealloc
{
   [self clearOutlets];
   self.applicationItems = nil;
   self.peopleItems = nil;
   [super dealloc];
}

#pragma mark -
#pragma mark Table support

- (NSDictionary *)itemInfoAtIndexPath:(NSIndexPath *)indexPath
{
   NSDictionary *itemInfo = nil;
   switch (indexPath.section)
   {
      case kCreditsSection_Application:
         itemInfo = [self.applicationItems objectAtIndex:indexPath.row];
         break;
      case kCreditsSection_People:
         itemInfo = [self.peopleItems objectAtIndex:indexPath.row];
         break;
      default:
         twlog("what CreditsViewController section is %i?", indexPath.section);
         break;
   }

   return itemInfo;
}

- (UIImage *)creditsImageFor:(NSString *)person;
{
   UIImage *creditsImage = nil;
   
   NSArray *nameComponents = [person componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
   twlogif(2 != nameComponents.count, "name parsing for image isn't working for '%@'", person);
   NSString *imagePath = [NSString stringWithFormat:@"credits/%@_%@.png",
      [nameComponents objectAtIndex:0],
      [nameComponents lastObject]
   ];
   creditsImage = [UIImage imageNamed:imagePath];
   twlogif(!creditsImage, "FAIL: expected image at '%@'!", imagePath);

   return creditsImage;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	(void)tableView;
   return kCreditsSectionCount;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section;
{
	(void)tableView;
	
   switch (section)
   {
      case kCreditsSection_Application:
         return @"About POssO";
      case kCreditsSection_People:
         return @"Credits";
      default:
         twlog("what CreditsViewController section is %i?", section);
         return @"";
   }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
   (void)tableView;
   
   switch (section)
   {
      case kCreditsSection_Application:
         return self.applicationItems.count;
      case kCreditsSection_People:
         return self.peopleItems.count;
      default:
         twlog("what CreditsViewController section is %i?", section);
         return 0;
   }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;
{
   (void)tableView;
   
   CGFloat height = 44.; // as standard in xib
   NSDictionary *itemInfo = [self itemInfoAtIndexPath:indexPath];
   NSString *heightString = [itemInfo objectForKey:kCreditCellHeight];
   if (nil != heightString)
      height = [heightString floatValue];
   
   return height;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
   static NSString *CreditsCellIdentifier = @"Credits";
   
   UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CreditsCellIdentifier];
   if (cell == nil)
      cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:CreditsCellIdentifier] autorelease];
	
   cell.selectionStyle = UITableViewCellSelectionStyleNone;
   NSDictionary *itemInfo = [self itemInfoAtIndexPath:indexPath];
   if (nil == itemInfo)
   {
      cell.accessoryType = UITableViewCellAccessoryNone;
      cell.text = @"fix me";
   }
   else 
   {
      cell.text = [itemInfo objectForKey:kCreditCellText];

      if (nil != [itemInfo objectForKey:kCreditCellURL])
      {
         if (kCreditsSection_People == indexPath.section)
            cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
         else
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
      }
      else
         cell.accessoryType = UITableViewCellAccessoryNone;
      
      NSString *iconFile = [itemInfo objectForKey:kCreditCellImage];
      if (nil != iconFile)
         cell.image = [UIImage imageNamed:iconFile];
      else if (kCreditsSection_People == indexPath.section)
         cell.image = [self creditsImageFor:cell.text];
      else
         cell.image = nil;
   }
   
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[self tableView:tableView accessoryButtonTappedForRowWithIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
 	(void)tableView;

   NSDictionary *itemInfo = [self itemInfoAtIndexPath:indexPath];
   NSString *urlString = [itemInfo objectForKey:kCreditCellURL];
   if (urlString)
      [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
}

@end
