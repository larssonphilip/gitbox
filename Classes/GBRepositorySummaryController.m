#import "GBRepository.h"
#import "GBRemote.h"
#import "GBRepositorySummaryController.h"

@interface GBRepositorySummaryController ()
- (NSString*) parentFolder;
- (NSString*) repoTitle;
- (NSString*) repoPath;
- (NSString*) repoURLString;
@end

@implementation GBRepositorySummaryController

@synthesize parentFolderLabel;
@synthesize titleLabel;
@synthesize pathLabel;
@synthesize originLabel;

- (void) dealloc
{
  self.parentFolderLabel = nil;
  self.titleLabel = nil;
  self.pathLabel = nil;
  self.originLabel = nil;  
  [super dealloc];
}

- (id) initWithRepository:(GBRepository*)repo
{
  if ((self = [super initWithRepository:repo]))
  {
  }
  return self;
}

- (NSString*) title
{
  return NSLocalizedString(@"Summary", @"");
}

- (void) viewDidAppear
{
  [super viewDidAppear];
  
  [self.parentFolderLabel setStringValue:[self parentFolder]];
  [self.titleLabel setStringValue:[self repoTitle]];
  [self.pathLabel setStringValue:[self repoPath]];
  [self.originLabel setStringValue:[self repoURLString]];
  
  // TODO: support multiple URLs
  // TODO: add more labels for useless stats like number of commits, tags, creation date, size on disk, committers etc.
}



#pragma mark Private


- (NSString*) parentFolder
{
  NSArray* pathComps = [[self.repository.url path] pathComponents];
  
  if ([pathComps count] < 2) return @"";
  
  return [pathComps objectAtIndex:[pathComps count] - 2];
}

- (NSString*) repoTitle
{
  NSString* s = [self.repository.url path];
  s = [s lastPathComponent];
  return s ? s : @"";
}

- (NSString*) repoPath
{
  NSString* s = [self.repository.url path];
  NSString* homePath = NSHomeDirectory();
  if (homePath)
  {
    NSRange r = [s rangeOfString:homePath];
    if (r.location == 0)
    {
      s = [s stringByReplacingOccurrencesOfString:homePath withString:@"~" options:0 range:r];
    }
  }
  return s ? s : @"";
}

- (NSString*) repoURLString
{
  NSArray* remotes = self.repository.remotes;
  if ([remotes count] < 1) return @"";
  NSString* url = [[remotes objectAtIndex:0] URLString];
  return url ? url : @"";
}

@end
