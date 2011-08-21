#import "GBRepository.h"
#import "GBRef.h"
#import "GBRemote.h"
#import "GBStage.h"
#import "GBStash.h"
#import "GBTask.h"
#import "GBTaskWithProgress.h"
#import "GBRemotesTask.h"
#import "GBHistoryTask.h"
#import "GBLocalRefsTask.h"
#import "GBSubmodulesTask.h"
#import "GBStashListTask.h"

#import "GBGitConfig.h"
#import "GBAskPassController.h"
#import "GBMainWindowController.h"

#import "OAPropertyListController.h"
#import "OABlockGroup.h"
#import "OABlockTable.h"
#import "NSFileManager+OAFileManagerHelpers.h"
#import "NSData+OADataHelpers.h"
#import "NSArray+OAArrayHelpers.h"
#import "NSString+OAGitHelpers.h"
#import "NSAlert+OAAlertHelpers.h"
#import "NSObject+OASelectorNotifications.h"

@interface GBRepository ()

@property(nonatomic, retain, readwrite) NSData* URLBookmarkData;
@property(nonatomic, retain) OABlockTable* blockTable;
@property(nonatomic, retain) GBGitConfig* config;
@property(nonatomic, assign) dispatch_queue_t dispatchQueue;
@property(nonatomic, assign, readwrite) NSUInteger commitsDiffCount;
@property(nonatomic, retain) NSMutableDictionary* tagsByCommitID;
@property(nonatomic, assign, readwrite, getter=isRebaseConflict) BOOL rebaseConflict;

- (void) loadCurrentLocalRefWithBlock:(void(^)())block;
- (void) loadLocalRefsWithBlock:(void(^)())block;

@end



@implementation GBRepository

@synthesize url;
@synthesize URLBookmarkData;
@dynamic path;
@synthesize dotGitURL;
@synthesize localBranches;
@synthesize remotes;
@synthesize tags;
@synthesize submodules;

@synthesize stage;
@synthesize currentLocalRef;
@synthesize currentRemoteBranch;
@synthesize localBranchCommits;
@synthesize dispatchQueue;
@synthesize lastError;
@synthesize blockTable;
@synthesize config;

@synthesize unmergedCommitsCount; // obsolete
@synthesize unpushedCommitsCount; // obsolete
@synthesize commitsDiffCount;

@synthesize rebaseConflict;

@synthesize tagsByCommitID;

@synthesize currentTaskProgress;
@synthesize currentTaskProgressStatus;


#pragma mark Init


- (void) dealloc
{
  NSLog(@"GBRepository#dealloc: %@", self);
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
  
  [url release]; url = nil;
  [URLBookmarkData release]; URLBookmarkData = nil;
  [dotGitURL release]; dotGitURL = nil;
  [localBranches release]; localBranches = nil;
  [remotes release]; remotes = nil;
  [tags release]; tags = nil;
  [stage release]; stage = nil;
  
  [currentLocalRef release]; currentLocalRef = nil;
  [currentRemoteBranch release]; currentRemoteBranch = nil;
  [localBranchCommits release]; localBranchCommits = nil;
  
  [blockTable release]; blockTable = nil;
  [config release]; config = nil;
  
  [submodules release]; submodules = nil;
  [tagsByCommitID release]; tagsByCommitID = nil;
  
  [currentTaskProgressStatus release]; currentTaskProgressStatus = nil;
  
  if (self.dispatchQueue) dispatch_release(self.dispatchQueue);
  self.dispatchQueue = nil;
    
  [super dealloc];
}


- (id) init
{
  if ((self = [super init]))
  {
    self.dispatchQueue = dispatch_queue_create("com.oleganza.gitbox.repository_queue", NULL);
    self.blockTable = [[OABlockTable new] autorelease];
    self.config = [GBGitConfig configForRepository:self];
  }
  return self;
}




+ (id) repositoryWithURL:(NSURL*)url
{
  GBRepository* r = [[self new] autorelease];
  r.url = [[[NSURL alloc] initFileURLWithPath:[url path] isDirectory:YES] autorelease]; // force ending slash "/" if needed
  return r;
}



