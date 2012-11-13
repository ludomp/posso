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
 WhoAmIViewController.m
 POssO is a portable administration console for OpenSSO.
 
 POssO adds the much desired remote management feature to your corporate identity 
 management infrastructure, enabling you to achieve better efficiency and 
 accessibility in your organization. 
 Learn more about POssO on the http://posso.mobi site.
 */

#import "WhoAmIViewController.h"
#import "PossoAppDelegate.h"
#import "LogsViewController.h"

@implementation WhoAmIViewController

@synthesize enterLoginLabel;
@synthesize loadingIndicator;
@synthesize errorLabel;
@synthesize infoTable;
@synthesize lastRetrievedToken;
@synthesize lastRetrievedInfo;

NSString* kWhoAmISectionName = @"section";
NSString* kWhoAmISectionValue = @"value";

#pragma mark -
#pragma mark Life cycle

- (void)viewDidLoad
{
   [super viewDidLoad];

   self.infoTable.backgroundColor = [UIColor clearColor];
   
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
   twlog("WhoAmIViewController didReceiveMemoryWarning -- no action");
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
      stringWithFormat:@"%@/attributes?subjectid=%@",
      serverBase,
      self.lastRetrievedToken
   ];
      
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
      [LogsViewController log:@"Who Am I query"];
   }
   else
   {
      twlog("whoami info FAIL: %@", infoResult);
      self.errorLabel.hidden = NO;
      [LogsViewController log:@"Who Am I query failed"];
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
   NSString *tokenPrefix = @"userdetails.token.id="; // first line 
   NSString *namePrefix = @"userdetails.attribute.name="; // a possible heading, if value(s) follow
   NSString *valuePrefix = @"userdetails.attribute.value="; // value(s) for the preceding heading

   // so we'll go through the lines and construct an array of dictionaries to populate the table with
   NSString *possibleHeading = nil;
   NSDictionary *currentDictionary = nil;
   for (NSString *line in lineArray)
   {
      if ([line hasPrefix:tokenPrefix] || (2 > line.length))
         continue; // we'll just assume those are first and last respectively

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
         
         // now add either a new item or append to last one
         if (!currentDictionary)
         {
            currentDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
               possibleHeading, kWhoAmISectionName,
               [rowArray mutableCopy], kWhoAmISectionValue,
               nil
            ];
            [self.lastRetrievedInfo addObject:currentDictionary];
         }
         else
         {
            [[currentDictionary objectForKey:kWhoAmISectionValue] addObjectsFromArray:rowArray];
         }
         
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
   
   NSInteger infoCount = self.lastRetrievedInfo.count;
   return infoCount ? infoCount : 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section;
{
	(void)tableView;
   
   if (section >= (NSInteger)self.lastRetrievedInfo.count)
      return @"no data";
	
   NSDictionary *sectionInfo = [self.lastRetrievedInfo objectAtIndex:section];
   return [sectionInfo objectForKey:kWhoAmISectionName];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
   (void)tableView;
	
   if (section >= (NSInteger)self.lastRetrievedInfo.count)
      return 0;

   NSDictionary *sectionInfo = [self.lastRetrievedInfo objectAtIndex:section];
   return [[sectionInfo objectForKey:kWhoAmISectionValue] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
   static NSString *WhoAmICellIdentifier = @"WhoAmI";
   
   UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:WhoAmICellIdentifier];
   if (cell == nil)
      cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:WhoAmICellIdentifier] autorelease];
	
   cell.selectionStyle = UITableViewCellSelectionStyleNone;
   NSDictionary *sectionInfo = [self.lastRetrievedInfo objectAtIndex:indexPath.section];
   cell.text = [[sectionInfo objectForKey:kWhoAmISectionValue] objectAtIndex:indexPath.row];
   
	return cell;
}

@end
