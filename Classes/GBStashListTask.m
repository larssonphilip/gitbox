#import "GBStash.h"
#import "GBStashListTask.h"
#import "NSData+OADataHelpers.h"

@implementation GBStashListTask

// git stash list --format="reflog %gd%nauthorDate %ai%n%n%w(99999,4,4)%B"

@synthesize stashes;

- (void) dealloc
{
  self.stashes = nil;
  [super dealloc];
}


- (NSArray*) arguments
{
  return [NSArray arrayWithObjects:@"stash", @"list", @"--format=ref %gd%ndate %ai%n%n%w(99999,4,4)%B", nil];
}


/* 
Output sample:

ref stash@{0}
date 2011-05-22 15:14:56 +0200

    WIP on master: 724b090 added tons of files

ref stash@{1}
date 2011-05-22 15:04:21 +0200

    On master: wip on longer test file

ref stash@{2}
date 2011-05-22 15:03:34 +0200

    On master: wip on test file

*/

- (NSArray*) stashesFromStatusOutput:(NSData*)data
{
  
#define GBScanError(msg) { \
[pool drain]; \
NSLog(@"ERROR: GBStashListTask parse error: %@", msg); \
NSLog(@"INPUT: %@", stringData); \
return list; \
}
  
  NSMutableArray* list = [NSMutableArray array];
  
  NSString* stringData = [data UTF8String];
  NSArray* lines = [stringData componentsSeparatedByString:@"\n"];
  
  NSUInteger lineIndex = 0;
  NSString* line = nil;
#define GBNextLine { \
lineIndex++; \
if (lineIndex < [lines count]) { \
line = [lines objectAtIndex:lineIndex]; \
} else { \
line = nil; \
} \
}
  NSCharacterSet* whitespaceCharacterSet = [NSCharacterSet whitespaceCharacterSet];
  while (lineIndex < [lines count])
  {
    NSAutoreleasePool* pool = [NSAutoreleasePool new];
    
    line = [lines objectAtIndex:lineIndex];
    
    if ([line length] > 0)
    {
      GBStash* stash = [[GBStash new] autorelease];
      
      // ref stash@{1}
      if ([line hasPrefix:@"ref "])
      {
        stash.ref = [line substringFromIndex:4]; // 'ref ' skipped
      }
      else GBScanError(@"Expected 'ref <reflog selector>' line (like \"ref stash@{1}\")");
      
      GBNextLine;
            
      // date 2011-05-22 15:03:34 +0200
      if ([line hasPrefix:@"date "])
      {
        stash.date = [NSDate dateWithString:[line substringFromIndex:5]]; // 'date ' skipped
      }
      else GBScanError(@"Expected 'date <date>' line");
      
      GBNextLine;
            
      // Skip initial empty lines
      while (line && [line length] <= 0)
      {
        GBNextLine;
      }
      NSMutableArray* rawBodyLines = [NSMutableArray array];
      while (line && [line length] <= 0 || [line hasPrefix:@"    "])
      {
        [rawBodyLines addObject:[line stringByTrimmingCharactersInSet:whitespaceCharacterSet]];
        GBNextLine;
      }
      
      stash.rawMessage = [rawBodyLines componentsJoinedByString:@"\n"];
      
      [list addObject:stash];
      
    }// if ! empty line
    else
    {
      GBNextLine;
    }
    
    [pool drain];
  }
  
  return list;
}

- (void) didFinishInBackground
{
  [super didFinishInBackground];
  
  if (self.terminationStatus == 0)
  {
    self.stashes = [self stashesFromStatusOutput:self.output];
  }
}

@end
