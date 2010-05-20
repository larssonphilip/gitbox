#import "GBRepository.h"
#import "GBCommit.h"
#import "GBStage.h"
#import "GBChange.h"
#import "GBRemote.h"
#import "GBRef.h"

#import "GBTask.h"

#import "OATaskManager.h"

#import "NSFileManager+OAFileManagerHelpers.h"
#import "NSObject+OALogging.h"
#import "NSAlert+OAAlertHelpers.h"
#import "NSData+OADataHelpers.h"

@implementation GBRepository

@synthesize url;
@synthesize dotGitURL;
@synthesize localBranches;
@synthesize remotes;
@synthesize tags;
@synthesize stage;
@synthesize currentRef;
@synthesize commits;
@synthesize taskManager;

@synthesize delegate;



#pragma mark Init


- (void) dealloc
{
  self.url = nil;
  self.dotGitURL = nil;
  self.localBranches = nil;
  self.remotes = nil;
  self.tags = nil;
  self.stage = nil;
  self.currentRef = nil;
  self.commits = nil;
  self.taskManager = nil;
  [super dealloc];
}

- (NSURL*) dotGitURL
{
  if (!dotGitURL)
  {
    self.dotGitURL = [self.url URLByAppendingPathComponent:@".git"];
  }
  return [[dotGitURL retain]  autorelease];
}

- (GBStage*) stage
{
  if (!stage)
  {
    self.stage = [[GBStage new] autorelease];
    stage.repository = self;
  }
  return [[stage retain] autorelease];
}

- (NSArray*) localBranches
{
  if (!localBranches)
  {
    self.localBranches = [self loadLocalBranches];
  }
  return [[localBranches retain] autorelease];
}

- (NSArray*) remotes
{
  if (!remotes)
  {
    self.remotes = [self loadRemotes];
  }
  return [[remotes retain] autorelease];
}

- (NSArray*) remoteBranches
{
  NSMutableArray* list = [NSMutableArray array];
  for (GBRemote* remote in self.remotes)
  {
    [list addObjectsFromArray:remote.branches];
  }
  return list;
}

- (NSArray*) tags
{
  if (!tags)
  {
    self.tags = [self loadTags];
  }
  return [[tags retain] autorelease];
}

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
    ref.repository = self;
    if ([HEAD hasPrefix:refprefix])
    {
      ref.name = [HEAD substringFromIndex:[refprefix length]];
    }
    else // assuming SHA1 ref
    {
      ref.commitId = HEAD;
    }
    self.currentRef = ref;
  }
  return [[currentRef retain] autorelease];
}

- (NSArray*) commits
{
  if (!commits)
  {
    self.commits = [self loadCommits];
  }
  return [[commits retain] autorelease];
}

- (OATaskManager*) taskManager
{
  if (!taskManager)
  {
    self.taskManager = [[OATaskManager new] autorelease];
  }
  return [[taskManager retain] autorelease];
}





#pragma mark Info


+ (BOOL) isValidRepositoryAtPath:(NSString*) aPath
{
  return aPath && [NSFileManager isWritableDirectoryAtPath:[aPath stringByAppendingPathComponent:@".git"]];
}

- (NSString*) path
{
  return [url path];
}





#pragma mark Update methods


- (void) updateStatus
{
  [self.stage reloadChanges];
}

- (void) updateCommits
{
  self.commits = [self loadCommits];
}

- (NSArray*) loadCommits
{
  return [[NSArray arrayWithObject:self.stage] arrayByAddingObjectsFromArray:[self.currentRef loadCommits]];
}

- (NSArray*) loadLocalBranches
{
  NSMutableArray* list = [NSMutableArray array];
  NSURL* aurl = [self gitURLWithSuffix:@"refs/heads"];
  for (NSURL* aURL in [NSFileManager contentsOfDirectoryAtURL:aurl])
  {
    NSString* name = [[aURL pathComponents] lastObject];
    GBRef* ref = [[GBRef new] autorelease];
    ref.repository = self;
    ref.name = name;
    [list addObject:ref];
  }
  return list;
}

- (NSArray*) loadTags
{
  NSMutableArray* list = [NSMutableArray array];
  NSURL* aurl = [self gitURLWithSuffix:@"refs/tags"];
  for (NSURL* aURL in [NSFileManager contentsOfDirectoryAtURL:aurl])
  {
    NSString* name = [[aURL pathComponents] lastObject];
    GBRef* ref = [[GBRef new] autorelease];
    ref.repository = self;
    ref.name = name;
    ref.isTag = YES;
    [list addObject:ref];
  }
  return list;
}

- (NSArray*) loadRemotes
{
  NSMutableArray* list = [NSMutableArray array];
  NSURL* aurl = [self gitURLWithSuffix:@"refs/remotes"];
  for (NSURL* aURL in [NSFileManager contentsOfDirectoryAtURL:aurl])
  {
    if ([NSFileManager isReadableDirectoryAtPath:aURL.path])
    {
      NSString* alias = [[aURL pathComponents] lastObject];
      GBRemote* remote = [[GBRemote new] autorelease];
      remote.repository = self;
      remote.alias = alias;
      [list addObject:remote];        
    }
  }
  return list;
}




#pragma mark Mutation methods


- (void) checkoutRef:(GBRef*)ref
{
  [[[self task] launchWithArgumentsAndWait:[NSArray arrayWithObjects:@"checkout", [ref commitish], nil]] showErrorIfNeeded];
  
  // invalidate current ref
  self.currentRef = nil;
}

- (void) checkoutRef:(GBRef*)ref withNewBranchName:(NSString*)name
{
  [[[self task] launchWithArgumentsAndWait:[NSArray arrayWithObjects:@"checkout", @"-b", name, [ref commitish], nil]] showErrorIfNeeded];
  
  // invalidate current ref
  self.currentRef = nil;  
}

- (void) checkoutNewBranchName:(NSString*)name
{
  [[[self task] launchWithArgumentsAndWait:[NSArray arrayWithObjects:@"checkout", @"-b", name, nil]] showErrorIfNeeded];
  
  // invalidate current ref
  self.currentRef = nil;    
}

- (void) commitWithMessage:(NSString*) message
{
  if (message && [message length] > 0)
  {
    [[[self task] launchWithArgumentsAndWait:[NSArray arrayWithObjects:@"commit", @"-m", message, nil]] showErrorIfNeeded];
    [self updateStatus];
    [self updateCommits];    
  }
}




#pragma mark Utility methods


- (GBTask*) task
{
  GBTask* task = [[GBTask new] autorelease];
  task.repository = self;
  return task;
}

- (GBTask*) launchTask:(GBTask*)aTask
{
  aTask.repository = self;
  [self.taskManager launchTask:aTask];
  return aTask;
}

- (GBTask*) launchTaskAndWait:(GBTask*)aTask
{
  aTask.repository = self;
  [aTask launchAndWait];
  return aTask;
}

- (NSURL*) gitURLWithSuffix:(NSString*)suffix
{
  return [self.dotGitURL URLByAppendingPathComponent:suffix];
}



@end
