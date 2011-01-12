#import "GBModels.h"

#import "GBTask.h"
#import "GBRemotesTask.h"
#import "GBHistoryTask.h"
#import "GBLocalRefsTask.h"

#import "NSFileManager+OAFileManagerHelpers.h"
#import "NSData+OADataHelpers.h"
#import "NSArray+OAArrayHelpers.h"
#import "NSString+OAGitHelpers.h"
#import "OAPropertyListController.h"
#import "OABlockGroup.h"

@interface GBRepository ()

- (void) captureErrorForTask:(OATask*)aTask withBlock:(NSError*(^)())block continuation:(void(^)())continuation;

- (void) loadCurrentLocalRefWithBlock:(void(^)())block;
- (void) loadLocalRefsWithBlock:(void(^)())block;
- (void) loadRemotesWithBlock:(void(^)())block;

@end



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
@synthesize lastError;

@synthesize unmergedCommitsCount;
@synthesize unpushedCommitsCount;


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
  if ((self = [super init]))
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
  return @"1.7.3.2";
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
  
  BOOL isDirectory = NO;
  if ([[NSFileManager defaultManager] fileExistsAtPath:[aPath stringByAppendingPathComponent:@".git"] isDirectory:&isDirectory])
  {
    if (isDirectory)
    {
      return aPath;
    }
  }
  return nil;
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

+ (void) configureUTF8WithBlock:(void(^)())block
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

+ (void) configureName:(NSString*)name email:(NSString*)email withBlock:(void(^)())block
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

- (NSUInteger) totalPendingChanges
{
  NSUInteger changes = [self.stage totalPendingChanges];
  NSUInteger commits = self.unpushedCommitsCount + self.unmergedCommitsCount;
  return commits + changes;
}








#pragma mark Interrogation




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

- (NSArray*) commits
{
  return self.localBranchCommits;
}

- (BOOL) doesRefExist:(GBRef*)ref
{
  // For now, the only case when ref can be created in UI, but does not have any commit id is a new remote branch.
  // This method will return NO only if the ref is a remote branch and not found in currently loaded remote branches.
  
  if (!ref) return NO;
  if (![ref isRemoteBranch]) return YES;
  if (!ref.name)
  {
    NSLog(@"WARNING: %@ %@ ref %@ is expected to have a name", [self class], NSStringFromSelector(_cmd), ref);
    return NO;
  }
  
  // Note: don't use ref.remote to avoid stale data (just in case)
  GBRemote* remote = [self.remotes objectWithValue:ref.remoteAlias forKey:@"alias"];
  
  if (!remote) return NO;
  
  return [[remote.branches valueForKey:@"name"] containsObject:ref.name];
}

- (BOOL) doesHaveSubmodules
{
  NSFileManager* fileManager   = [[[NSFileManager alloc] init] autorelease];
  NSString* dotGitModulesPath = [[NSURL URLWithString:@".gitmodule" relativeToURL: [self url]] path];

  return [fileManager fileExistsAtPath:dotGitModulesPath];
  
}



#pragma mark Update




- (void) updateLocalRefsWithBlock:(void(^)())block
{
  block = [[block copy] autorelease];
  
  [self loadRemotesWithBlock:^{
    [self loadLocalRefsWithBlock:^{
      [self loadCurrentLocalRefWithBlock:^{
        [self.currentLocalRef loadConfiguredRemoteBranchWithBlock:^{
          if (block) block();
        }];
      }];
    }];
  }];
  
}


- (void) loadRemotesWithBlock:(void(^)())block
{
  block = [[block copy] autorelease];
  GBRemotesTask* task = [GBRemotesTask task];
  task.repository = self;
  [task launchWithBlock:^{
    
    for (GBRemote* newRemote in task.remotes)
    {
      for (GBRemote* oldRemote in self.remotes)
      {
        [newRemote copyInterestingDataFromRemoteIfApplicable:oldRemote];
      }
      [newRemote updateNewBranches];
    }
    
    self.remotes = task.remotes;
    if (block) block();
  }];
}


