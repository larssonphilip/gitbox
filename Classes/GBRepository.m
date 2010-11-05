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
@synthesize dispatchQueue;


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
  
  if (self.dispatchQueue) dispatch_release(self.dispatchQueue);
  self.dispatchQueue = nil;
    
  [super dealloc];
}


- (id) init
{
  if (self = [super init])
  {
    self.dispatchQueue = dispatch_queue_create("com.oleganza.gitbox.repository_queue", NULL);
  }
  return self;
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
  return [self gitVersionForLaunchPath:[GBTask pathToBundledBinary:@"git"]];
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
  if ([aPath rangeOfString:@"/.Trash/"].location != NSNotFound) return nil;
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
  task.launchPath = [GBTask pathToBundledBinary:@"git"];
  task.arguments = [NSArray arrayWithObjects:@"init", nil];
  [task launchAndWait];
  [[NSFileManager defaultManager] copyItemAtPath:[[NSBundle mainBundle] pathForResource:@"default_gitignore" ofType:nil]
                                          toPath:[url.path stringByAppendingPathComponent:@".gitignore"] 
                                           error:NULL];
}

+ (void) configureUTF8WithBlock:(GBBlock)block
{
  OATask* task = [OATask task];
  task.launchPath = [GBTask pathToBundledBinary:@"git"];
  task.arguments = [NSArray arrayWithObjects:@"config", @"--global", @"core.quotepath", @"false",  nil];
  [task launchWithBlock:block];
}

