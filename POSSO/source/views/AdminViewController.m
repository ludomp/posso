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
 AdminViewController.m
 POssO is a portable administration console for OpenSSO.
 
 POssO adds the much desired remote management feature to your corporate identity 
 management infrastructure, enabling you to achieve better efficiency and 
 accessibility in your organization. 
 Learn more about POssO on the http://posso.mobi site.
 */

#import "AdminViewController.h"

@implementation AdminViewController

@synthesize functionsTable;
@synthesize functionItems;

#pragma mark -
#pragma mark Fields in functiondescription plists

NSString *kFunctionCellText = @"text";
NSString *kFunctionCellView = @"view";

#pragma mark -
#pragma mark Life cycle

- (void)viewDidLoad
{
   [super viewDidLoad];
   
   self.functionsTable.backgroundColor = [UIColor clearColor];
   
   self.functionItems = [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"adminfunctions" ofType:@"plist"]];
}

- (void)viewWillAppear:(BOOL)animated
{
   [super viewWillAppear:animated];
   
	NSIndexPath *selection = [self.functionsTable indexPathForSelectedRow];
	if (selection)
		[self.functionsTable deselectRowAtIndexPath:selection animated:animated];
}

- (void)didReceiveMemoryWarning
{
   twlog("AdminViewController didReceiveMemoryWarning -- no action");
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
   self.functionsTable = nil;
}

- (void)dealloc
{
   [self clearOutlets];
   self.functionItems = nil;
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
	
   return @"Admin Functions";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
   (void)tableView;
 	(void)section;
  
   return self.functionItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
   static NSString *AdminCellIdentifier = @"Admin";
   
   UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:AdminCellIdentifier];
   if (cell == nil)
      cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:AdminCellIdentifier] autorelease];
	
   NSDictionary *itemInfo = [self.functionItems objectAtIndex:indexPath.row];
   cell.text = [itemInfo objectForKey:kFunctionCellText];
   if (nil != [itemInfo objectForKey:kFunctionCellView])
      cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
   else
      cell.accessoryType = UITableViewCellAccessoryNone;
   
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[self tableView:tableView accessoryButtonTappedForRowWithIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
 	(void)tableView;
   
   NSDictionary *itemInfo = [self.functionItems objectAtIndex:indexPath.row];
   NSString *viewString = [itemInfo objectForKey:kFunctionCellView];
   if (!viewString)
      return;
   
   // note assumption of controller class naming convention - add "Controller" to xib name
   NSString *viewControllerString = [viewString stringByAppendingString:@"Controller"];
   id controllerClass = objc_getClass([viewControllerString UTF8String]);
   twcheck(controllerClass);
   
   UIViewController *functionViewController = [[controllerClass alloc] initWithNibName:viewString bundle:nil];
   functionViewController.title = [itemInfo objectForKey:kFunctionCellText];
	[self.navigationController pushViewController:functionViewController animated:YES];
	[functionViewController release];
}

@end