- (void) loadLocalRefsWithBlock:(void(^)())block
{
  block = [[block copy] autorelease];
  GBLocalRefsTask* task = [GBLocalRefsTask task];
  task.repository = self;
  [task launchWithBlock:^{
    self.localBranches = task.branches;
    self.tags = task.tags;
    
    for (NSString* remoteAlias in task.remoteBranchesByRemoteAlias)
    {
      GBRemote* aRemote = [self.remotes objectWithValue:remoteAlias forKey:@"alias"];
      aRemote.branches = [task.remoteBranchesByRemoteAlias objectForKey:remoteAlias];
      [aRemote updateNewBranches];
    }
    
    if (block) block();
  }];
}


- (void) loadCurrentLocalRefWithBlock:(void(^)())block
{
  NSError* outError = nil;
  NSString* HEAD = [NSString stringWithContentsOfURL:[self gitURLWithSuffix:@"HEAD"]
                                            encoding:NSUTF8StringEncoding 
                                               error:&outError];
  if (!HEAD)
  {
    NSLog(@"%@ %@ error: %@", [self class], NSStringFromSelector(_cmd), outError);
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
  
  if (ref.name)
  {
    // try to find an existing ref in the list
    NSArray* refsList = self.localBranches;
    if ([ref isTag]) refsList = self.tags;
    GBRef* existingRef = [refsList objectWithValue:ref.name forKey:@"name"];
    if (existingRef)
    {
      ref = existingRef;
    }
    else
    {
      //NSLog(@"WARNING: %@ %@ cannot find head ref %@ in local branches or tags.", [self class], NSStringFromSelector(_cmd), ref);
    }
  }
  self.currentLocalRef = ref;
  if (block) block();
}



//#warning Deprecated method loadCurrentLocalRef
//- (GBRef*) loadCurrentLocalRef
//{
//  NSError* outError = nil;
//  NSString* HEAD = [NSString stringWithContentsOfURL:[self gitURLWithSuffix:@"HEAD"]
//                                            encoding:NSUTF8StringEncoding 
//                                               error:&outError];
//  if (!HEAD)
//  {
//    NSLog(@"GBRepository: loadcurrentLocalRef error: %@", outError);
//  }
//  HEAD = [HEAD stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
//  NSString* refprefix = @"ref: refs/heads/";
//  GBRef* ref = [[GBRef new] autorelease];
//  ref.repository = self;
//  if ([HEAD hasPrefix:refprefix])
//  {
//    ref.name = [HEAD substringFromIndex:[refprefix length]];
//  }
//  else // assuming SHA1 ref
//  {
//    ref.commitId = HEAD;
//  }
//  
//  return ref;
//}











- (void) updateLocalBranchCommitsWithBlock:(void(^)())block
{
  block = [[block copy] autorelease];
  GBHistoryTask* task = [GBHistoryTask task];
  task.repository = self;
  task.branch = self.currentLocalRef;
  if ([self doesRefExist:self.currentRemoteBranch])
  {
    task.joinedBranch = self.currentRemoteBranch;
  }

  [task launchWithBlock:^{
    
    NSString* newTopCommitId = [[task.commits objectAtIndex:0 or:nil] commitId];
    self.topCommitId = newTopCommitId;
    self.localBranchCommits = task.commits;
    
    if (block) block();
  }];
}

- (void) updateUnmergedCommitsWithBlock:(void(^)())block
{
  if (![self doesRefExist:self.currentRemoteBranch]) // no commits to be unmerged, returning now
  {
    if (block) block();
    return;
  }
  
  block = [[block copy] autorelease];
  GBHistoryTask* task = [GBHistoryTask task];
  task.repository = self;
  task.branch = self.currentRemoteBranch;
  task.substructedBranch = self.currentLocalRef;
  [task launchWithBlock:^{
    NSArray* allCommits = self.localBranchCommits;
    self.unmergedCommitsCount = [task.commits count];
    for (GBCommit* commit in task.commits)
    {
      NSUInteger index = [allCommits indexOfObject:commit];
      if (index !=  NSNotFound)
      {
        commit = [allCommits objectAtIndex:index];
        commit.syncStatus = GBCommitSyncStatusUnmerged;
      }
    }
    if (block) block();
  }];  
}

- (void) updateUnpushedCommitsWithBlock:(void(^)())block
{
  block = [[block copy] autorelease];
  if (!self.currentRemoteBranch)
  {
    self.unpushedCommitsCount = 0;
    if (block) block();
    return;
  }
  
  GBHistoryTask* task = [GBHistoryTask task];
  task.repository = self;
  task.branch = self.currentLocalRef;
  if ([self doesRefExist:self.currentRemoteBranch])
  {
    task.substructedBranch = self.currentRemoteBranch;
  }
  
  [task launchWithBlock:^{
    NSArray* allCommits = self.localBranchCommits;
    self.unpushedCommitsCount = [task.commits count];
    for (GBCommit* commit in task.commits)
    {
      NSUInteger index = [allCommits indexOfObject:commit];
      if (index !=  NSNotFound)
      {
        commit = [allCommits objectAtIndex:index];
        commit.syncStatus = GBCommitSyncStatusUnpushed;
      }
    }
    if (block) block();
  }];
}


- (void) initSubmodules
{
  GBTask* task = [self task];
  task.arguments = [NSArray arrayWithObjects:@"submodule", @"init",  nil];
	[task launchWithBlock:^{
		if ([task isError])
    {
			[NSError errorWithDomain:@"Gitbox" code:1
																	 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
																						 [task.output UTF8String], NSLocalizedDescriptionKey,
																						 [NSNumber numberWithInt:[task terminationStatus]], @"terminationStatus",
																						 [task command], @"command",
																						 nil]];
		}
    else
    {
			//NSLog(@"GBCloningRepositoryController: did finish submodule init at %@", [self path]);
		}		
	}];
  [self updateSubmodulesWithBlock:NULL];
}


