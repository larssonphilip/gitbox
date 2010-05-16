#import "GBChange.h"
#import "GBRepository.h"

@implementation GBChange

@synthesize srcURL;
@synthesize dstURL;
@synthesize statusCode;
@synthesize oldRevision;
@synthesize newRevision;
@synthesize staged;

@synthesize repository;

- (void) dealloc
{
  self.srcURL = nil;
  self.dstURL = nil;
  self.statusCode = nil;
  self.oldRevision = nil;
  self.newRevision = nil;
  [super dealloc];
}

- (void) setStaged:(BOOL) flag
{
  if (flag != staged)
  {
    staged = flag;
    if (flag)
    {
      [self.repository stageChange:self];
    }
    else
    {
      [self.repository unstageChange:self];
    }
  }
}

- (NSURL*) fileURL
{
  if (self.dstURL) return self.dstURL;
  return self.srcURL;
}

- (BOOL) isEqual:(GBChange*)other
{
  if (!other) return NO;
  return ([self.oldRevision isEqual:other.oldRevision] && [self.newRevision isEqual:other.newRevision]);
}

- (NSString*) status
{
  /*
   Possible status letters are:
   
   o   A: addition of a file
   
   o   C: copy of a file into a new one
   
   o   D: deletion of a file
   
   o   M: modification of the contents or mode of a file
   
   o   R: renaming of a file
   
   o   T: change in the type of the file
   
   o   U: file is unmerged (you must complete the merge before it can be committed)
   
   o   X: "unknown" change type (most probably a bug, please report it)
   
   Status letters C and R are always followed by a score (denoting the percentage of similarity between the source and target of the move or copy), and are the only ones to be so.
   
   */
  
  if (!self.statusCode || [self.statusCode length] < 1) return NSLocalizedString(@"Untracked", @"");
  
  const char* cstatusCode = [self.statusCode cStringUsingEncoding:NSUTF8StringEncoding];
  char c = *cstatusCode;
  if (c == 'A') return NSLocalizedString(@"Added", @"");
  if (c == 'C') return NSLocalizedString(@"Copied", @"");
  if (c == 'D') return NSLocalizedString(@"Deleted", @"");
  if (c == 'M') return NSLocalizedString(@"Modified", @"");
  if (c == 'R') return NSLocalizedString(@"Renamed", @"");
  if (c == 'T') return NSLocalizedString(@"Type changed", @"");
  if (c == 'U') return NSLocalizedString(@"Unmerged", @"");
  if (c == 'X') return NSLocalizedString(@"Unknown", @"");
  
  return self.statusCode;
}

- (NSString*) pathStatus
{
  if (self.dstURL)
  {
    return [NSString stringWithFormat:@"%@ → %@", self.srcURL.relativePath, self.dstURL.relativePath];
  }
  return self.srcURL.relativePath;
}

- (BOOL) isDeletion
{
  return [self.statusCode isEqualToString:@"D"];
}

- (NSComparisonResult) compareByPath:(GBChange*) other
{
  return [self.srcURL.relativePath compare:other.srcURL.relativePath];
}

@end
