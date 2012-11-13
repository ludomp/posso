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
 EditUserViewController.m
 POssO is a portable administration console for OpenSSO.
 
 POssO adds the much desired remote management feature to your corporate identity 
 management infrastructure, enabling you to achieve better efficiency and 
 accessibility in your organization. 
 Learn more about POssO on the http://posso.mobi site.
 */


#import "EditUserViewController.h"
#import "EditTextTableViewCell.h"
#import "PossoAppDelegate.h"
#import "LogsViewController.h"

@implementation EditUserViewController

@synthesize enterLoginLabel;
@synthesize loadingIndicator;
@synthesize errorLabel;
@synthesize infoTable;
@synthesize editableFields;
@synthesize lastRetrievedToken;
@synthesize lastRetrievedInfo;

NSString* kEditUserSectionName = @"section";
NSString* kEditUserSectionValue = @"value";
NSString* kEditUserSectionEditable = @"editable";

#pragma mark -
#pragma mark Life cycle

- (void)viewDidLoad
{
   [super viewDidLoad];

   self.infoTable.backgroundColor = [UIColor clearColor];
   self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc]
      initWithBarButtonSystemItem:UIBarButtonSystemItemTrash
      target:self
      action:@selector(deleteUser)
   ] autorelease];

   self.editableFields = [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"userEditableFields" ofType:@"plist"]];

   [self retrieveInfo];
}

- (void)viewWillAppear:(BOOL)animated
{
   (void)animated;
   
   if (![self.lastRetrievedToken isEqual:[PossoAppDelegate appDelegate].token])
      [self retrieveInfo];
}

- (void)didReceiveMemoryWarning
{
   twlog("EditUserViewController didReceiveMemoryWarning -- no action");
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
   self.infoTable = nil;
}

- (void)dealloc
{
   [self clearOutlets];
   self.editableFields = nil;
   self.lastRetrievedToken = nil;
   self.lastRetrievedInfo = nil;
   [super dealloc];
}

#pragma mark -
#pragma mark Info management

