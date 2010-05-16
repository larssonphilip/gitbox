#import "GBRepository.h"
#import "GBCommit.h"
#import "GBStage.h"
#import "GBChange.h"
#import "GBRef.h"

#import "GBTask.h"

#import "NSFileManager+OAFileManagerHelpers.h"
#import "NSObject+OALogging.h"
#import "NSAlert+OAAlertHelpers.h"
#import "NSData+OADataHelpers.h"

@implementation GBRepository

+ (BOOL) isValidRepositoryAtPath:(NSString*) aPath
{
  return aPath && [NSFileManager isWritableDirectoryAtPath:[aPath stringByAppendingPathComponent:@".git"]];
}

@synthesize delegate;
@synthesize url;

@dynamic path;
- (NSString*) path
{
  return [url path];
}

@synthesize stage;
- (GBCommit*) stage
{
  if (!stage)
  {
    self.stage = [[GBStage new] autorelease];
    stage.repository = self;
  }
  return [[stage retain] autorelease];
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
    NSLog(@"Find real remote branches");
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
      NSLog(@"TODO: Test for tag");
      ref.commitId = HEAD;
    }
    self.currentRef = ref;
  }
  return [[currentRef retain] autorelease];
}

@synthesize commits;
- (NSArray*) commits
{
  if (!commits)
  {
    self.commits = [NSArray arrayWithObject:self.stage];
  }
  return [[commits retain] autorelease];
}


- (GBTask*) task
{
  GBTask* task = [[GBTask new] autorelease];
  task.path = self.path;
  return task;
}


#pragma mark Mutation methods


- (void) checkoutRef:(GBRef*)ref
{
  NSString* rev = (ref.name ? ref.name : ref.commitId);
  
  [[self task] launchWithArguments:[NSArray arrayWithObjects:@"git", @"checkout", rev, nil]];
  
  // invalidate current ref
  self.currentRef = nil;
}


- (void) stageChange:(GBChange*)change
{
  NSData* output; // used to ignore error
  if ([change isDeletion])
  {
    [[self task] launchWithArguments:[NSArray arrayWithObjects:@"git", @"update-index", @"--remove", change.srcURL.path, nil] outputRef:&output];
  }
  else
  {
    [[self task] launchWithArguments:[NSArray arrayWithObjects:@"git", @"add", change.fileURL.path, nil] outputRef:&output];
  }

  [self updateStatus];
}

- (void) unstageChange:(GBChange*)change
{
  NSData* output; // used to ignore error
  [[self task] launchWithArguments:[NSArray arrayWithObjects:@"git", @"reset", @"--", change.fileURL.path, nil] outputRef:&output];
  [self updateStatus];
}

- (void) updateStatus
{
  [self.stage invalidateChanges];
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




#pragma mark Utility methods



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



@end
