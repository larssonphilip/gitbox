#import "GBRepository.h"
#import "GBRef.h"
#import "NSFileManager+OAFileManagerHelpers.h"
#import "NSObject+OALogging.h"

@implementation GBRepository

+ (BOOL) isValidRepositoryAtPath:(NSString*) aPath
{
  return aPath && [NSFileManager isWritableDirectoryAtPath:[aPath stringByAppendingPathComponent:@".git"]];
}


@synthesize url;
@dynamic path;
- (NSString*) path
{
  return [url path];
}

@synthesize dotGitURL;
- (NSURL*) dotGitURL
{
  if (!dotGitURL)
  {
    self.dotGitURL = [self.url URLByAppendingPathComponent:@".git"];
  }
  return [[dotGitURL retain]  autorelease];
}

- (NSURL*) gitURLWithSuffix:(NSString*)suffix
{
  return [dotGitURL URLByAppendingPathComponent:suffix];
}


@synthesize localBranches;
- (NSArray*) localBranches
{
  if (!localBranches)
  {
    NSError* outError;
    NSArray* URLs = [[NSFileManager defaultManager] 
                     contentsOfDirectoryAtURL:[self gitURLWithSuffix:@"refs/heads"]
                      includingPropertiesForKeys:[NSArray array] 
                      options:0 
                      error:&outError];
    NSMutableArray* branches = [NSMutableArray array];
    for (NSURL* aURL in URLs)
    {
      NSString* name = [[aURL pathComponents] lastObject];
      GBRef* ref = [[GBRef new] autorelease];
      ref.name = name;
      [branches addObject:ref];
    }
    self.localBranches = branches;
  }
  return [[localBranches retain] autorelease];
}

@synthesize remoteBranches;
- (NSArray*) remoteBranches
{
  if (!remoteBranches)
  {
    [self TODO:@"Find real remote branches"];
    self.remoteBranches = [NSArray array];
  }
  return [[remoteBranches retain] autorelease];  
}

@synthesize tags;
- (NSArray*) tags
{
  if (!tags)
  {
    [self TODO:@"Find real tags"];
    self.tags = [NSArray array];
  }
  return [[tags retain] autorelease];
}

@synthesize currentRef;
- (GBRef*) currentRef
{
  if (!currentRef)
  {
    
  }
  return [[currentRef retain] autorelease];
}



- (void) dealloc
{
  self.url = nil;
  self.localBranches = nil;
  self.remoteBranches = nil;
  self.tags = nil;
  self.currentRef = nil;
  [super dealloc];
}

@end
