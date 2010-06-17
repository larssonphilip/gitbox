#import "GBModels.h"

#import "OATaskManager.h"

#import "GBTask.h"
#import "GBRemotesTask.h"
#import "GBHistoryTask.h"
#import "GBLocalBranchesTask.h"

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
    self.currentLocalRef = [self loadCurrentLocalRef];
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


+ (NSString*) supportedGitVersion
{
  return @"1.7.1";
}

+ (NSString*) gitVersion
{
  return [self gitVersionForLaunchPath:[OATask systemPathForExecutable:@"git"]];
}

+ (NSString*) gitVersionForLaunchPath:(NSString*) aLaunchPath
{
  OATask* task = [OATask task];
  task.currentDirectoryPath = NSHomeDirectory();
  //task.executableName = @"git";
  if (aLaunchPath)
  {
    task.launchPath = aLaunchPath;
  }
  task.arguments = [NSArray arrayWithObject:@"--version"];
  if (![task launchPath])
  {
    return nil;
  }
  [task launchAndWait];
  return [[[task.output UTF8String] stringByReplacingOccurrencesOfString:@"git version" withString:@""] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}


+ (BOOL) isSupportedGitVersion:(NSString*)version
{
  NSLog(@"isSupportedGitVersion: %@", version);
  if (!version) return NO;
  return [version compare:[self supportedGitVersion]] != NSOrderedAscending;
}

+ (NSString*) validRepositoryPathForPath:(NSString*)aPath
{
  if (!aPath) return nil;
  while (![NSFileManager isWritableDirectoryAtPath:[aPath stringByAppendingPathComponent:@".git"]])
  {
    if ([aPath isEqualToString:@"/"] || [aPath isEqualToString:@""]) return nil;
    aPath = [aPath stringByDeletingLastPathComponent];
    if (!aPath) return nil;
  }
  return aPath;
}

- (GBRef*) loadCurrentLocalRef
{
  NSError* outError = nil;
  NSString* HEAD = [NSString stringWithContentsOfURL:[self gitURLWithSuffix:@"HEAD"]
                                            encoding:NSUTF8StringEncoding 
                                               error:&outError];
  if (!HEAD)
  {
    [self alertWithError:outError];
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
  return ref;
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
  GBLocalBranchesTask* task = [GBLocalBranchesTask task];
  [self launchTaskAndWait:task];
  self.tags = task.tags;
  return task.branches;
}

- (NSArray*) loadTags
{
  GBLocalBranchesTask* task = [GBLocalBranchesTask task];
  [self launchTaskAndWait:task];
  self.localBranches = task.branches;
  return task.tags;
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

- (void) updateBranchStatus
{
  GBRef* ref = [self loadCurrentLocalRef];
  if (![ref isEqual:self.currentLocalRef])
  {
    [self resetCurrentLocalRef];
    [self reloadCommits];
  }
  self.localBranches = [self loadLocalBranches];
}

- (void) updateCommits
{
  self.commits = [self composedCommits];
}

- (void) reloadCommits
{
  GBHistoryTask* localAndRemoteCommitsTask = [GBHistoryTask task];
  localAndRemoteCommitsTask.branch = self.currentLocalRef;
  localAndRemoteCommitsTask.joinedBranch = self.currentRemoteBranch;
  localAndRemoteCommitsTask.target = self;
  localAndRemoteCommitsTask.action = @selector(didReceiveLocalAndRemoteCommits:);
  [self launchTask:localAndRemoteCommitsTask];
  [self updateCommits];
}
  - (void) didReceiveLocalAndRemoteCommits:(NSArray*)theCommits
  {
    self.localBranchCommits = theCommits;
    
    GBHistoryTask* unmergedCommitsTask = [GBHistoryTask task];
    unmergedCommitsTask.branch = self.currentRemoteBranch;
    unmergedCommitsTask.substructedBranch = self.currentLocalRef;
    unmergedCommitsTask.target = self;
    unmergedCommitsTask.action = @selector(didReceiveUnmergedRemoteCommits:);
    [self launchTaskAndWait:unmergedCommitsTask];

    GBHistoryTask* unpushedCommitsTask = [GBHistoryTask task];
    unpushedCommitsTask.branch = self.currentLocalRef;
    unpushedCommitsTask.substructedBranch = self.currentRemoteBranch;
    unpushedCommitsTask.target = self;
    unpushedCommitsTask.action = @selector(didReceiveUnpushedLocalCommits:);
    [self launchTaskAndWait:unpushedCommitsTask];
    
    [self updateCommits];
  }

    - (void) didReceiveUnmergedRemoteCommits:(NSArray*)unmergedCommits
    {
      NSArray* allCommits = self.localBranchCommits;
      for (GBCommit* commit in unmergedCommits)
      {
        NSUInteger index = [allCommits indexOfObject:commit];
        commit = [allCommits objectAtIndex:index];
        commit.syncStatus = GBCommitSyncStatusUnmerged;
      }
    }

    - (void) didReceiveUnpushedLocalCommits:(NSArray*)unpushedCommits
    {
      NSArray* allCommits = self.localBranchCommits;
      for (GBCommit* commit in unpushedCommits)
      {
        NSUInteger index = [allCommits indexOfObject:commit];
        commit = [allCommits objectAtIndex:index];
        commit.syncStatus = GBCommitSyncStatusUnpushed;
      }
    }


- (void) reloadRemotes
{
  self.remotes = [self loadRemotes];
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




#pragma mark Background Update


- (void) beginBackgroundUpdate
{
  [self endBackgroundUpdate];
  backgroundUpdateEnabled = YES;
  // randomness is added to make all opened windows fetch at different points of time
  backgroundUpdateInterval = 10.0 + 2*2*(0.5-drand48()); 
  [self performSelector:@selector(fetchSilentlyDuringBackgroundUpdate) 
             withObject:nil 
             afterDelay:15.0];
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
  backgroundUpdateInterval *= 1.3;
  [self performSelector:@selector(fetchSilentlyDuringBackgroundUpdate) 
             withObject:nil 
             afterDelay:backgroundUpdateInterval];
  [self fetchSilently];
}





#pragma mark Alerts


- (void) alertWithError:(NSError*)error
{
  if ([delegate respondsToSelector:@selector(repository:alertWithError:)])
  {
    [delegate repository:self alertWithError:error];
  }
  else
  {
    [NSAlert error:error];
  }
}

- (void) alertWithMessage:(NSString*)msg description:(NSString*)description
{
  if ([delegate respondsToSelector:@selector(repository:alertWithMessage:description:)])
  {
    [delegate repository:self alertWithMessage:msg description:description];
  }
  else
  {
    [NSAlert message:msg description:description];
  }
}





#pragma mark Mutation methods


+ (void) initRepositoryAtURL:(NSURL*)url
{
  OATask* task = [OATask task];
  task.currentDirectoryPath = url.path;
  task.executableName = @"git";
  task.arguments = [NSArray arrayWithObjects:@"init", nil];
  [task launchAndWait];
  [[NSFileManager defaultManager] copyItemAtPath:[[NSBundle mainBundle] pathForResource:@"default_gitignore" ofType:nil]
                                          toPath:[url.path stringByAppendingPathComponent:@".gitignore"] 
                                           error:NULL];
}

- (void) resetCurrentLocalRef
{
  self.currentLocalRef = [self loadCurrentLocalRef];
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
  
  if ([ref isRemoteBranch])
  {
    GBTask* task = [GBTask task];
    task.arguments = [NSArray arrayWithObjects:@"config", 
                      [NSString stringWithFormat:@"branch.%@.remote", name], 
                      ref.remoteAlias, 
                      nil];
    [self launchTaskAndWait:task];
    task = [GBTask task];
    task.arguments = [NSArray arrayWithObjects:@"config", 
                      [NSString stringWithFormat:@"branch.%@.merge", name],
                      [NSString stringWithFormat:@"refs/heads/%@", ref.name],
                      nil];
    [self launchTaskAndWait:task];
  }
  
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
  [self.currentLocalRef rememberRemoteBranch:aBranch];
  [self reloadCommits];
}

- (void) pull
{
  if (self.currentRemoteBranch)
  {
    if ([self.currentRemoteBranch isLocalBranch])
    {
      [self mergeBranch:self.currentRemoteBranch];
    }
    else
    {
      [self pullBranch:self.currentRemoteBranch];
    }
  }
}

- (void) mergeBranch:(GBRef*)aBranch
{
  if (!self.pulling)
  {
    self.pulling = YES;
    
    GBTask* mergeTask = [GBTask task];
    mergeTask.arguments = [NSArray arrayWithObjects:@"merge", aBranch.name, nil];
    
    [mergeTask subscribe:self selector:@selector(mergeTaskDidFinish:)];
    [self launchTask:mergeTask];
  }
}
  - (void) mergeTaskDidFinish:(NSNotification*)notification
  {
    GBTask* task = [notification object];
    [task unsubscribe:self];
    self.pulling = NO;
    
    if ([task isError])
    {
      [self alertWithMessage: @"Merge failed" description:[task.output UTF8String]];
    }
    
    [self reloadCommits];
    [self updateStatus];
  }


- (void) pullBranch:(GBRef*)aRemoteBranch
{
  if (!self.pulling)
  {
    NSLog(@"TODO: check for already fetched commits and merge them with a blocking task instead of pulling again");
    self.pulling = YES;
    
    GBTask* pullTask = [GBTask task];
    pullTask.arguments = [NSArray arrayWithObjects:@"pull", 
                           @"--tags", 
                           @"--force", 
                           aRemoteBranch.remoteAlias, 
                           [NSString stringWithFormat:@"%@:refs/remotes/%@", 
                            aRemoteBranch.name, [aRemoteBranch nameWithRemoteAlias]],
                           nil];
    
    [pullTask subscribe:self selector:@selector(pullTaskDidFinish:)];
    [self launchTask:pullTask];
  }
}

  - (void) pullTaskDidFinish:(NSNotification*)notification
  {
    GBTask* task = [notification object];
    [task unsubscribe:self];
    self.pulling = NO;
    
    if ([task isError])
    {
      [self alertWithMessage: @"Pull failed" description:[task.output UTF8String]];
    }
    
    [self reloadCommits];
    [self updateStatus];
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
    aRemoteBranch.isNewRemoteBranch = NO;
    GBTask* pushTask = [GBTask task];
    NSString* refspec = [NSString stringWithFormat:@"%@:%@", aLocalBranch.name, aRemoteBranch.name];
    pushTask.arguments = [NSArray arrayWithObjects:@"push", @"--tags", aRemoteBranch.remoteAlias, refspec, nil];
    [pushTask subscribe:self selector:@selector(pushTaskDidFinish:)];
    [self launchTask:pushTask];    
  }
}

  - (void) pushTaskDidFinish:(NSNotification*)notification
  {
    GBTask* task = [notification object];
    [task unsubscribe:self];
    self.pushing = NO;
    
    if ([task isError])
    {
      [self fetchSilently];
      [self alertWithMessage: @"Push failed" description:[task.output UTF8String]];
    }
    [self reloadCommits];
  }


- (void) fetchSilently
{
  GBRef* aRemoteBranch = self.currentRemoteBranch;
  if (!self.fetching && aRemoteBranch && [aRemoteBranch isRemoteBranch])
  {
    self.fetching = YES;
    
    GBTask* fetchTask = [GBTask task];
    fetchTask.arguments = [NSArray arrayWithObjects:@"fetch", 
                           @"--tags", 
                           @"--force", 
                           aRemoteBranch.remoteAlias, 
                           [NSString stringWithFormat:@"%@:refs/remotes/%@", 
                            aRemoteBranch.name, [aRemoteBranch nameWithRemoteAlias]],
                           nil];
    [fetchTask subscribe:self selector:@selector(fetchSilentlyTaskDidFinish:)];
    [self launchTask:fetchTask];
  }
}





#pragma mark Git Task Callbacks


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