+ (NSString*) supportedGitVersion
{
  return [GBTask bundledGitVersion];
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
  return [[[task UTF8OutputStripped] stringByReplacingOccurrencesOfString:@"git version" withString:@""] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}


+ (BOOL) isSupportedGitVersion:(NSString*)version
{
  if (!version) return NO;
  return [version compare:[self supportedGitVersion]] != NSOrderedAscending;
}


+ (BOOL) isValidRepositoryPath:(NSString*)aPath
{
  if (!aPath) return NO;
  if ([aPath rangeOfString:@"/.Trash/"].location != NSNotFound) return NO;
  
  BOOL isDirectory = NO;
  if ([[NSFileManager defaultManager] fileExistsAtPath:[aPath stringByAppendingPathComponent:@".git"] isDirectory:&isDirectory])
  {
    if (isDirectory)
    {
      return YES;
    }
  }
  
  // Bare repository:
  if ([[NSFileManager defaultManager] fileExistsAtPath:[aPath stringByAppendingPathComponent:@"HEAD"] isDirectory:&isDirectory])
  {
    if (isDirectory) return NO;
    if ([[NSFileManager defaultManager] fileExistsAtPath:[aPath stringByAppendingPathComponent:@"objects"] isDirectory:&isDirectory])
    {
      if (!isDirectory) return NO;
      if ([[NSFileManager defaultManager] fileExistsAtPath:[aPath stringByAppendingPathComponent:@"refs"] isDirectory:&isDirectory])
      {
        if (!isDirectory) return NO;
        return YES;
      }
    }    
  }
  return NO;
}

+ (BOOL) isValidRepositoryOrFolderURL:(NSURL*)aURL
{
  if (![aURL isFileURL]) return NO;
  NSString* aPath = [aURL path];
  if (!aPath) return NO;
  if ([aPath rangeOfString:@"/.Trash/"].location != NSNotFound) return NO;
  
  BOOL isDirectory = NO;
  if ([[NSFileManager defaultManager] fileExistsAtPath:aPath isDirectory:&isDirectory])
  {
    if (isDirectory)
    {
      return YES;
    }
  }
  return NO;
}

+ (BOOL) isAtLeastOneValidRepositoryOrFolderURL:(NSArray*)URLs
{
  for (NSURL* url in URLs)
  {
    if ([self isValidRepositoryOrFolderURL:url]) return YES;
  }
  return NO;
}


// OBSOLETE
+ (BOOL) validateRepositoryURL:(NSURL*)aURL withBlock:(void(^)(BOOL isValid))aBlock
{
  BOOL v = [self validateRepositoryURL:aURL];
  if (aBlock) aBlock(v);
  return v;
}

+ (BOOL) validateRepositoryURL:(NSURL*)aURL
{
  NSString* aPath = [aURL path];
  
  if (!aPath) return NO;
  
  if ([self isValidRepositoryPath:aPath])
  {
    return YES;
  }
  
  BOOL isDirectory;
  if (![[NSFileManager defaultManager] fileExistsAtPath:aPath isDirectory:&isDirectory])
  {
    [NSAlert message:NSLocalizedString(@"Folder does not exist.", @"") description:aPath];
    return NO;
  }
  
  if (!isDirectory)
  {
    [NSAlert message:NSLocalizedString(@"File is not a folder.", @"") description:aPath];
    return NO;
  }
  
  if (![NSFileManager isWritableDirectoryAtPath:aPath])
  {
    [NSAlert message:NSLocalizedString(@"No write access to the folder.", @"") description:aPath];
    return NO;
  }
  
  // Make app visible before popping an alert (otherwise it will look awkward)
  if (![NSApp isActive])
  {
    [NSApp activateIgnoringOtherApps:YES];
  }
  
  if ([NSAlert prompt:NSLocalizedString(@"The folder is not a git repository.\nMake it a repository?", @"App")
          description:aPath])
  {
    [self initRepositoryAtURL:aURL];
    return YES;
  }
  
  return NO;
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

+ (NSURL*) URLFromBookmarkData:(NSData*)bookmarkData
{
  if (!bookmarkData) return nil;
  if (![bookmarkData isKindOfClass:[NSData class]]) return nil;
  
  NSError* error = nil;
  NSURL* aURL = [NSURL URLByResolvingBookmarkData:bookmarkData
                                          options:NSURLBookmarkResolutionWithoutUI | NSURLBookmarkResolutionWithoutMounting
                                    relativeToURL:nil
                              bookmarkDataIsStale:NO
                                            error:&error];
  if (error)
  {
    NSLog(@"[GBRepository URLFromBookmarkData:]: Cannot create URL from bookmark data: %@", bookmarkData);
  }
  
  if (!aURL) return nil;
  if (![aURL path]) return nil;
  return aURL;
}


#pragma mark Properties



- (void) setUrl:(NSURL *)aURL
{
  if (aURL == url) return;
  
  [url release];
  url = [aURL retain];
  
  if (!url)
  {
    self.URLBookmarkData = nil;
  }
  else
  {
    NSError* error = nil;
    self.URLBookmarkData = [url bookmarkDataWithOptions:NSURLBookmarkCreationPreferFileIDResolution
                                includingResourceValuesForKeys:nil
                                                 relativeToURL:nil
                                                         error:&error];
    if (error)
    {
      NSLog(@"[GBRepository setUrl:]: Cannot create bookmark data for URL %@", url);
      self.URLBookmarkData = nil;
    }
  }
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

- (void) setTags:(NSArray *)newTags
{
  if (tags == newTags) return;
  
  [tags release];
  tags = [newTags retain];
    
  self.tagsByCommitID = [NSMutableDictionary dictionary];
  for (GBRef* tag in tags)
  {
    if (tag.commitId) [self.tagsByCommitID setObject:tag forKey:tag.commitId];
    else NSLog(@"WARNING: GBRepository setTags: tag.commitId is nil: %@", tag);
  }
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

- (NSString*) description
{
  return [NSString stringWithFormat:@"<GBRepository:%p %@>", self, self.url];
}

- (GBRef*) tagForCommit:(GBCommit*)aCommit
{
  if (!aCommit.commitId) return nil;
  return [self.tagsByCommitID objectForKey:aCommit.commitId];
}

- (NSArray*) tagsForCommit:(GBCommit*)aCommit
{
  if (![self tagForCommit:aCommit] && [self.tags count] < 1) return nil; // quick lookup in dictionary
  NSMutableArray* result = [NSMutableArray array];
  for (GBRef* tag in self.tags)
  {
    if ([tag.commitId isEqual:aCommit.commitId])
    {
      [result addObject:tag];
    }
  }
  return result;
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

- (GBRemote*) remoteForAlias:(NSString*)remoteAlias
{
  if (!remoteAlias) return nil;
  for (GBRemote* aRemote in self.remotes)
  {
    if ([aRemote.alias isEqual:remoteAlias])
    {
      return aRemote;
    }
  }
  return nil;
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
  return [[NSFileManager defaultManager] fileExistsAtPath:[[self path] stringByAppendingPathComponent:@".gitmodules"]];
}

- (NSURL*) URLForSubmoduleAtPath:(NSString*)submodulePath
{
  NSString* key = [NSString stringWithFormat:@"%@.%@.%@", @"submodule", [submodulePath stringWithEscapingConfigKeyPart], @"url"];
  NSString* urlString = [self.config stringForKey:key];
  if (!urlString || [urlString isEqualToString:@""]) return nil;
  return [NSURL URLWithString:urlString];
}

- (void) loadStashesWithBlock:(void(^)(NSArray*))block
{
  if (!block) return;
  
  block = [[block copy] autorelease];
  
  GBStashListTask* task = [[[GBStashListTask alloc] init] autorelease];
  task.repository = self;
  [self launchTask:task withBlock:^{
    block(task.stashes);
  }];
}

- (GBRemote*) firstRemote
{
  if ([self.remotes count] < 1) return nil;
  return [self.remotes objectAtIndex:0];
}




#pragma mark Update



- (void) updateLocalRefsWithBlock:(void(^)())aBlock
{
  aBlock = [[aBlock copy] autorelease];
  
  [self loadRemotesWithBlock:^{
    [self loadLocalRefsWithBlock:^{
      [self loadCurrentLocalRefWithBlock:^{
        [self.currentLocalRef loadConfiguredRemoteBranchWithBlock:^{
          if (aBlock) aBlock();
        }];
      }];
    }];
  }];
}


- (void) loadRemotesIfNeededWithBlock:(void(^)())aBlock
{
  if (self.remotes && [self.remotes count] > 0) 
  {
    if (aBlock) aBlock();
    return;
  }
  [self loadRemotesWithBlock:aBlock];
}

- (void) loadRemotesWithBlock:(void(^)())aBlock
{
  aBlock = [[aBlock copy] autorelease];
  GBRemotesTask* task = [GBRemotesTask task];
  task.repository = self;
  [self launchTask:task withBlock:^{
    
    for (GBRemote* newRemote in task.remotes)
    {
      for (GBRemote* oldRemote in self.remotes)
      {
        [newRemote copyInterestingDataFromRemoteIfApplicable:oldRemote];
      }
      [newRemote updateBranches];
    }
    
    self.remotes = task.remotes;
    if (aBlock) aBlock();
  }];
}


- (void) loadLocalRefsWithBlock:(void(^)())block
{
  block = [[block copy] autorelease];
  GBLocalRefsTask* task = [GBLocalRefsTask task];
  task.repository = self;
  [self launchTask:task withBlock:^{
    self.localBranches = task.branches;
    self.tags = task.tags;
    
    for (NSString* remoteAlias in task.remoteBranchesByRemoteAlias)
    {
      GBRemote* aRemote = [self.remotes objectWithValue:remoteAlias forKey:@"alias"];
      aRemote.branches = [task.remoteBranchesByRemoteAlias objectForKey:remoteAlias];
      [aRemote updateBranches];
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
    
    // Try to find a tag for this commit id.
    
    GBRef* tag = [self.tagsByCommitID objectForKey:ref.commitId];
    if (tag) ref = tag;
  }
  
  if (ref.name)
  {
    // Try to find an existing ref in the list
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
  
  [self updateConflictState];
  
  if (block) block();
}


- (void) updateConflictState
{
  self.rebaseConflict = ([[NSFileManager defaultManager] fileExistsAtPath:[[self.dotGitURL path] stringByAppendingPathComponent:@"rebase-apply"]]);
}


- (void) updateLocalBranchCommitsWithBlock:(void(^)())block
{
  if (!self.currentLocalRef)
  {
    if (block) block();
    return;
  }
  block = [[block copy] autorelease];
  GBHistoryTask* task = [GBHistoryTask task];
  task.repository = self;
  task.branch = self.currentLocalRef;
  if ([self doesRefExist:self.currentRemoteBranch])
  {
    task.joinedBranch = self.currentRemoteBranch;
  }

  [self launchTask:task withBlock:^{
    self.localBranchCommits = task.commits;
    [self updateUnmergedCommitsWithBlock:^{
      [self updateUnpushedCommitsWithBlock:^{
        if (block) block();
      }];
    }];
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
  [self launchTask:task withBlock:^{
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
  
  [self launchTask:task withBlock:^{
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

- (void) updateCommitsDiffCountWithBlock:(void(^)())block
{
  NSString* commitish1 = [self.currentLocalRef commitish];
  NSString* commitish2 = [self.currentRemoteBranch commitish];
  
  if (!commitish1 || !commitish2 || [commitish1 isEqualToString:@""] || [commitish2 isEqualToString:@""])
  {
    self.commitsDiffCount = 0;
    if (block) block();
    return;
  }
  
  block = [[block copy] autorelease];
  
  // There's a problem with blockTable here: if the branch was changed when this command was running, the result will be stale.
  //[self.blockTable addBlock:block forName:@"updateCommitsDiffCount" proceedIfClear:^{}];
  
  GBTask* task = [self task];
  NSString* query = [NSString stringWithFormat:@"%@...%@", commitish1, commitish2]; // '...' produces symmetric difference
  task.arguments = [NSArray arrayWithObjects:@"rev-list", query, @"--count",  nil];
  [self launchTask:task withBlock:^{
    if ([task isError])
    {
      self.lastError = [NSError errorWithDomain:@"Gitbox" code:1
                                       userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                 [task UTF8ErrorAndOutput], NSLocalizedDescriptionKey,
                                                 [NSNumber numberWithInt:[task terminationStatus]], @"terminationStatus",
                                                 [task command], @"command",
                                                 nil]];
    }
    NSString* countString = [task.output UTF8String];
    self.commitsDiffCount = (NSUInteger)[countString integerValue];
    if (block) block();
  }];
}



// A routine for configuring .gitmodules in .git/config. 
// 99.99% of users don't want to think about it, so it is a private method used by updateSubmodulesWithBlock:
- (void) initSubmodulesWithBlock:(void(^)())block
{
  block = [[block copy] autorelease];
  GBTask* task = [self task];
  task.arguments = [NSArray arrayWithObjects:@"submodule", @"init",  nil];
	[self launchTask:task withBlock:^{
		if ([task isError])
    {
			self.lastError = [NSError errorWithDomain:@"Gitbox" code:1
																	 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
																						 [task UTF8ErrorAndOutput], NSLocalizedDescriptionKey,
																						 [NSNumber numberWithInt:[task terminationStatus]], @"terminationStatus",
																						 [task command], @"command",
																						 nil]];
		}
    if (block) block();
	}];
}


// Updates list of submodules (NOT what 'git submodule update' does!) for this repository. 
// DOES NOT pull actual submodules or change their refs in any way. MK.

- (void) updateSubmodulesWithBlock:(void (^)())block
{
  // Quick check for common case: if file .gitmodules does not exist, we have no submodules
  if (![self doesHaveSubmodules])
  {
    self.submodules = [NSArray array];
    if (block) block();
    return;
  }
  
  [self.blockTable addBlock:block forName:@"updateSubmodules" proceedIfClear:^{
    [self initSubmodulesWithBlock:^{
      GBSubmodulesTask* task = [GBSubmodulesTask taskWithRepository:self];
      [self launchTask:task withBlock:^{
        
        // TODO: reuse submodules with the same name and update its status and URL
        
        self.submodules = task.submodules;
        [self.blockTable callBlockForName:@"updateSubmodules"];
      }];
    }];
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
  
  NSString* escapedName = [name stringWithEscapingConfigKeyPart];
  //NSLog(@"escapedName = %@", escapedName);
  [self.config setString:ref.remoteAlias
                  forKey:[NSString stringWithFormat:@"branch.%@.remote", escapedName] withBlock:^{
                    
    [self.config setString:[NSString stringWithFormat:@"refs/heads/%@", ref.name]
                    forKey:[NSString stringWithFormat:@"branch.%@.merge", escapedName] withBlock:^{
      if (block) block();
    }];

  }];
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
    [self launchTask:checkoutTask withBlock:^{
      [checkoutTask showErrorIfNeeded];
      [self configureTrackingRemoteBranch:ref withLocalName:name block:block];
    }];
  }
  else
  {
    if (block) block();
  }
}

- (void) checkoutNewBranchWithName:(NSString*)name commit:(GBCommit*)aCommit block:(void(^)())block
{
  block = [[block copy] autorelease];
  GBTask* checkoutTask = [self task];
  // Note: if commit is nil, then the command will be simply "git tag <name>"
  checkoutTask.arguments = [NSArray arrayWithObjects:@"checkout", @"-b", name, aCommit.commitId, nil];
  [self launchTask:checkoutTask withBlock:^{
    [checkoutTask showErrorIfNeeded];
    [self configureTrackingRemoteBranch:self.currentRemoteBranch withLocalName:name block:block];
  }];
}

- (void) createNewTagWithName:(NSString*)name commit:(GBCommit*)aCommit block:(void(^)())block
{
  block = [[block copy] autorelease];
  GBTask* aTask = [self task];
  // Note: if commit is nil, then the command will be simply "git tag <name>"
  aTask.arguments = [NSArray arrayWithObjects:@"tag", name, aCommit.commitId, nil]; 
  [self launchTask:aTask withBlock:^{
    [aTask showErrorIfNeeded];
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
    [self launchTask:task withBlock:^{
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
  description = [description stringByReplacingOccurrencesOfString:@"fatal: " withString:@""];
  description = [description stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
  description = [description stringByAppendingFormat:@"\n\nRepository: %@", self.path];
  
  NSAlert* alert = [[[NSAlert alloc] init] autorelease];
  [alert addButtonWithTitle:@"OK"];
  [alert setMessageText:message];
  [alert setInformativeText:description];
  [alert setAlertStyle:NSWarningAlertStyle];
  
  [[GBMainWindowController instance] sheetQueueAddBlock:^{
    [alert retain];
    [alert beginSheetModalForWindow:[[GBMainWindowController instance] window] 
                      modalDelegate:self
                     didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
                        contextInfo:NULL];
  }];
}

- (void) alertDidEnd:(NSAlert*)alert returnCode:(NSInteger)returnCode contextInfo:(void*)ref
{
  [[alert window] orderOut:nil];
  [[GBMainWindowController instance] sheetQueueEndBlock];
  [alert release];
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
  [self mergeCommitish:[aBranch nameWithRemoteAlias] withBlock:block];
}

- (void) mergeCommitish:(NSString*)commitish withBlock:(void(^)())block
{
  if (!commitish)
  {
    if (block) block();
    return;
  }
  block = [[block copy] autorelease];
  GBTask* task = [self task];
  task.arguments = [NSArray arrayWithObjects:@"merge", commitish, nil];
  [self launchTask:task withBlock:^{
    if ([task isError])
    {
      [self alertWithMessage: @"Merge failed" description:[task UTF8ErrorAndOutput]];
    }
    if (block) block();
  }];
}

- (void) cherryPickCommit:(GBCommit*)aCommit creatingCommit:(BOOL)creatingCommit withBlock:(void(^)())block
{
  if (!aCommit)
  {
    if (block) block();
    return;
  }
  
  block = [[block copy] autorelease];
  GBTask* task = [self task];
  if (creatingCommit)
  {
    task.arguments = [NSArray arrayWithObjects:@"cherry-pick", aCommit.commitId, nil];
  }
  else
  {
    task.arguments = [NSArray arrayWithObjects:@"cherry-pick", @"--no-commit", aCommit.commitId, nil];
  }

  [self launchTask:task withBlock:^{
    if (!creatingCommit || [task isError])
    {
      self.stage.currentCommitMessage = aCommit.message;
    }
    if ([task isError])
    {
      [self alertWithMessage: @"Cherry-pick failed" description:[task UTF8ErrorAndOutput]];
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
  [GBAskPassController launchedControllerWithAddress:aRemoteBranch.remote.URLString taskFactory:^{
    GBTask* task = [self taskWithProgress];
    task.arguments = [NSArray arrayWithObjects:@"pull", 
                           @"--tags", 
                           @"--force", 
                           @"--progress",
                           aRemoteBranch.remoteAlias, 
                           [NSString stringWithFormat:@"%@:refs/remotes/%@", 
                            aRemoteBranch.name, [aRemoteBranch nameWithRemoteAlias]],
                           nil];
    task.dispatchQueue = self.dispatchQueue;
    task.didTerminateBlock = ^{
      self.currentTaskProgress = 0.0;
      self.currentTaskProgressStatus = nil;

      if ([task isError])
      {
        [self alertWithMessage: @"Pull failed" description:[task UTF8ErrorAndOutput]];
      }
      if (block) block();
    };
    return (id)task;
  }];
}

- (void) fetchAllWithBlock:(void(^)())block
{
  [self fetchAllSilently:NO withBlock:block];
}

- (void) fetchAllSilently:(BOOL)silently withBlock:(void(^)())block
{
  [OABlockGroup groupBlock:^(OABlockGroup *group) {
    for (GBRemote* aRemote in self.remotes)
    {
      [group enter];
      [self fetchRemote:aRemote silently:silently withBlock:^{
        [group leave];
      }];
    }
  } continuation:block];
}


- (void) fetchRemote:(GBRemote*)aRemote withBlock:(void(^)())block
{
	[self fetchRemote:aRemote silently:NO withBlock:block];
}

- (void) fetchRemote:(GBRemote*)aRemote silently:(BOOL)silently withBlock:(void(^)())block
{
  block = [[block copy] autorelease];
  if (!aRemote)
  {
    if (block) block();
    return;
  }
  [GBAskPassController launchedControllerWithAddress:aRemote.URLString silent:silently taskFactory:^{
    GBTask* task = [self taskWithProgress];
    task.arguments = [NSArray arrayWithObjects:@"fetch", 
                       @"--tags",
                       @"--force",
                       @"--prune",
                       @"--progress",
                       aRemote.alias,
                       [aRemote defaultFetchRefspec], // Declaring a proper refspec is necessary to make autofetch expectations about remote alias to work. git show-ref should always return refs for alias XYZ.
                       nil];
    task.dispatchQueue = self.dispatchQueue;
    task.didTerminateBlock = ^{
      self.currentTaskProgress = 0.0;
      self.currentTaskProgressStatus = nil;

      if ([task isError])
      {
        self.lastError = [self errorWithCode:GBErrorCodeFetchFailed
                                 description:[NSString stringWithFormat:NSLocalizedString(@"Failed to fetch from %@",@"Error"), aRemote.alias]
                                      reason:[task UTF8ErrorAndOutput]
                                  suggestion:NSLocalizedString(@"Please check the URL or network settings.",@"Error")];
      }
      if (block) block();
      self.lastError = nil;
    };
    return (id)task;
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
  [GBAskPassController launchedControllerWithAddress:aRemoteBranch.remote.URLString taskFactory:^{
    GBTask* task = [self taskWithProgress];
    task.arguments = [NSArray arrayWithObjects:@"fetch", 
                      @"--tags", 
                      @"--force", 
                      @"--progress",
                      aRemoteBranch.remoteAlias, 
                      [NSString stringWithFormat:@"%@:refs/remotes/%@", 
                       aRemoteBranch.name, [aRemoteBranch nameWithRemoteAlias]],
                      nil];
    task.dispatchQueue = self.dispatchQueue;
    task.didTerminateBlock = ^{
      self.currentTaskProgress = 0.0;
      self.currentTaskProgressStatus = nil;
      if ([task isError])
      {
        self.lastError = [self errorWithCode:GBErrorCodeFetchFailed
                                 description:[NSString stringWithFormat:NSLocalizedString(@"Failed to fetch from %@",@"Error"), aRemoteBranch.remoteAlias]
                                      reason:[task UTF8ErrorAndOutput]
                                  suggestion:NSLocalizedString(@"Please check the URL or network settings.",@"Error")];
      }
      if (block) block();
      self.lastError = nil;
    };
    return (id)task;
  }];
}

- (void) pushWithBlock:(void(^)())block
{
  [self pushWithForce:NO block:block];
}

- (void) pushWithForce:(BOOL)forced block:(void(^)())block
{
  [self pushBranch:self.currentLocalRef toRemoteBranch:self.currentRemoteBranch forced:(BOOL)forced withBlock:block];
}

- (void) pushBranch:(GBRef*)aLocalBranch toRemoteBranch:(GBRef*)aRemoteBranch forced:(BOOL)forced withBlock:(void(^)())block
{
  block = [[block copy] autorelease];
  if (!aLocalBranch || !aRemoteBranch)
  {
    if (block) block();
    return;
  }
  GBRemote* aRemote = aRemoteBranch.remote;
  [GBAskPassController launchedControllerWithAddress:aRemoteBranch.remote.URLString taskFactory:^{
    GBTask* task = [self taskWithProgress];
    NSString* refspec = [NSString stringWithFormat:@"%@:%@", aLocalBranch.name, aRemoteBranch.name];
    
    task.arguments = [NSArray arrayWithObjects:@"push", @"--tags", @"--progress", nil];
    if (forced) task.arguments = [task.arguments arrayByAddingObject:@"--force"];
    task.arguments = [task.arguments arrayByAddingObject:aRemoteBranch.remoteAlias];
    task.arguments = [task.arguments arrayByAddingObject:refspec];
    
    task.dispatchQueue = self.dispatchQueue;
    task.didTerminateBlock = ^{
      self.currentTaskProgress = 0.0;
      self.currentTaskProgressStatus = nil;

      if ([task isError])
      {
        [self alertWithMessage: @"Push failed" description:[task UTF8ErrorAndOutput]];
      }
      else
      {
        // update remote branch commit id to avoid autofetching immediately after push.
        // Normally we have two separate instances of remote branches: one from "configured for local branch" and one from remote.branches.
        if (aLocalBranch.commitId && aRemoteBranch.name)
        {
          aRemoteBranch.commitId = aLocalBranch.commitId;
          if (aRemote)
          {
            for (GBRef* ref in [aRemote pushedAndNewBranches])
            {
              if (ref.name && aRemoteBranch.name && [ref.name isEqualToString:aRemoteBranch.name])
              {
                ref.commitId = aLocalBranch.commitId;
              }
            }
          }
        }
      }
      if (block) block();
    };
    return (id)task;
  }];
}

- (void) rebaseWithBlock:(void(^)())block
{
  block = [[block copy] autorelease];
  
  if (!self.currentRemoteBranch)
  {
    if (block) block();
  }
  
  GBRef* otherBranch = self.currentRemoteBranch;
  
  [self fetchRemote:otherBranch.remote withBlock:^{
    
    GBTask* taskContinue = [self task];
    taskContinue.arguments = [NSArray arrayWithObjects:@"rebase", @"--continue", nil];
    [self launchTask:taskContinue withBlock:^{
      GBTask* task = [self task];
      task.arguments = [NSArray arrayWithObjects:@"rebase", [otherBranch nameWithRemoteAlias], nil];
      [self launchTask:task withBlock:^{
        if ([task isError])
        {
          [self alertWithMessage:NSLocalizedString(@"Rebase failed",nil) description:[task UTF8ErrorAndOutput]];
        }
        if (block) block();
      }];
      
    }];
  }];
}


- (void) rebaseCancelWithBlock:(void(^)())block
{
  block = [[block copy] autorelease];
  GBTask* task = [self task];
  task.arguments = [NSArray arrayWithObjects:@"rebase", @"--abort", nil];
  [self launchTask:task withBlock:^{
    if ([task isError])
    {
      [self alertWithMessage:NSLocalizedString(@"Failed to cancel rebase",nil) description:[task UTF8ErrorAndOutput]];
    }
    if (block) block();
  }];
}

- (void) rebaseSkipWithBlock:(void(^)())block
{
  block = [[block copy] autorelease];
  GBTask* task = [self task];
  task.arguments = [NSArray arrayWithObjects:@"rebase", @"--skip", nil];
  [self launchTask:task withBlock:^{
    if ([task isError])
    {
      [self alertWithMessage:NSLocalizedString(@"Rebase failed",nil) description:[task UTF8ErrorAndOutput]];
    }
    if (block) block();
  }];
}

- (void) rebaseContinueWithBlock:(void(^)())block
{
  block = [[block copy] autorelease];
  GBTask* task = [self task];
  task.arguments = [NSArray arrayWithObjects:@"rebase", @"--continue", nil];
  [self launchTask:task withBlock:^{
    if ([task isError])
    {
      [self alertWithMessage:NSLocalizedString(@"Rebase failed",nil) description:[task UTF8ErrorAndOutput]];
    }
    if (block) block();
  }];
}



- (void) resetStageWithBlock:(void(^)())block
{
  block = [[block copy] autorelease];
    
  GBTask* task = [self task];
  task.arguments = [NSArray arrayWithObjects:@"reset", @"--hard", @"HEAD", nil];
  [self launchTask:task withBlock:^{
    self.stage.currentCommitMessage = nil;
    if ([task isError])
    {
      [self alertWithMessage:NSLocalizedString(@"Reset failed",nil) description:[task UTF8ErrorAndOutput]];
    }
    if (block) block();
  }];
}


- (void) resetToCommit:(GBCommit*)aCommit withBlock:(void(^)())block
{
  block = [[block copy] autorelease];
  
  GBTask* task = [self task];
  task.arguments = [NSArray arrayWithObjects:@"reset", @"--hard", aCommit.commitId, nil];
  [self launchTask:task withBlock:^{
    self.stage.currentCommitMessage = nil;
    if ([task isError])
    {
      [self alertWithMessage:NSLocalizedString(@"Branch reset failed",nil) description:[task UTF8ErrorAndOutput]];
    }
    if (block) block();
  }];  
}


- (void) stashChangesWithMessage:(NSString*)message block:(void(^)())block
{
  block = [[block copy] autorelease];
  
  GBTask* task = [self task];
  
  message = [message stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
  task.arguments = [NSArray arrayWithObjects:@"stash", @"save", message, nil];
  [self launchTask:task withBlock:^{
    if ([task isError])
    {
      [self alertWithMessage:[NSString stringWithFormat:NSLocalizedString(@"Failed to stash “%@”",nil), message] description:[task UTF8ErrorAndOutput]];
    }
    if (block) block();
  }];
}


- (void) applyStash:(GBStash*)aStash withBlock:(void(^)())block
{
  block = [[block copy] autorelease];
  
  if (!aStash)
  {
    if (block) block();
    return;
  }
  
  GBTask* task = [self task];
  task.arguments = [NSArray arrayWithObjects:@"stash", @"apply", aStash.ref, nil];
  [self launchTask:task withBlock:^{
    if ([task isError])
    {
      [self alertWithMessage:[NSString stringWithFormat:NSLocalizedString(@"Failed to apply stash “%@”",nil), aStash.message] description:[task UTF8ErrorAndOutput]];
    }
    if (block) block();
  }];
}


- (void) removeStashes:(NSArray*)theStashes withBlock:(void(^)())block
{
  [OABlockGroup groupBlock:^(OABlockGroup *group) {
    for (GBStash* stash in [theStashes reversedArray]) // using reversed Array so that stash.ref remains valid (it is relative to the top of the stash stack)
    {
      [group enter];
      GBTask* task = [self task];
      task.arguments = [NSArray arrayWithObjects:@"stash", @"drop", stash.ref, nil];
      [self launchTask:task withBlock:^{
        if ([task isError])
        {
          [self alertWithMessage:[NSString stringWithFormat:NSLocalizedString(@"Failed to remove stash %@",nil), stash.ref] description:[task UTF8ErrorAndOutput]];
        }
        [group leave];
      }];
    }
  } continuation:block];
}


- (void) removeRefs:(NSArray*)refs withBlock:(void(^)())block
{
  [OABlockGroup groupBlock:^(OABlockGroup *group) {
    for (GBRef* ref in refs)
    {
      [group enter];
      GBTask* task = [self task];
      if ([ref isTag])
      {
        task.arguments = [NSArray arrayWithObjects:@"tag", @"-d", ref.name, nil];
      }
      else
      {
        task.arguments = [NSArray arrayWithObjects:@"branch", @"-D", ref.name, nil];
      }
      
      [self launchTask:task withBlock:^{
        if ([task isError])
        {
          [self alertWithMessage:[NSString stringWithFormat:NSLocalizedString(@"Failed to remove ref %@",nil), ref.name] description:[task UTF8ErrorAndOutput]];
        }
        [group leave];
      }];
    }
  } continuation:block];
}



#pragma mark Utility methods


- (id) task
{
  GBTask* task = [[GBTask new] autorelease];
  task.repository = self;
  return task;
}

- (id) taskWithProgress
{
  GBTaskWithProgress* task = [[GBTaskWithProgress new] autorelease];
  task.repository = self;
  task.progressUpdateBlock = ^{
    self.currentTaskProgress = task.progress;
    self.currentTaskProgressStatus = task.status;
    
    if (task.progress >= 99.9)
    {
      self.currentTaskProgress = 0.0;
      self.currentTaskProgressStatus = @"";
    }
    
    [self notifyWithSelector:@selector(repositoryDidUpdateProgress:)];
  };
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

@end
