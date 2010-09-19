#import "GBModels.h"

#import "GBTask.h"
#import "GBRemotesTask.h"
#import "GBHistoryTask.h"
#import "GBLocalBranchesTask.h"

#import "NSFileManager+OAFileManagerHelpers.h"
#import "NSData+OADataHelpers.h"
#import "NSArray+OAArrayHelpers.h"

#import "OAPropertyListController.h"

@implementation GBRepository

@synthesize url;
@synthesize dotGitURL;
@synthesize localBranches;
@synthesize remotes;
@synthesize tags;
@synthesize stage;
@synthesize currentLocalRef;
@synthesize currentRemoteBranch;

@synthesize localBranchCommits;

@synthesize needsLocalBranchesUpdate;
@synthesize needsRemotesUpdate;


@synthesize topCommitId;

@synthesize plistController;



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
  
  self.localBranchCommits = nil;
  
  self.topCommitId = nil;
  
  self.plistController = nil;
  
  [super dealloc];
}

+ (id) repository
{
  return [[self new] autorelease];
}

+ (id) repositoryWithURL:(NSURL*)url
{
  GBRepository* r = [self repository];
  r.url = url;
  return r;
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
  if (!localBranches) self.localBranches = [NSArray array];
  return [[localBranches retain] autorelease];
}

- (NSArray*) tags
{
  if (!tags) self.tags = [NSArray array];
  return [[tags retain] autorelease];
}

