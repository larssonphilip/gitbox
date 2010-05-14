#import "GBCommit.h"

@implementation GBCommit
@synthesize revision;
@synthesize changes;
@synthesize isWorkingDirectory;

@synthesize comment;
@synthesize authorName;
@synthesize authorEmail;
@synthesize date;


- (void) dealloc
{
  self.revision = nil;
  self.changes = nil;
  
  self.comment = nil;
  self.authorName = nil;
  self.authorEmail = nil;
  self.date = nil;
  
  [super dealloc];
}

@end
