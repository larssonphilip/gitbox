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
@synthesize currentLocalRef;
@synthesize currentRemoteBranch;

@synthesize commits;
@synthesize localBranchCommits;

@synthesize taskManager;

@synthesize pulling;
@synthesize merging;
@synthesize fetching;
@synthesize pushing;

@synthesize delegate;

@synthesize selectedCommit;

#pragma mark Init


+ (id) freshRepositoryForURL:(NSURL*)url
{
  NSLog(@"TODO: freshRepositoryForURL:%@", url);
  return nil;
}

- (void) dealloc
{
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
  
  self.url = nil;
  self.dotGitURL = nil;
  self.localBranches = nil;
  self.remotes = nil;
  self.tags = nil;
  self.stage = nil;
  self.currentLocalRef = nil;
  self.currentRemoteBranch = nil;
  
  self.commits = nil;
  self.localBranchCommits = nil;
  
  self.taskManager = nil;
  
  self.selectedCommit = nil;
  
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

- (GBRef*) currentLocalRef
{
  if (!currentLocalRef)
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
    self.currentLocalRef = ref;
  }
  return [[currentLocalRef retain] autorelease];
}



- (GBRef*) currentRemoteBranch
{
  if (!currentRemoteBranch)
  {
    self.currentRemoteBranch = [self.currentLocalRef rememberedOrGuessedRemoteBranch];
    [self.currentLocalRef rememberRemoteBranch:currentRemoteBranch];
  }
  return [[currentRemoteBranch retain] autorelease];
}


- (NSArray*) commits
{
  if (!commits)
  {
    self.commits = [self composedCommits];
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


- (void) saveObject:(id)obj forKey:(NSString*)key
{
  NSString* repokey = [NSString stringWithFormat:@"optionsFor:%@", self.path];
  NSDictionary* dict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:repokey];
  NSMutableDictionary* mdict = nil;
  if (dict) mdict = [[dict mutableCopy] autorelease];
  if (!dict) mdict = [NSMutableDictionary dictionary];
  [mdict setObject:obj forKey:key];
  [[NSUserDefaults standardUserDefaults] setObject:mdict forKey:repokey];
}

- (id) loadObjectForKey:(NSString*)key
{
  NSString* repokey = [NSString stringWithFormat:@"optionsFor:%@", self.path];
  NSDictionary* dict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:repokey];
  if (!dict) dict = [NSDictionary dictionary];
  return [dict objectForKey:key];
}



#pragma mark Interrogation


+ (BOOL) isValidRepositoryAtPath:(NSString*) aPath
{
  NSLog(@"TODO: check parent folders for containing .git");
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
  self.commits = [self composedCommits];
}

- (void) reloadCommits
{
  [self.currentLocalRef updateCommits];
  [self updateCommits];
}

- (NSArray*) composedCommits
{
  if (!self.localBranchCommits) self.localBranchCommits = [NSArray array];
  return [[NSArray arrayWithObject:self.stage] arrayByAddingObjectsFromArray:self.localBranchCommits];
}

- (void) remoteDidUpdate:(GBRemote*)aRemote
{
  [self.delegate repository:self didUpdateRemote:aRemote];
}

- (void) branch:(GBRef*)aBranch didLoadCommits:(NSArray*)theCommits;
{
  if (aBranch == self.currentLocalRef)
  {
    self.localBranchCommits = theCommits;
    [self updateCommits];
  }
}



#pragma mark Background Update


- (void) beginBackgroundUpdate
{
  [self endBackgroundUpdate];
  backgroundUpdateEnabled = YES;
  backgroundUpdateInterval = 30.0;
  [self performSelector:@selector(fetchSilentlyDuringBackgroundUpdate) 
             withObject:nil 
             afterDelay:backgroundUpdateInterval];
}

- (void) endBackgroundUpdate
{
  backgroundUpdateEnabled = NO;
  [NSObject cancelPreviousPerformRequestsWithTarget:self 
                                           selector:@selector(fetchSilentlyDuringBackgroundUpdate) 
                                             object:nil];
}

- (void) fetchSilentlyDuringBackgroundUpdate
{
  if (!backgroundUpdateEnabled) return;
  backgroundUpdateInterval *= 1.2;
  [self performSelector:@selector(fetchSilentlyDuringBackgroundUpdate) 
             withObject:nil 
             afterDelay:backgroundUpdateInterval];
  [self fetchSilently];
}






#pragma mark Mutation methods



- (void) resetCurrentLocalRef
{
  self.currentLocalRef = nil; // invalidate
  GBRef* ref = [self.currentLocalRef rememberedOrGuessedRemoteBranch];
  if (ref) self.currentRemoteBranch = ref;
  [self.currentLocalRef rememberRemoteBranch:self.currentRemoteBranch];
}

