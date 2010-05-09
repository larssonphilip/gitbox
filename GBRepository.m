#import "GBRepository.h"
#import "GBRef.h"
#import "NSFileManager+OAFileManagerHelpers.h"
#import "NSObject+OALogging.h"
#import "NSAlert+OAAlertHelpers.h"

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
  return [self.dotGitURL URLByAppendingPathComponent:suffix];
}


@synthesize localBranches;
- (NSArray*) localBranches
{
  if (!localBranches)
  {
    NSError* outError = nil;
    NSURL* aurl = [self gitURLWithSuffix:@"refs/heads"];
    NSAssert(aurl, @"url must be .git/refs/heads");
    NSArray* URLs = [[NSFileManager defaultManager] 
                     contentsOfDirectoryAtURL:aurl
                      includingPropertiesForKeys:[NSArray array] 
                      options:0 
                      error:&outError];
    NSMutableArray* refs = [NSMutableArray array];
    if (URLs)
    {
      for (NSURL* aURL in URLs)
      {
        NSString* name = [[aURL pathComponents] lastObject];
        GBRef* ref = [[GBRef new] autorelease];
        ref.name = name;
        [refs addObject:ref];
      }
    }
    else
    {
      [NSAlert error:outError];
    }
    self.localBranches = refs;
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
    NSError* outError = nil;
    NSURL* aurl = [self gitURLWithSuffix:@"refs/tags"];
    NSAssert(aurl, @"url must be .git/refs/tags");
    NSArray* URLs = [[NSFileManager defaultManager] 
                     contentsOfDirectoryAtURL:aurl
                     includingPropertiesForKeys:[NSArray array] 
                     options:0 
                     error:&outError];
    NSMutableArray* refs = [NSMutableArray array];
    if (URLs)
    {
      for (NSURL* aURL in URLs)
      {
        NSString* name = [[aURL pathComponents] lastObject];
        GBRef* ref = [[GBRef new] autorelease];
        ref.name = name;
        ref.isTag = YES;
        [refs addObject:ref];
      }
    }
    else
    {
      [NSAlert error:outError];
    }
    self.tags = refs;
  }
  return [[tags retain] autorelease];
}

@synthesize currentRef;
- (GBRef*) currentRef
{
  if (!currentRef)
  {
    NSError* outError = nil;
    NSString* HEAD = [NSString stringWithContentsOfURL:[self gitURLWithSuffix:@"HEAD"]
                                              encoding:NSUTF8StringEncoding 
                                                 error:&outError];
    if (!HEAD)
    {
      [NSAlert error:outError];
      return nil;
    }
    HEAD = [HEAD stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString* refprefix = @"ref: refs/heads/";
    GBRef* ref = [[GBRef new] autorelease];
    if ([HEAD hasPrefix:refprefix])
    {
      ref.name = [HEAD substringFromIndex:[refprefix length]];
    }
    else // assuming SHA1 ref
    {
      [self TODO:@"Test for tag"];
      ref.commitId = HEAD;
    }
    self.currentRef = ref;
  }
  return [[currentRef retain] autorelease];
}




#pragma mark Mutation methods


- (void) checkoutRef:(GBRef*)ref
{
  
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
