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
@synthesize topCommitId;

@synthesize needsLocalBranchesUpdate;
@synthesize needsRemotesUpdate;



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





#pragma mark Properties



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










#pragma mark Interrogation





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

- (NSArray*) stageAndCommits
{
  NSArray* list = [NSArray arrayWithObject:self.stage];
  if (self.localBranchCommits)
  {
    list = [list arrayByAddingObjectsFromArray:self.localBranchCommits];
  }
  return list;
}






#pragma mark Update



- (void) updateLocalBranchesAndTagsWithBlockIfNeeded:(GBBlock)block
{
  if (!needsLocalBranchesUpdate) return;
  [self updateLocalBranchesAndTagsWithBlock:block];
  
}

- (void) updateLocalBranchesAndTagsWithBlock:(GBBlock)block
{
  self.needsLocalBranchesUpdate = NO;
  GBLocalBranchesTask* task = [GBLocalBranchesTask task];
  task.repository = self;
  [task launchWithBlock:^{
    self.localBranches = task.branches;
    self.tags = task.tags;
    block();
  }];
}

- (void) updateRemotesWithBlockIfNeeded:(GBBlock)block
{
  if (!needsRemotesUpdate) return;
  [self updateRemotesWithBlock:block];
}

- (void) updateRemotesWithBlock:(GBBlock)block
{
  self.needsRemotesUpdate = NO;
  GBRemotesTask* task = [GBRemotesTask task];
  task.repository = self;
  [task launchWithBlock:^{
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
    self.topCommitId = newTopCommitId;
    self.localBranchCommits = task.commits;
    
    block();
  }];
}

- (void) updateUnmergedCommitsWithBlock:(GBBlock)block
{
  GBHistoryTask* task = [GBHistoryTask task];
  task.repository = self;
  task.branch = self.currentRemoteBranch;
  task.substructedBranch = self.currentLocalRef;
  [task launchWithBlock:^{
    NSArray* allCommits = self.localBranchCommits;
    for (GBCommit* commit in task.commits)
    {
      NSUInteger index = [allCommits indexOfObject:commit];
      commit = [allCommits objectAtIndex:index];
      commit.syncStatus = GBCommitSyncStatusUnmerged;
    }
    block();
  }];  
}

- (void) updateUnpushedCommitsWithBlock:(GBBlock)block
{
  GBHistoryTask* task = [GBHistoryTask task];
  task.repository = self;
  task.branch = self.currentLocalRef;
  task.substructedBranch = self.currentRemoteBranch;
  [task launchWithBlock:^{
    NSArray* allCommits = self.localBranchCommits;
    for (GBCommit* commit in task.commits)
    {
      NSUInteger index = [allCommits indexOfObject:commit];
      commit = [allCommits objectAtIndex:index];
      commit.syncStatus = GBCommitSyncStatusUnpushed;
    }
    block();
  }];
}






#pragma mark Mutation methods


- (void) configureTrackingRemoteBranch:(GBRef*)ref withLocalName:(NSString*)name withBlock:(GBBlock)block
{
  if (!ref || ![ref isRemoteBranch] || !name)
  {
    block();
    return;
  }
  
  GBTask* task1 = [self task];
  task1.arguments = [NSArray arrayWithObjects:@"config", 
                     [NSString stringWithFormat:@"branch.%@.remote", name], 
                     ref.remoteAlias, 
                     nil];
  [task1 launchWithBlock:^{
    GBTask* task2 = [self task];
    task2.arguments = [NSArray arrayWithObjects:@"config", 
                       [NSString stringWithFormat:@"branch.%@.merge", name],
                       [NSString stringWithFormat:@"refs/heads/%@", ref.name],
                       nil];
    [task2 launchWithBlock:^{
      [task2 showErrorIfNeeded];
      block();
    }];
  }];  
}


- (void) checkoutRef:(GBRef*)ref withBlock:(GBBlock)block
{
  GBTask* task = [self task];
  task.arguments = [NSArray arrayWithObjects:@"checkout", [ref commitish], nil];
  [task launchWithBlock:^{
    [task showErrorIfNeeded];
    block();
  }];
}

- (void) checkoutRef:(GBRef*)ref withNewName:(NSString*)name withBlock:(GBBlock)block
{
  if ([ref isRemoteBranch])
  {
    GBTask* checkoutTask = [self task];
    checkoutTask.arguments = [NSArray arrayWithObjects:@"checkout", @"-b", name, [ref commitish], nil];
    [checkoutTask launchWithBlock:^{
      [checkoutTask showErrorIfNeeded];
      [self configureTrackingRemoteBranch:ref withLocalName:name withBlock:block];
    }];
  }
  else
  {
    block();
  }
}

- (void) checkoutNewBranchWithName:(NSString*)name withBlock:(GBBlock)block
{
  GBTask* checkoutTask = [self task];
  checkoutTask.arguments = [NSArray arrayWithObjects:@"checkout", @"-b", name, nil];
  [checkoutTask launchWithBlock:^{
    [checkoutTask showErrorIfNeeded];
    [self configureTrackingRemoteBranch:self.currentRemoteBranch withLocalName:name withBlock:block];
  }];
}







- (void) commitWithMessage:(NSString*) message
{
  if (message && [message length] > 0)
  {
    [[[self task] launchWithArgumentsAndWait:[NSArray arrayWithObjects:@"commit", @"-m", message, nil]] showErrorIfNeeded];
    [self updateStatus];
//    [self reloadCommits];
  }
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








// FIXME: get rid of this
- (void) updateStatus
{
  [self.stage reloadChanges];
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