+ (NSString*) configValueForKey:(NSString*)key
{
  OATask* task = [OATask task];
  task.launchPath = [GBTask pathToBundledBinary:@"git"];
  task.arguments = [NSArray arrayWithObjects:@"config", @"--global", key,  nil];
  [task launchAndWait];
  return [[task.output UTF8String] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

+ (void) setConfigValue:(NSString*)value forKey:(NSString*)key
{
  OATask* task = [OATask task];
  task.launchPath = [GBTask pathToBundledBinary:@"git"];
  task.arguments = [NSArray arrayWithObjects:@"config", @"--global", key, value,  nil];
  [task launchAndWait];
}

+ (void) configureName:(NSString*)name email:(NSString*)email withBlock:(GBBlock)block
{
  // git config --global user.name "Joey Joejoe"
  // git config --global user.email "joey@joejoe.com"
  
  [self setConfigValue:name forKey:@"user.name"];
  [self setConfigValue:email forKey:@"user.email"];
  block();
}

+ (NSString*) globalConfiguredName
{
  return [self configValueForKey:@"user.name"];
}

+ (NSString*) globalConfiguredEmail
{
  return [self configValueForKey:@"user.email"];
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



- (void) updateLocalBranchesAndTagsWithBlock:(GBBlock)block
{
  GBLocalBranchesTask* task = [GBLocalBranchesTask task];
  task.repository = self;
  [task launchWithBlock:^{
    self.localBranches = task.branches;
    self.tags = task.tags;
    block();
  }];
}

- (void) updateRemotesWithBlock:(GBBlock)block
{
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


- (void) configureTrackingRemoteBranch:(GBRef*)ref withLocalName:(NSString*)name block:(GBBlock)block
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
  [self launchTask:task1 withBlock:^{
  }];
  GBTask* task2 = [self task];
  task2.arguments = [NSArray arrayWithObjects:@"config", 
                     [NSString stringWithFormat:@"branch.%@.merge", name],
                     [NSString stringWithFormat:@"refs/heads/%@", ref.name],
                     nil];
  [self launchTask:task2 withBlock:^{
    [task2 showErrorIfNeeded];
  }];
  [self dispatchBlock:block];
}


- (void) checkoutRef:(GBRef*)ref withBlock:(GBBlock)block
{
  GBTask* task = [self task];
  task.arguments = [NSArray arrayWithObjects:@"checkout", [ref commitish], nil];
  [self launchTask:task withBlock:^{
    [task showErrorIfNeeded];
    block();
  }];
}

- (void) checkoutRef:(GBRef*)ref withNewName:(NSString*)name block:(GBBlock)block
{
  if ([ref isRemoteBranch])
  {
    GBTask* checkoutTask = [self task];
    checkoutTask.arguments = [NSArray arrayWithObjects:@"checkout", @"-b", name, [ref commitish], nil];
    [checkoutTask launchWithBlock:^{
      [checkoutTask showErrorIfNeeded];
      [self configureTrackingRemoteBranch:ref withLocalName:name block:block];
    }];
  }
  else
  {
    block();
  }
}

- (void) checkoutNewBranchWithName:(NSString*)name block:(GBBlock)block
{
  GBTask* checkoutTask = [self task];
  checkoutTask.arguments = [NSArray arrayWithObjects:@"checkout", @"-b", name, nil];
  [checkoutTask launchWithBlock:^{
    [checkoutTask showErrorIfNeeded];
    [self configureTrackingRemoteBranch:self.currentRemoteBranch withLocalName:name block:block];
  }];
}

- (void) commitWithMessage:(NSString*) message block:(void(^)())block
{
  if (message && [message length] > 0)
  {
    GBTask* task = [self task];
    task.arguments = [NSArray arrayWithObjects:@"commit", @"-m", message, nil];
    [task launchWithBlock:^{
      [task showErrorIfNeeded];
      block();
    }];
  }
  else
  {
    block();
  }
}






#pragma mark Pull, Merge, Push


- (void) alertWithMessage:(NSString*)message description:(NSString*)description
{
  NSAlert* alert = [[[NSAlert alloc] init] autorelease];
  [alert addButtonWithTitle:@"OK"];
  [alert setMessageText:message];
  [alert setInformativeText:description];
  [alert setAlertStyle:NSWarningAlertStyle];
  
  [alert runModal];
  
  //[alert retain];
  // This cycle delay helps to avoid toolbar deadlock
  //[self performSelector:@selector(slideAlert:) withObject:alert afterDelay:0.1];
}

- (void) fetchWithBlock:(GBBlock)block
{
  if (self.currentRemoteBranch && [self.currentRemoteBranch isRemoteBranch])
  {
    [self fetchBranch:self.currentRemoteBranch withBlock:block];
  }
  else
  {
    block();
  }  
}

- (void) pullOrMergeWithBlock:(GBBlock)block
{
  if (self.currentRemoteBranch)
  {
    if ([self.currentRemoteBranch isLocalBranch])
    {
      [self mergeBranch:self.currentRemoteBranch withBlock:block];
    }
    else
    {
      [self pullBranch:self.currentRemoteBranch withBlock:block];
    }
  }
  else
  {
    block();
  }
}

- (void) mergeBranch:(GBRef*)aBranch withBlock:(GBBlock)block
{
  GBTask* task = [self task];
  task.arguments = [NSArray arrayWithObjects:@"merge", [aBranch nameWithRemoteAlias], nil];
  [self launchTask:task withBlock:^{
    if ([task isError])
    {
      [self alertWithMessage: @"Merge failed" description:[task.output UTF8String]];
    }
    block();
  }];
}

- (void) pullBranch:(GBRef*)aRemoteBranch withBlock:(GBBlock)block
{
  if (!aRemoteBranch)
  {
    block();
    return;
  }
  GBTask* task = [self task];
  task.arguments = [NSArray arrayWithObjects:@"pull", 
                         @"--tags", 
                         @"--force", 
                         aRemoteBranch.remoteAlias, 
                         [NSString stringWithFormat:@"%@:refs/remotes/%@", 
                          aRemoteBranch.name, [aRemoteBranch nameWithRemoteAlias]],
                         nil];
  
  [self launchTask:task withBlock:^{
    if ([task isError])
    {
      [self alertWithMessage: @"Pull failed" description:[task.output UTF8String]];
    }
    block();
  }];
}

- (void) fetchBranch:(GBRef*)aRemoteBranch withBlock:(GBBlock)block
{
  if (!aRemoteBranch)
  {
    block();
    return;
  }
  GBTask* task = [self task];
  task.arguments = [NSArray arrayWithObjects:@"fetch", 
                    @"--tags", 
                    @"--force", 
                    aRemoteBranch.remoteAlias, 
                    [NSString stringWithFormat:@"%@:refs/remotes/%@", 
                     aRemoteBranch.name, [aRemoteBranch nameWithRemoteAlias]],
                    nil];
  
  [self launchTask:task withBlock:^{
    if ([task isError])
    {
      [self alertWithMessage: @"Fetch failed" description:[task.output UTF8String]];
    }
    block();
  }];
}

- (void) pushWithBlock:(GBBlock)block
{
  [self pushBranch:self.currentLocalRef toRemoteBranch:self.currentRemoteBranch withBlock:block];
}

- (void) pushBranch:(GBRef*)aLocalBranch toRemoteBranch:(GBRef*)aRemoteBranch withBlock:(GBBlock)block
{
  if (!aLocalBranch || !aRemoteBranch)
  {
    block();
    return;
  }
  
  GBTask* task = [self task];
  NSString* refspec = [NSString stringWithFormat:@"%@:%@", aLocalBranch.name, aRemoteBranch.name];
  task.arguments = [NSArray arrayWithObjects:@"push", @"--tags", aRemoteBranch.remoteAlias, refspec, nil];
  [self launchTask:task withBlock:^{
    if ([task isError])
    {
      [self alertWithMessage: @"Push failed" description:[task.output UTF8String]];
    }

    aRemoteBranch.isNewRemoteBranch = NO;
    block();
  }];   
}







#pragma mark Utility methods


- (id) task
{
  GBTask* task = [[GBTask new] autorelease];
  task.repository = self;
  return task;
}

- (void) launchTask:(OATask*)aTask withBlock:(void(^)())block
{
  [aTask launchInQueue:self.dispatchQueue withBlock:block];
}

- (void) dispatchBlock:(void(^)())block
{
  dispatch_async(self.dispatchQueue, ^{
    dispatch_async(dispatch_get_main_queue(), block);
  });
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