- (void) checkoutRef:(GBRef*)ref
{
  [[[self task] launchWithArgumentsAndWait:[NSArray arrayWithObjects:@"checkout", [ref commitish], nil]] showErrorIfNeeded];
  
  [self resetCurrentLocalRef];
}

- (void) checkoutRef:(GBRef*)ref withNewBranchName:(NSString*)name
{
  [[[self task] launchWithArgumentsAndWait:[NSArray arrayWithObjects:@"checkout", @"-b", name, [ref commitish], nil]] showErrorIfNeeded];
  
  [self resetCurrentLocalRef];
  if ([ref isRemoteBranch])
  {
    self.currentRemoteBranch = ref;
  }
}

- (void) checkoutNewBranchName:(NSString*)name
{
  [[[self task] launchWithArgumentsAndWait:[NSArray arrayWithObjects:@"checkout", @"-b", name, nil]] showErrorIfNeeded];
  
  [self resetCurrentLocalRef];
}

- (void) commitWithMessage:(NSString*) message
{
  if (message && [message length] > 0)
  {
    [[[self task] launchWithArgumentsAndWait:[NSArray arrayWithObjects:@"commit", @"-m", message, nil]] showErrorIfNeeded];
    [self updateStatus];
    [self reloadCommits];
  }
}

- (void) selectRemoteBranch:(GBRef*)aBranch
{
  self.currentRemoteBranch = aBranch;
  
  if (self.currentLocalRef && [self.currentLocalRef isLocalBranch])
  {
    [self.currentLocalRef rememberRemoteBranch:aBranch];
  }
}

- (void) pull
{
  if (self.currentRemoteBranch)
  {
    [self pullBranch:self.currentRemoteBranch];
  }
}

- (void) pullBranch:(GBRef*)aRemoteBranch
{
  if (!self.pulling)
  {
    NSLog(@"TODO: check for already fetched commits and merge them with a blocking task instead of pulling again");
    self.pulling = YES;
    
    GBTask* pullTask = [GBTask task];
    pullTask.arguments = [NSArray arrayWithObjects:@"pull", aRemoteBranch.remoteAlias, aRemoteBranch.name, nil];
    [pullTask subscribe:self selector:@selector(pullTaskDidFinish:)];
    [self launchTask:pullTask];
  }
}

- (void) push
{
  if (self.currentRemoteBranch)
  {
    [self pushBranch:self.currentLocalRef to:self.currentRemoteBranch];
  }  
}

- (void) pushBranch:(GBRef*)aLocalBranch to:(GBRef*)aRemoteBranch
{
  if (!self.pushing && !self.pulling)
  {
    self.pushing = YES;
    
    GBTask* pushTask = [GBTask task];
    NSString* refspec = [NSString stringWithFormat:@"%@:%@", aLocalBranch.name, aRemoteBranch.name];
    pushTask.arguments = [NSArray arrayWithObjects:@"push", @"--tags", aRemoteBranch.remoteAlias, refspec, nil];
    [pushTask subscribe:self selector:@selector(pushTaskDidFinish:)];
    [self launchTask:pushTask];    
  }
}

- (void) fetchSilently
{
  GBRef* aRemoteBranch = self.currentRemoteBranch;
  if (!self.fetching && aRemoteBranch)
  {
    self.fetching = YES;
    
    GBTask* fetchTask = [GBTask task];
    fetchTask.arguments = [NSArray arrayWithObjects:@"fetch", @"--tags", aRemoteBranch.remoteAlias, aRemoteBranch.name, nil];
    [fetchTask subscribe:self selector:@selector(fetchSilentlyTaskDidFinish:)];
    [self launchTask:fetchTask];
  }
}





#pragma mark Git Task Callbacks


- (void) pullTaskDidFinish:(NSNotification*)notification
{
  GBTask* task = [notification object];
  [task unsubscribe:self];
  self.pulling = NO;
  
  [self reloadCommits];
  [self updateStatus];
}

- (void) pushTaskDidFinish:(NSNotification*)notification
{
  GBTask* task = [notification object];
  [task unsubscribe:self];
  self.pushing = NO;
  
  if ([task isError])
  {
    [self fetchSilently];
    [NSAlert message: @"Push failed"
         description: @"Try to pull first."];
  }
  
  [self reloadCommits];
}

- (void) fetchSilentlyTaskDidFinish:(NSNotification*)notification
{
  GBTask* task = [notification object];
  [task unsubscribe:self];
  self.fetching = NO;
  
  [self reloadCommits];
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