- (NSArray*) remotes
{
  if (!remotes) self.remotes = [NSArray array];
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

- (GBRef*) currentLocalRef
{
  if (!currentLocalRef) self.currentLocalRef = [self loadCurrentLocalRef];
  return [[currentLocalRef retain] autorelease];
}

- (GBRef*) currentRemoteBranch
{
  if (!currentRemoteBranch)
  {
    self.currentRemoteBranch = [self.currentLocalRef configuredOrRememberedRemoteBranch];
    [self.currentLocalRef rememberRemoteBranch:currentRemoteBranch];
  }
  return [[currentRemoteBranch retain] autorelease];
}


- (OAPropertyListController*) plistController
{
  if (!plistController)
  {
    self.plistController = [[OAPropertyListController new] autorelease];
    plistController.plistURL = [NSURL fileURLWithPath:[[[self path] stringByAppendingPathComponent:@".git"] stringByAppendingPathComponent:@"gitbox.plist"]];
  }
  return plistController; // it is used inside this object only, so we can not retain+autorelease it.
}









#pragma mark Per-repo options




- (void) saveObject:(id)obj forKey:(NSString*)key
{
  if (!obj) return;
  
  [self.plistController setObject:obj forKey:key];
    
  return;
  
  // Legacy non-used pre-0.9.8 code
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
  // try to find data in a .git/gitbox.plist
  // if not found, but found in NSUserDefaults, then write to .git/gitbox.plist
  id obj = nil;
  obj = [self.plistController objectForKey:key];
  if (!obj)
  {
    // Legacy API (pre 0.9.8)
    NSString* repokey = [NSString stringWithFormat:@"optionsFor:%@", self.path];
    NSDictionary* dict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:repokey];
    obj = [dict objectForKey:key];
    
    // Save to a new storage
    if (obj)
    {
      [self saveObject:obj forKey:key];
    }
  }
  return obj;
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
    NSLog(@"GBRepository: loadcurrentLocalRef error: %@", outError);
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







#pragma mark Update



- (void) updateLocalBranchesAndTagsIfNeededWithBlock:(GBBlock)block
{
  if (!needsLocalBranchesUpdate) return;
  [self updateLocalBranchesAndTagsWithBlock:block];
  
}

- (void) updateLocalBranchesAndTagsWithBlock:(GBBlock)block
{
  GBLocalBranchesTask* task = [GBLocalBranchesTask task];
  task.repository = self;
  [task launchWithBlock:^{
    self.needsLocalBranchesUpdate = NO;
    self.localBranches = task.branches;
    self.tags = task.tags;
    block();
  }];
}

- (void) updateRemotesIfNeededWithBlock:(GBBlock)block
{
  if (!needsRemotesUpdate) return;
  [self updateRemotesWithBlock:block];
}

- (void) updateRemotesWithBlock:(GBBlock)block
{
  GBRemotesTask* task = [GBRemotesTask task];
  task.repository = self;
  [task launchWithBlock:^{
    self.needsRemotesUpdate = NO;
    self.remotes = task.remotes;
    block();
  }];
}

- (void) updateLocalBranchCommitsWithBlock:(GBBlock)block
{
  GBHistoryTask* task = [GBHistoryTask task];
  task.repository = self;
  task.branch = self.currentLocalRef;
  task.joinedBranch = self.currentRemoteBranch;
  [task launchWithBlock:^{
    
    NSString* newTopCommitId = [[task.commits objectAtIndex:0 or:nil] commitId];
    if (newTopCommitId && ![topCommitId isEqualToString:newTopCommitId])
    {
      [self resetBackgroundUpdateInterval];
    }
    self.topCommitId = newTopCommitId;
    self.localBranchCommits = task.commits;
    
    GBHistoryTask* unmergedCommitsTask = [GBHistoryTask task];
    unmergedCommitsTask.repository = self;
    unmergedCommitsTask.branch = self.currentRemoteBranch;
    unmergedCommitsTask.substructedBranch = self.currentLocalRef;
    [unmergedCommitsTask launchWithBlock:^{
      NSArray* allCommits = self.localBranchCommits;
      for (GBCommit* commit in unmergedCommitsTask.commits)
      {
        NSUInteger index = [allCommits indexOfObject:commit];
        commit = [allCommits objectAtIndex:index];
        commit.syncStatus = GBCommitSyncStatusUnmerged;
      }
    }];
    
    GBHistoryTask* unpushedCommitsTask = [GBHistoryTask task];
    unpushedCommitsTask.repository = self;
    unpushedCommitsTask.branch = self.currentLocalRef;
    unpushedCommitsTask.substructedBranch = self.currentRemoteBranch;
    [unpushedCommitsTask launchWithBlock:^{
      NSArray* allCommits = self.localBranchCommits;
      for (GBCommit* commit in unpushedCommitsTask.commits)
      {
        NSUInteger index = [allCommits indexOfObject:commit];
        commit = [allCommits objectAtIndex:index];
        commit.syncStatus = GBCommitSyncStatusUnpushed;
      }
    }];
  }];
}

- (void) updateStatus
{
  [self.stage reloadChanges];
}

//- (void) updateBranchStatus
//{
//  GBRef* ref = [self loadCurrentLocalRef];
//  if (![ref isEqual:self.currentLocalRef])
//  {
//    [self resetCurrentLocalRef];
//    [self reloadCommits];
//  }
//  self.localBranches = [self loadLocalBranches];
//}



- (NSArray*) stageAndCommits
{
  NSArray* list = [NSArray arrayWithObject:self.stage];
  if (self.localBranchCommits)
  {
    list = [list arrayByAddingObjectsFromArray:self.localBranchCommits];
  }
  return list;
}


- (void) finish
{
  [self.plistController synchronizeIfNeeded];
  [self endBackgroundUpdate];
}




#pragma mark Background Update


- (void) resetBackgroundUpdateInterval
{
  backgroundUpdateInterval = 10.0 + 2*2*(0.5-drand48()); 
}


- (void) beginBackgroundUpdate
{
  [self endBackgroundUpdate];
  backgroundUpdateEnabled = YES;
  // randomness is added to make all opened windows fetch at different points of time
  [self resetBackgroundUpdateInterval];
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
  GBRef* ref = [self.currentLocalRef configuredOrRememberedRemoteBranch];
  if (ref) self.currentRemoteBranch = ref;
  [self.currentLocalRef rememberRemoteBranch:self.currentRemoteBranch];
}

- (void) checkoutRef:(GBRef*)ref withBlock:(GBBlock)block
{
  GBTask* task = [self task];
  task.arguments = [NSArray arrayWithObjects:@"checkout", [ref commitish], nil];
  [task launchWithBlock:^{
    [task showErrorIfNeeded];
    [self resetCurrentLocalRef];
    block();
  }];
}

- (void) checkoutRef:(GBRef*)ref withNewBranchName:(NSString*)name withBlock:(GBBlock)block
{
  [[[self task] launchWithArgumentsAndWait:[NSArray arrayWithObjects:@"checkout", @"-b", name, [ref commitish], nil]] showErrorIfNeeded];
  
  if ([ref isRemoteBranch])
  {
    GBTask* task = [self task];
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
      // Try to find some unmerged fetched commits and simply merge them without fetching again
      BOOL hasUnmergedCommits = NO;
      NSUInteger c = [self.localBranchCommits count];
      for (NSUInteger index = 0; index < c && !hasUnmergedCommits && index < 50; index++)
      {
        hasUnmergedCommits = hasUnmergedCommits || 
          (((GBCommit*)[self.localBranchCommits objectAtIndex:index]).syncStatus == GBCommitSyncStatusUnmerged);
      }
      if (hasUnmergedCommits)
      {
        // TODO: should create a queue for the tasks to replace the conditional flags like self.pulling
        //[self mergeBranch:self.currentRemoteBranch];
        [self pullBranch:self.currentRemoteBranch];
      }
      else
      {
        [self pullBranch:self.currentRemoteBranch];
      }
    }
  }
}