- (void)retrieveInfo
{
   // empty table data if there was any
   self.lastRetrievedInfo = [NSMutableArray array];
   
   // check if we've got a valid token
   self.lastRetrievedToken = [PossoAppDelegate appDelegate].token;
   if (!self.lastRetrievedToken.length)
   {
      self.enterLoginLabel.hidden = NO;
      self.loadingIndicator.stopAnimating;
      self.errorLabel.hidden = YES;
      self.infoTable.hidden = YES;
      return;
  }
   
   // ok, start a request
   self.enterLoginLabel.hidden = YES;
   self.loadingIndicator.startAnimating;
   self.errorLabel.hidden = YES;
   self.infoTable.hidden = YES;

   BOOL validConfiguration = YES;
   NSString *serverBase = [PossoAppDelegate appDelegate].baseURL;
   validConfiguration &= 0 < serverBase.length;
   validConfiguration &= 0 < self.lastRetrievedToken.length;
   twcheck(validConfiguration);
   
   NSString *infoURLString = [NSString
      stringWithFormat:@"%@/read?&name=%@&attributes_names=objecttype&attributes_values_objecttype=user&admin=%@",
      serverBase,
      self.title, // note we assume creator will have set this
      self.lastRetrievedToken
   ];

   // note that token needs percent encoding for an expected trailing # character
   // now we escape token on retrieval, including reserved but not illegal characters
   //infoURLString = [infoURLString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
   //twlog("calling %@ for user %@ info", infoURLString, self.title);
   
	NSError* infoError = nil;
	NSString *infoResult = [NSString
      stringWithContentsOfURL:[NSURL URLWithString:infoURLString]
      encoding:NSNonLossyASCIIStringEncoding
      error:&infoError
   ];
   /* it was suggested that needing to POST was the problem, but no, it was lack of percent encoding
   NSURL *infoURL = [NSURL URLWithString:infoURLString];
   NSMutableURLRequest *infoRequest = [NSMutableURLRequest requestWithURL:infoURL];
	[infoRequest setHTTPMethod: @"POST"];
   NSURLResponse* infoResponse = nil;
	NSData* infoResultData = [NSURLConnection
      sendSynchronousRequest:infoRequest
      returningResponse:&infoResponse
      error:&infoError
   ];
   */
   twlogif(nil != infoError, "info getting FAIL: %@", infoError);
  
   self.loadingIndicator.stopAnimating;
   if (!infoError && [self parseInfo:infoResult])
   {
      self.infoTable.hidden = NO;
      [self.infoTable reloadData];
      [LogsViewController logWithFormat:@"loaded user %@ info", self.title];
   }
   else
   {
      twlog("EditUser info FAIL: %@", infoResult);
      self.errorLabel.hidden = NO;
      [LogsViewController logWithFormat:@"loading user %@ info failed", self.title];
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
   
   // and these are what we expect each line to start with
   NSString *userNamePrefix = @"identitydetails.name="; // first line 
   NSString *userTypePrefix = @"identitydetails.type="; // second line 
   NSString *userRealmPrefix = @"identitydetails.realm="; // third line 
   NSString *emptyLine = @"identitydetails.attribute="; // ignore
   NSString *namePrefix = @"identitydetails.attribute.name="; // a possible heading, if value(s) follow
   NSString *valuePrefix = @"identitydetails.attribute.value="; // value(s) for the preceding heading

   // so we'll go through the lines and construct an array of dictionaries to populate the table with
   NSString *possibleHeading = nil;
   NSDictionary *currentDictionary = nil;
   for (NSString *line in lineArray)
   {
      if (2 > line.length)
         continue; // trailing CR, we assume
      if ([emptyLine isEqual:line])
         continue; // instructions are to ignore

      if ([line hasPrefix:userNamePrefix])
      {
         NSString *userName = [line stringByReplacingOccurrencesOfString:userNamePrefix withString:@""];
         NSDictionary *nameDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
            @"Name", kEditUserSectionName,
            [NSArray arrayWithObject:userName], kEditUserSectionValue,
            [NSNumber numberWithBool:NO], kEditUserSectionEditable,
            nil
         ];
         [self.lastRetrievedInfo addObject:nameDictionary];
         
         continue;
     }

      if ([line hasPrefix:userTypePrefix])
      {
         NSString *userType = [line stringByReplacingOccurrencesOfString:userTypePrefix withString:@""];
         NSDictionary *typeDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
            @"Type", kEditUserSectionName,
            [NSArray arrayWithObject:userType], kEditUserSectionValue,
            [NSNumber numberWithBool:NO], kEditUserSectionEditable,
            nil
         ];
         [self.lastRetrievedInfo addObject:typeDictionary];
         
         continue;
     }

      if ([line hasPrefix:userRealmPrefix])
      {
         NSString *userRealms = [line stringByReplacingOccurrencesOfString:userRealmPrefix withString:@""];
         NSArray *realmsArray = [userRealms componentsSeparatedByString:@","];
         NSDictionary *realmsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
            @"Realms", kEditUserSectionName,
            realmsArray, kEditUserSectionValue,
           [NSNumber numberWithBool:NO], kEditUserSectionEditable,
            nil
         ];
         [self.lastRetrievedInfo addObject:realmsDictionary];
         
         continue;
      }
      
      if ([line hasPrefix:namePrefix])
      {
         currentDictionary = nil;
         possibleHeading = [line stringByReplacingOccurrencesOfString:namePrefix withString:@""];
         
         // but we'll filter out some things
         if ([possibleHeading isEqual:@"userpassword"])
            possibleHeading = nil;
         
         continue;
      }

      if ([line hasPrefix:valuePrefix])
      {
         if (!possibleHeading && !currentDictionary)
            continue; // we filtered it out above, we assume
         
         // we'll assume that if any commas appear in line they delineate multiple rows
         NSString *rowList = [line stringByReplacingOccurrencesOfString:valuePrefix withString:@""];
         NSArray *rowArray = [rowList componentsSeparatedByString:@","];
         
         BOOL canEdit = NSNotFound != [self.editableFields indexOfObject:possibleHeading];
         
         // now add either a new item or append to last one
         if (!currentDictionary)
         {
            currentDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
               possibleHeading, kEditUserSectionName,
               [rowArray mutableCopy], kEditUserSectionValue,
               [NSNumber numberWithBool:canEdit], kEditUserSectionEditable,
               nil
            ];
            [self.lastRetrievedInfo addObject:currentDictionary];
         }
         else
         {
            [[currentDictionary objectForKey:kEditUserSectionValue] addObjectsFromArray:rowArray];
         }
         
         continue;
      }
      
      twlog("what is this line? -- %@", line);
   }
   
   return YES;
}