/* Updates list of submodules (NOT what git submodule update does!) for this repository. DOES NOT pull actual submodules or
 * change their refs in any way. MK.
 */
- (void) updateSubmodulesWithBlock:(void (^)())block
{
  /* 1. Run git submodule status to fetch status of known submodules.
   * 2. For each submodule, use git config --get submodule.$name.url to fetch submodule URL. Example: git config --get submodule.vendor/rails.url.
   * 3. Update submodules list.
   * 4. Execute block if it is given.
   */

  // 1
  GBTask* statusTask = [self task];
  statusTask.arguments = [NSArray arrayWithObjects:@"submodule", @"status", nil];
  [statusTask launchWithBlock:^{
    if ([statusTask isError])
    {
      // TODO: logging, alert
    }

    /* Example (from Express.js repository):

     688b96c28e485da80211218ed5fd8c9f70a26be4 support/connect (0.5.2-7-g688b96c)
     ccefcd28dbb30d9a38a6fd12a50e77e8c461b4d3 support/connect-form (0.2.0)
     b1d822e99ccfb49f729f69d38dd66b2ce1fc501e support/ejs (0.2.1)
     da39f132bc2880a7eec013217b8f2f496ed5d2b1 support/expresso (0.7.0)
     +42b8e0e19b226bc2fabfa06fe013340e3d5677a0 support/haml (0.4.4-3-g42b8e0e)
     c6ecf33acbaac8ecf63deb557e116a0ef719884c support/jade (0.6.1)
     607f8734e80774a098f084a6ef66934787b7f33f support/should (0.0.3-6-g607f873)

     when none of the submodules was initialized, git adds minus in front of the SHA (example from Jade repository):
     
     -b1d822e99ccfb49f729f69d38dd66b2ce1fc501e benchmarks/ejs
     -382bc11ce4fd03403bcf2c0ed5545a4c891b60c2 benchmarks/haml
     -34fb092db3fff6d3b95a361dea4c21b63b8553c9 benchmarks/haml-js
     -502d444ebd6c0589a14cc20e951d5b34a30d46c7 support/coffee-script
     -2ea263d1b64d318edeed4abe45a0f4ebae80bbff support/expresso
     -805b0a69e1b357dcf2c4d54486dbcd7d6ac3d427 support/markdown
     -738177239c6b55521a1b0cb12aadccb794eb1609 support/sass     

     
     that is, the output looks like this:
     
     [space][optional + or -][SHA1 of commit submodule is pinned to][space][submodule path][the rest]
     */
    NSScanner* scanner = [NSScanner scannerWithString:[[statusTask output] UTF8String]];
    [scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@""]];

    while ([scanner isAtEnd] == NO)
    {
      [scanner scanString:@" " intoString:NULL];
      // optional plus or minus
      NSString* leadingChar = nil;

      [scanner scanCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"+-"] intoString:&leadingChar];

      // commit submodule is pinned down to
      NSString* submoduleRef = nil;
      if (![scanner scanUpToString:@" " intoString:&submoduleRef]) {
        // TOOD: log an error
      }

      // space
      if (![scanner scanString:@" " intoString:NULL]) {
        // TODO: log an error
      }

      // submodule path
      NSString* submodulePath = nil;
      if (![scanner scanUpToString:@" " intoString:&submodulePath]) {
        // TOOD: log an error
      }

      /* from there on there may or may not be any other content in the line.
       * In any case, it is irrelevant to us: we know submodule ref and we don't care
       * what branch/tag that commit belongs to. MK.
       */
      [scanner scanUpToString:@"\n" intoString:NULL];
      [scanner scanString:@"\n" intoString:NULL];

      NSLog(@"Repository = %@, leading char = %@, submoduleRef = %@, submodulePath = %@", [self.url path], leadingChar, submoduleRef, submodulePath);
      // TODO      
    }

    if (block) block();
  }];
}






