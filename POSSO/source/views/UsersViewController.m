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
 UsersViewController.m
 POssO is a portable administration console for OpenSSO.
 
 POssO adds the much desired remote management feature to your corporate identity 
 management infrastructure, enabling you to achieve better efficiency and 
 accessibility in your organization. 
 Learn more about POssO on the http://posso.mobi site.
 */


#import "UsersViewController.h"
#import "PossoAppDelegate.h"
#import "EditUserViewController.h"
#import "LogsViewController.h"

@implementation UsersViewController

@synthesize enterLoginLabel;
@synthesize loadingIndicator;
@synthesize errorLabel;
@synthesize usersTable;
@synthesize lastRetrievedToken;
@synthesize lastRetrievedUsers;

#pragma mark -
#pragma mark Life cycle

- (void)viewDidLoad
{
   [super viewDidLoad];
   
   self.usersTable.backgroundColor = [UIColor clearColor];
   
   [self fixDisplay];
}

- (void)viewWillAppear:(BOOL)animated
{
   (void)animated;
   
	NSIndexPath *selection = [self.usersTable indexPathForSelectedRow];
	if (selection)
		[self.usersTable deselectRowAtIndexPath:selection animated:animated];
   
   if (![self.lastRetrievedToken isEqual:[PossoAppDelegate appDelegate].token])
      [self fixDisplay];
}

- (void)didReceiveMemoryWarning
{
   twlog("UsersViewController didReceiveMemoryWarning -- no action");
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
   self.usersTable = nil;
}

- (void)dealloc
{
   [self clearOutlets];
   self.lastRetrievedToken = nil;
   self.lastRetrievedUsers = nil;
   [super dealloc];
}

#pragma mark -
#pragma mark Users management

- (void)fixDisplay
{
   // empty table data if there was any
   self.lastRetrievedUsers = [NSMutableArray array];
   
   // check if we've got a valid token
   self.lastRetrievedToken = [PossoAppDelegate appDelegate].token;
   if (!self.lastRetrievedToken.length)
   {
      self.enterLoginLabel.hidden = NO;
      self.loadingIndicator.stopAnimating;
      self.errorLabel.hidden = YES;
      self.usersTable.hidden = YES;
      return;
   }
   
   // ok, start a request
   self.enterLoginLabel.hidden = YES;
   self.loadingIndicator.startAnimating;
   self.errorLabel.hidden = YES;
   self.usersTable.hidden = YES;

   [self performSelectorInBackground:@selector(loadUsersFromServer) withObject:nil];
}

- (void)loadUsersFromServer
{
   NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

   BOOL validConfiguration = YES;
   NSString *serverBase = [PossoAppDelegate appDelegate].baseURL;
   validConfiguration &= 0 < serverBase.length;
   validConfiguration &= 0 < self.lastRetrievedToken.length;
   twcheck(validConfiguration);
   
   NSString *usersURLString = [NSString
      stringWithFormat:@"%@/search?filter=*&attributes_names=objectclass&attributes_values_objectclass=person&admin=%@",
      serverBase,
      self.lastRetrievedToken
   ];
   
   // note that token needs percent encoding for an expected trailing # character
   // now we escape token on retrieval, including reserved but not illegal characters
   //usersURLString = [usersURLString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
   //twlog("calling %@ for users", usersURLString);
  
	NSError* usersError = nil;
	NSString *usersResult = [NSString
      stringWithContentsOfURL:[NSURL URLWithString:usersURLString]
      encoding:NSNonLossyASCIIStringEncoding
      error:&usersError
   ];
   /* it was suggested that needing to POST was the problem, but no, it was lack of percent encoding
    NSURL *usersURL = [NSURL URLWithString:usersURLString];
    NSMutableURLRequest *usersRequest = [NSMutableURLRequest requestWithURL:usersURL];
    [usersRequest setHTTPMethod: @"POST"];
    NSURLResponse* usersResponse = nil;
    NSData* usersResultData = [NSURLConnection
    sendSynchronousRequest:usersRequest
    returningResponse:&usersResponse
    error:&usersError
    ];
    */
   twlogif(nil != usersError, "users getting FAIL: %@", usersError);
   
   self.loadingIndicator.stopAnimating;
   if (!usersError && [self parseUsers:usersResult])
   {
      self.usersTable.hidden = NO;
      [self.usersTable reloadData];
      [LogsViewController log:@"listed users"];
   }
   else
   {
      twlog("users result FAIL: %@", usersResult);
      self.errorLabel.hidden = NO;
      [LogsViewController log:@"listing users failed"];
   }
   
   [pool release];
}

- (BOOL)parseUsers:(NSString *)users
{
   if (!users || !users.length)
      return NO;
   if (0 != [users rangeOfString:@"Error report"].length)
      return NO;
   
   // expect a list of names and possible values on separate lines
   NSArray *lineArray = [users componentsSeparatedByString:@"\n"];
   if (2 > lineArray.count)
   {
      twlog("something odd about received users -- no line breaks!");
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
         [self.lastRetrievedUsers addObject:userID];
 
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

   return self.lastRetrievedUsers.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
   static NSString *UsersCellIdentifier = @"Users";
   
   UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:UsersCellIdentifier];
   if (cell == nil)
      cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:UsersCellIdentifier] autorelease];
	
   cell.text = [lastRetrievedUsers objectAtIndex:indexPath.row];
   
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[self tableView:tableView accessoryButtonTappedForRowWithIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
 	(void)tableView;
   
   NSString *username = [lastRetrievedUsers objectAtIndex:indexPath.row];
   //twlog("dispay user %@!", username);
   
   UIViewController *userViewController = [[EditUserViewController alloc] initWithNibName:@"EditUserView" bundle:nil];
   userViewController.title = username;
	[self.navigationController pushViewController:userViewController animated:YES];
	[userViewController release];
}

@end