- (void)deleteUser
{
   // check to make sure!
   
   UIActionSheet *actionSheet = [[[UIActionSheet alloc]
      initWithTitle:@"Confirm Delete User"
      delegate:self
      cancelButtonTitle:@"Cancel"
      destructiveButtonTitle:@"Delete User"
      otherButtonTitles:nil
   ] autorelease];
   [actionSheet showFromTabBar:[PossoAppDelegate appDelegate].tabBar];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
   if (actionSheet.destructiveButtonIndex != buttonIndex)
      return;
   
   // alrighty, they ok'd it

   BOOL validConfiguration = YES;
   NSString *serverBase = [PossoAppDelegate appDelegate].baseURL;
   validConfiguration &= 0 < serverBase.length;
   validConfiguration &= 0 < self.lastRetrievedToken.length;
   twcheck(validConfiguration);
   
   NSString *deleteURLString = [NSString
      stringWithFormat:@"%@/delete?identity_name=%@&identity_type=user&admin=%@",
      serverBase,
      self.title, // note we assume creator will have set this
      self.lastRetrievedToken
   ];
   
	NSError* deleteError = nil;
	NSString *deleteResult = [NSString
      stringWithContentsOfURL:[NSURL URLWithString:deleteURLString]
      encoding:NSNonLossyASCIIStringEncoding
      error:&deleteError
   ];
   twlogif(nil != deleteError, "deleting FAIL: %@", deleteError);
   twlog("delete result: %@", deleteResult);
   [LogsViewController logWithFormat:@"deleted user %@", self.title];
   
   [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark -
#pragma mark Table support

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	(void)tableView;
   
   NSInteger infoCount = self.lastRetrievedInfo.count;
   return infoCount ? infoCount : 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section;
{
	(void)tableView;
   
   if (section >= (NSInteger)self.lastRetrievedInfo.count)
      return @"no data";
	
   NSDictionary *sectionInfo = [self.lastRetrievedInfo objectAtIndex:section];
   return [sectionInfo objectForKey:kEditUserSectionName];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
   (void)tableView;
	
   if (section >= (NSInteger)self.lastRetrievedInfo.count)
      return 0;

   NSDictionary *sectionInfo = [self.lastRetrievedInfo objectAtIndex:section];
   return [[sectionInfo objectForKey:kEditUserSectionValue] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
   static NSString *EditUserCellIdentifier = @"EditUser";
   
   EditTextTableViewCell *cell = (EditTextTableViewCell *)[tableView dequeueReusableCellWithIdentifier:EditUserCellIdentifier];
   if (cell == nil)
      cell = [[[EditTextTableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:EditUserCellIdentifier] autorelease];
	
   NSDictionary *sectionInfo = [self.lastRetrievedInfo objectAtIndex:indexPath.section];
   cell.label.text = [[sectionInfo objectForKey:kEditUserSectionValue] objectAtIndex:indexPath.row];
   cell.editable = [[sectionInfo objectForKey:kEditUserSectionEditable] boolValue];
    
	return cell;
}

@end