#pragma mark Mutation methods


- (void) configureTrackingRemoteBranch:(GBRef*)ref withLocalName:(NSString*)name block:(void(^)())block
{
  block = [[block copy] autorelease];
  
  if (!ref || ![ref isRemoteBranch] || !name)
  {
    if (block) block();
    return;
  }
  
  [OABlockGroup groupBlock:^(OABlockGroup* blockGroup){
    GBTask* task1 = [self task];
    task1.arguments = [NSArray arrayWithObjects:@"config", 
                       [NSString stringWithFormat:@"branch.%@.remote", name], 
                       ref.remoteAlias, 
                       nil];
    [blockGroup enter];
    [self launchTask:task1 withBlock:^{
      [blockGroup leave];
    }];
    GBTask* task2 = [self task];
    task2.arguments = [NSArray arrayWithObjects:@"config", 
                       [NSString stringWithFormat:@"branch.%@.merge", name],
                       [NSString stringWithFormat:@"refs/heads/%@", ref.name],
                       nil];
    [blockGroup enter];
    [self launchTask:task2 withBlock:^{
      [task2 showErrorIfNeeded];
      [blockGroup leave];
    }];
  } continuation:block];
}


- (void) checkoutRef:(GBRef*)ref withBlock:(void(^)())block
{
  block = [[block copy] autorelease];
  GBTask* task = [self task];
  task.arguments = [NSArray arrayWithObjects:@"checkout", [ref commitish], nil];
  [self launchTask:task withBlock:^{
    [task showErrorIfNeeded];
    if (block) block();
  }];
}

- (void) checkoutRef:(GBRef*)ref withNewName:(NSString*)name block:(void(^)())block
{
  block = [[block copy] autorelease];
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
    if (block) block();
  }
}

- (void) checkoutNewBranchWithName:(NSString*)name block:(void(^)())block
{
  block = [[block copy] autorelease];
  GBTask* checkoutTask = [self task];
  checkoutTask.arguments = [NSArray arrayWithObjects:@"checkout", @"-b", name, nil];
  [checkoutTask launchWithBlock:^{
    [checkoutTask showErrorIfNeeded];
    [self configureTrackingRemoteBranch:self.currentRemoteBranch withLocalName:name block:block];
  }];
}

