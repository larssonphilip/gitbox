#import "GBModels.h"

#import "OATaskManager.h"

#import "GBTask.h"
#import "GBRemotesTask.h"

#import "NSFileManager+OAFileManagerHelpers.h"
#import "NSAlert+OAAlertHelpers.h"
#import "NSData+OADataHelpers.h"
#import "NSArray+OAArrayHelpers.h"

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

@synthesize pulling;
@synthesize merging;
@synthesize fetching;
@synthesize pushing;

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





#pragma mark Interrogation


+ (BOOL) isValidRepositoryAtPath:(NSString*) aPath
{
  return aPath && [NSFileManager isWritableDirectoryAtPath:[aPath stringByAppendingPathComponent:@".git"]];
}

- (NSString*) path
{
  return [url path];
}

- (GBRemote*) defaultRemote
{
  for (GBRemote* remote in self.remotes)
  {
    if ([remote.alias isEqualToString:@"origin"]) return remote;
  }
  return [self.remotes firstObject];
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
  return [[self launchTaskAndWait:[GBRemotesTask task]] remotes];
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

- (void) remoteDidUpdate:(GBRemote*)aRemote
{
  [self.delegate repository:self didUpdateRemote:aRemote];
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

- (void) pull
{
  GBRef* remoteBranch = self.currentRef.remoteBranch;
  if (remoteBranch)
  {
    [self pullBranch:remoteBranch];
  }
}

- (void) pullBranch:(GBRef*)aRemoteBranch
{
  NSLog(@"TODO: check for already fetched commits and merge them with a blocking task instead of pulling again");
  self.pulling = YES;
  
  GBTask* pullTask = [GBTask task];
  pullTask.arguments = [NSArray arrayWithObjects:@"pull", aRemoteBranch.remoteAlias, aRemoteBranch.name, nil];
  [pullTask subscribe:self selector:@selector(pullTaskDidFinish:)];
  [self launchTask:pullTask];
}

- (void) push
{
  GBRef* remoteBranch = self.currentRef.remoteBranch;
  if (remoteBranch && self.currentRef)
  {
    [self pushBranch:self.currentRef to:remoteBranch];
  }  
}

- (void) pushBranch:(GBRef*)aLocalBranch to:(GBRef*)aRemoteBranch
{
  self.pushing = YES;
  
  GBTask* pushTask = [GBTask task];
  NSString* refspec = [NSString stringWithFormat:@"%@:%@", aLocalBranch.name, aRemoteBranch.name];
  pushTask.arguments = [NSArray arrayWithObjects:@"push", @"--tags", aRemoteBranch.remoteAlias, refspec, nil];
  [pushTask subscribe:self selector:@selector(pushTaskDidFinish:)];
  [self launchTask:pushTask];
}



#pragma mark Git Task Callbacks


- (void) pullTaskDidFinish:(NSNotification*)notification
{
  GBTask* task = [notification object];
  [task unsubscribe:self];
  self.pulling = NO;
  
  NSLog(@"TODO: update branch log and status");
}

- (void) pushTaskDidFinish:(NSNotification*)notification
{
  GBTask* task = [notification object];
  [task unsubscribe:self];
  self.pushing = NO;
  
  NSLog(@"TODO: if push fails, try fetch immediately (without errors) and show error");
  
  NSLog(@"TODO: update branch log and status");
}






#pragma mark Utility methods


- (id) task
{
  GBTask* task = [[GBTask new] autorelease];
  task.repository = self;
  return task;
}

- (id) enqueueTask:(GBTask*)aTask
{
  aTask.repository = self;
  [self.taskManager enqueueTask:aTask];
  return aTask;
}

- (id) launchTask:(GBTask*)aTask
{
  aTask.repository = self;
  [self.taskManager launchTask:aTask];
  return aTask;
}

- (id) launchTaskAndWait:(GBTask*)aTask
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
