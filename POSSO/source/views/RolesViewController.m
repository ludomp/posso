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
 RolesViewController.m
 POssO is a portable administration console for OpenSSO.
 
 POssO adds the much desired remote management feature to your corporate identity 
 management infrastructure, enabling you to achieve better efficiency and 
 accessibility in your organization. 
 Learn more about POssO on the http://posso.mobi site.
 */


#import "RolesViewController.h"
#import "PossoAppDelegate.h"
#import "LogsViewController.h"

@implementation RolesViewController

@synthesize enterLoginLabel;
@synthesize loadingIndicator;
@synthesize errorLabel;
@synthesize rolesTable;
@synthesize lastRetrievedToken;
@synthesize lastRetrievedRoles;

#pragma mark -
#pragma mark Life cycle

- (void)viewDidLoad
{
   [super viewDidLoad];
   
   self.rolesTable.backgroundColor = [UIColor clearColor];
   
   [self fixDisplay];
}

- (void)viewWillAppear:(BOOL)animated
{
   (void)animated;
   
	NSIndexPath *selection = [self.rolesTable indexPathForSelectedRow];
	if (selection)
		[self.rolesTable deselectRowAtIndexPath:selection animated:animated];
   
   if (![self.lastRetrievedToken isEqual:[PossoAppDelegate appDelegate].token])
      [self fixDisplay];
}

- (void)didReceiveMemoryWarning
{
   twlog("RolesViewController didReceiveMemoryWarning -- no action");
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
   self.enterLoginLabel = nil;
   self.loadingIndicator = nil;
   self.errorLabel = nil;
   self.rolesTable = nil;
}

- (void)dealloc
{
   [self clearOutlets];
   self.lastRetrievedToken = nil;
   self.lastRetrievedRoles = nil;
   [super dealloc];
}

#pragma mark -
#pragma mark Roles management

- (void)fixDisplay
{
   // empty table data if there was any
   self.lastRetrievedRoles = [NSMutableArray array];
   
   // check if we've got a valid token
   self.lastRetrievedToken = [PossoAppDelegate appDelegate].token;
   if (!self.lastRetrievedToken.length)
   {
      self.enterLoginLabel.hidden = NO;
      self.loadingIndicator.stopAnimating;
      self.errorLabel.hidden = YES;
      self.rolesTable.hidden = YES;
      return;
   }
   
   // ok, start a request
   self.enterLoginLabel.hidden = YES;
   self.loadingIndicator.startAnimating;
   self.errorLabel.hidden = YES;
   self.rolesTable.hidden = YES;

   [self performSelectorInBackground:@selector(loadRolesFromServer) withObject:nil];
}

- (void)loadRolesFromServer
{
   NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

   BOOL validConfiguration = YES;
   NSString *serverBase = [PossoAppDelegate appDelegate].baseURL;
   validConfiguration &= 0 < serverBase.length;
   validConfiguration &= 0 < self.lastRetrievedToken.length;
   twcheck(validConfiguration);

   NSString *rolesURL1String = [NSString
      stringWithFormat:@"%@/search?&name=*&attributes_names=objecttype&attributes_values_objecttype=group&admin=%@",
      serverBase,
      self.lastRetrievedToken
   ];
   
	NSError* rolesError = nil;
	NSString *rolesResult1 = [NSString
      stringWithContentsOfURL:[NSURL URLWithString:rolesURL1String]
      encoding:NSNonLossyASCIIStringEncoding
      error:&rolesError
   ];
   twlogif(nil != rolesError, "roles group getting FAIL: %@", rolesError);

   NSString *rolesURL2String = [NSString
      stringWithFormat:@"%@/search?&name=*&attributes_names=objecttype&attributes_values_objecttype=role&admin=%@",
      serverBase,
      self.lastRetrievedToken
   ];
   
	rolesError = nil;
	NSString *rolesResult2 = [NSString
      stringWithContentsOfURL:[NSURL URLWithString:rolesURL2String]
      encoding:NSNonLossyASCIIStringEncoding
      error:&rolesError
   ];
   twlogif(nil != rolesError, "roles role getting FAIL: %@", rolesError);
   
   self.loadingIndicator.stopAnimating;
   NSString *rolesResult = [rolesResult1 stringByAppendingString:rolesResult2];
   if (!rolesError && [self parseRoles:rolesResult])
   {
      self.rolesTable.hidden = NO;
      [self.rolesTable reloadData];
      [LogsViewController log:@"listed roles"];
   }
   else
   {
      twlog("roles result FAIL: %@", rolesResult);
      self.errorLabel.hidden = NO;
      [LogsViewController log:@"listing roles failed"];
   }
   
   [pool release];
}

- (BOOL)parseRoles:(NSString *)roles
{
   if (!roles || !roles.length)
      return NO;
   if (0 != [roles rangeOfString:@"Error report"].length)
      return NO;
   
   // expect a list of names and possible values on separate lines
   NSArray *lineArray = [roles componentsSeparatedByString:@"\n"];
   if (2 > lineArray.count)
   {
      twlog("something odd about received roles -- no line breaks!");
      return NO;
   }
   
   // and these are what we expect each line to start with
   NSString *namePrefix = @"string=";
   
   // so we'll go through the lines and construct an array to populate the table with
   for (NSString *line in lineArray)
   {
      if (2 > line.length)
         continue; // trailing CR, we assume

      if ([line hasPrefix:namePrefix])
      {
         NSString *userID = [line stringByReplacingOccurrencesOfString:namePrefix withString:@""];
         [self.lastRetrievedRoles addObject:userID];
 
         continue;
      }
      
      twlog("what is this line? -- %@", line);
   }
   
   return YES;
}

#pragma mark -
#pragma mark Table support

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	(void)tableView;
   
   return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
   (void)tableView;
   (void)section;

   return self.lastRetrievedRoles.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
   static NSString *RolesCellIdentifier = @"Roles";
   
   UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:RolesCellIdentifier];
   if (cell == nil)
      cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:RolesCellIdentifier] autorelease];
	
   cell.text = [lastRetrievedRoles objectAtIndex:indexPath.row];
  // cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
   
	return cell;
}

/*
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[self tableView:tableView accessoryButtonTappedForRowWithIndexPath:indexPath];
}
*/
/*- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
 	(void)tableView;
   
   NSString *username = [lastRetrievedRoles objectAtIndex:indexPath.row];
   twlog("dispay user %@!", username);
   
   UIViewController *userViewController = [[EditUserViewController alloc] initWithNibName:@"EditUserView" bundle:nil];
   userViewController.title = username;
	[self.navigationController pushViewController:userViewController animated:YES];
	[userViewController release];
} 
 */

@end