- (void) commitWithMessage:(NSString*) message block:(void(^)())block
{
  block = [[block copy] autorelease];
  if (message && [message length] > 0)
  {
    GBTask* task = [self task];
    task.arguments = [NSArray arrayWithObjects:@"commit", @"-m", message, nil];
    [task launchWithBlock:^{
      [task showErrorIfNeeded];
      if (block) block();
    }];
  }
  else
  {
    if (block) block();
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

- (void) fetchCurrentBranchWithBlock:(void(^)())block
{
  block = [[block copy] autorelease];
  if (self.currentRemoteBranch && [self.currentRemoteBranch isRemoteBranch])
  {
    [self fetchBranch:self.currentRemoteBranch withBlock:block];
  }
  else
  {
    if (block) block();
  }  
}

- (void) pullOrMergeWithBlock:(void(^)())block
{
  block = [[block copy] autorelease];
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
    if (block) block();
  }
}

- (void) mergeBranch:(GBRef*)aBranch withBlock:(void(^)())block
{
  block = [[block copy] autorelease];
  GBTask* task = [self task];
  task.arguments = [NSArray arrayWithObjects:@"merge", [aBranch nameWithRemoteAlias], nil];
  [self launchTask:task withBlock:^{
    if ([task isError])
    {
      [self alertWithMessage: @"Merge failed" description:[task.output UTF8String]];
    }
    if (block) block();
  }];
}

- (void) pullBranch:(GBRef*)aRemoteBranch withBlock:(void(^)())block
{
  block = [[block copy] autorelease];
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
    if (block) block();
  }];
}

- (void) fetchRemote:(GBRemote*)aRemote withBlock:(void(^)())block
{
  if (!aRemote)
  {
    if (block) block();
    return;
  }
  GBTask* task = [self task];
  task.arguments = [NSArray arrayWithObjects:@"fetch", 
                     @"--tags",
                     @"--force",
                     @"--prune",
                     aRemote.alias,
                     [aRemote defaultFetchRefspec], // Declaring a proper refspec is necessary to make autofetch expectations about remote alias to work. git show-ref should always return refs for alias XYZ.
                     nil];
  
  [self launchTask:task withBlock:^{
    [self captureErrorForTask:task
                    withBlock:^(){
                      return [self errorWithCode:GBErrorCodeFetchFailed
                                     description:[NSString stringWithFormat:NSLocalizedString(@"Failed to fetch from %@",@"Error"), aRemote.alias]
                                          reason:[task.output UTF8String]
                                      suggestion:NSLocalizedString(@"Please check the URL or network settings.",@"Error")];
                      
                    }
                 continuation:block];
  }];  
}


- (void) fetchBranch:(GBRef*)aRemoteBranch withBlock:(void(^)())block
{
  block = [[block copy] autorelease];
  if (!aRemoteBranch)
  {
    if (block) block();
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
    [self captureErrorForTask:task
                    withBlock:^(){
                      return [self errorWithCode:GBErrorCodeFetchFailed
                                     description:[NSString stringWithFormat:NSLocalizedString(@"Failed to fetch from %@",@"Error"), aRemoteBranch.remoteAlias]
                                          reason:[task.output UTF8String]
                                      suggestion:NSLocalizedString(@"Please check the URL or network settings.",@"Error")];
                                 }
                 continuation:block];
  }];
}

- (void) pushWithBlock:(void(^)())block
{
  [self pushBranch:self.currentLocalRef toRemoteBranch:self.currentRemoteBranch withBlock:block];
}

- (void) pushBranch:(GBRef*)aLocalBranch toRemoteBranch:(GBRef*)aRemoteBranch withBlock:(void(^)())block
{
  block = [[block copy] autorelease];
  if (!aLocalBranch || !aRemoteBranch)
  {
    if (block) block();
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

    if (block) block();
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

- (NSError*) errorWithCode:(GBErrorCode)aCode
               description:(NSString*)aDescription
                    reason:(NSString*)aReason
                suggestion:(NSString*)aSuggestion
{
  return [NSError errorWithDomain:GBErrorDomain
                             code:aCode
                         userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                   aDescription, NSLocalizedDescriptionKey,
                                   aReason, NSLocalizedFailureReasonErrorKey,
                                   aSuggestion, NSLocalizedRecoverySuggestionErrorKey,
                                   nil]];
}

- (void) captureErrorForTask:(OATask*)aTask withBlock:(NSError*(^)())block continuation:(void(^)())continuation
{
  if ([aTask isError])
  {
    self.lastError = block ? block() : nil;
  }
  if (continuation) continuation();
  self.lastError = nil;
}

@end