- (void) mergeBranch:(GBRef*)aBranch
{
//  if (!self.pulling)
//  {
//    self.pulling = YES;
    
    GBTask* task = [self task];
    task.arguments = [NSArray arrayWithObjects:@"merge", [aBranch nameWithRemoteAlias], nil];
    
    [task launchWithBlock:^{
//      self.pulling = NO;
      
      if ([task isError])
      {
        [self alertWithMessage: @"Merge failed" description:[task.output UTF8String]];
      }
      
      [self reloadCommits];
      [self updateStatus];      
    }];
//  }
}


- (void) pullBranch:(GBRef*)aRemoteBranch
{
//  if (!self.pulling)
//  {
//    self.pulling = YES;
    
    GBTask* task = [self task];
    task.arguments = [NSArray arrayWithObjects:@"pull", 
                           @"--tags", 
                           @"--force", 
                           aRemoteBranch.remoteAlias, 
                           [NSString stringWithFormat:@"%@:refs/remotes/%@", 
                            aRemoteBranch.name, [aRemoteBranch nameWithRemoteAlias]],
                           nil];
    
    [task launchWithBlock:^{
//      self.pulling = NO;
      
      if ([task isError])
      {
        [self alertWithMessage: @"Pull failed" description:[task.output UTF8String]];
      }
      
      [self reloadCommits];
      [self updateStatus];    
    }];
//  }
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
//  if (!self.pushing && !self.pulling)
//  {
//    self.pushing = YES;
    aRemoteBranch.isNewRemoteBranch = NO;
    GBTask* task = [self task];
    NSString* refspec = [NSString stringWithFormat:@"%@:%@", aLocalBranch.name, aRemoteBranch.name];
    task.arguments = [NSArray arrayWithObjects:@"push", @"--tags", aRemoteBranch.remoteAlias, refspec, nil];
    [task launchWithBlock:^{
      //    self.pushing = NO;
      
      if ([task isError])
      {
        [self fetchSilently];
        [self alertWithMessage: @"Push failed" description:[task.output UTF8String]];
      }
      [self reloadCommits];      
    }];    
//  }
}


- (void) fetchSilently
{
  GBRef* aRemoteBranch = self.currentRemoteBranch;
//  if (!self.fetching && aRemoteBranch && [aRemoteBranch isRemoteBranch])
//  {
//    self.fetching = YES;
    
    GBTask* task = [GBTask task];
    task.arguments = [NSArray arrayWithObjects:@"fetch", 
                           @"--tags", 
                           @"--force", 
                           aRemoteBranch.remoteAlias, 
                           [NSString stringWithFormat:@"%@:refs/remotes/%@", 
                            aRemoteBranch.name, [aRemoteBranch nameWithRemoteAlias]],
                           nil];
    [task launchWithBlock:^{
      //self.fetching = NO;
      [self reloadCommits];      
    }];
//  }
}





#pragma mark Utility methods


- (id) task
{
  GBTask* task = [[GBTask new] autorelease];
  task.repository = self;
  return task;
}

- (id) launchTask:(GBTask*)aTask withBlock:(void (^)())block
{
  aTask.repository = self;
  [aTask launchWithBlock:block];
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
