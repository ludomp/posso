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
 AdvancedConfigureViewController.m
 POssO is a portable administration console for OpenSSO.
 
 POssO adds the much desired remote management feature to your corporate identity 
 management infrastructure, enabling you to achieve better efficiency and 
 accessibility in your organization. 
 Learn more about POssO on the http://posso.mobi site.
 */


#import "AdvancedConfigureViewController.h"
#import "LicenseViewController.h"
#import "EditRangeTableViewCell.h"

@implementation AdvancedConfigureViewController

@synthesize passwordTable;
@synthesize licenseButton;
@synthesize passwordItems;

#pragma mark -
#pragma mark Life cycle

- (void)viewDidLoad
{
   [super viewDidLoad];

   self.passwordTable.backgroundColor = [UIColor clearColor];
   
   self.passwordItems = [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"passwordItems" ofType:@"plist"]];
}

- (void)viewWillAppear:(BOOL)animated
{
   (void)animated;
}

- (void)didReceiveMemoryWarning
{
   twlog("AdvancedConfigureViewController didReceiveMemoryWarning -- no action");
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
   self.passwordTable = nil;
   self.licenseButton = nil;
}

- (void)dealloc
{
   [self clearOutlets];
   self.passwordItems = nil;
   [super dealloc];
}

#pragma mark -
#pragma mark Table support

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	(void)tableView;
   
   return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section;
{
	(void)tableView;
	(void)section;
   
   return @"Password Policy";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
   (void)tableView;
	(void)section;
	
   return self.passwordItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	(void)indexPath;

   static NSString *AdvancedCellIdentifier = @"AdvancedConfigure";
   
   EditRangeTableViewCell *cell = (EditRangeTableViewCell *)[tableView dequeueReusableCellWithIdentifier:AdvancedCellIdentifier];
   if (cell == nil)
      cell = [[[EditRangeTableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:AdvancedCellIdentifier] autorelease];
	
   cell.selectionStyle = UITableViewCellSelectionStyleNone;
   NSDictionary *itemInfo = [self.passwordItems objectAtIndex:indexPath.row];
   cell.itemInfo = itemInfo;
   
	return cell;
}

#pragma mark -
#pragma mark Action support

- (IBAction)showLicense:(id)sender
{
   (void)sender;

   UIViewController *licenseViewController = [[LicenseViewController alloc] initWithNibName:@"LicenseView" bundle:nil];
   licenseViewController.title = @"License";
	[self.navigationController pushViewController:licenseViewController animated:YES];
	[licenseViewController release];
}

@end
