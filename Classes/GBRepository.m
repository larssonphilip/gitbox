#import "GBRepository.h"
#import "GBRef.h"
#import "GBRemote.h"
#import "GBStage.h"
#import "GBStash.h"
#import "GBSubmodule.h"
#import "GBTask.h"
#import "GBTaskWithProgress.h"
#import "GBRemotesTask.h"
#import "GBHistoryTask.h"
#import "GBLocalRefsTask.h"
#import "GBSubmodulesTask.h"
#import "GBStashListTask.h"
#import "GBVersionComparator.h"
#import "GBLocalRemoteAssociationTask.h"

#import "GitRepository.h"
#import "GitConfig.h"

#import "GBGitConfig.h"
#import "GBAuthenticatedTask.h"
#import "GBMainWindowController.h"

#import "GitRepository.h"

#import "OAPropertyListController.h"
#import "OABlockGroup.h"
#import "OABlockTable.h"
#import "OABlockTransaction.h"
#import "NSFileManager+OAFileManagerHelpers.h"
#import "NSData+OADataHelpers.h"
#import "NSArray+OAArrayHelpers.h"
#import "NSString+OAGitHelpers.h"
#import "NSString+OAStringHelpers.h"
#import "NSAlert+OAAlertHelpers.h"
#import "NSObject+OASelectorNotifications.h"

@interface GBRepository ()

@property(nonatomic, strong, readwrite) NSData* URLBookmarkData;
@property(nonatomic, strong) OABlockTable* blockTable;
@property(nonatomic, strong, readwrite) OABlockTransaction* blockTransaction;
@property(nonatomic, strong, readwrite) GBGitConfig* config;
@property(nonatomic, assign, readwrite) NSUInteger commitsDiffCount;
@property(nonatomic, strong) NSMutableDictionary* tagsByCommitID;

- (void) updateCurrentLocalRefWithBlock:(void(^)())block;
- (void) loadLocalRefsWithBlock:(void(^)())block;

- (id) taskWithProgress;
- (id) authenticatedTaskWithAddress:(NSString*)address;

@end



@implementation GBRepository {
	dispatch_queue_t remoteDispatchQueue;
}

@synthesize url;
@synthesize dispatchQueue;
@synthesize URLBookmarkData;
@dynamic path;
@synthesize dotGitURL;
@synthesize localBranches;
@synthesize remotes;
@synthesize tags;
@synthesize submodules=_submodules;
@synthesize libgitRepository;

@synthesize stage;
@synthesize currentLocalRef;
@synthesize currentRemoteBranch;
@synthesize localBranchCommits;
@synthesize lastError;
@synthesize blockTable;
@synthesize blockTransaction;
@synthesize config;

@synthesize unmergedCommitsCount; // obsolete
@synthesize unpushedCommitsCount; // obsolete
@synthesize commitsDiffCount;

@synthesize tagsByCommitID;

@synthesize currentTaskProgress;
@synthesize currentTaskProgressStatus;

@synthesize authenticationFailed;
@synthesize authenticationCancelledByUser;



#pragma mark Init


- (void) dealloc
{
	NSLog(@"GBRepository#dealloc: %@", self);
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	
	 url = nil;
	 tags = nil;
	
	stage.repository = nil;
	
}


- (id) init
{
	if ((self = [super init]))
	{
		// Limit global number of queues to avoid high load on CPU and disk.
		static int queueId = 0;
#define GBRepoDispatchQueuesMax 6
		static dispatch_queue_t queues[GBRepoDispatchQueuesMax] = {NULL, NULL, NULL, NULL, NULL, NULL};
		static dispatch_once_t onceToken = 0;
		dispatch_once(&onceToken, ^{
			queues[0] = dispatch_queue_create("com.oleganza.gitbox.repo_local_task_queue1", NULL);
			queues[1] = dispatch_queue_create("com.oleganza.gitbox.repo_local_task_queue2", NULL);
			queues[2] = dispatch_queue_create("com.oleganza.gitbox.repo_local_task_queue3", NULL);
			queues[3] = dispatch_queue_create("com.oleganza.gitbox.repo_local_task_queue4", NULL);
			queues[4] = dispatch_queue_create("com.oleganza.gitbox.repo_local_task_queue5", NULL);
			queues[5] = dispatch_queue_create("com.oleganza.gitbox.repo_local_task_queue6", NULL);
		});
		
		dispatchQueue = queues[(queueId++) % GBRepoDispatchQueuesMax];
		remoteDispatchQueue = dispatch_queue_create("com.oleganza.gitbox.repo_remote_task_queue", NULL);
		
		self.blockTable = [OABlockTable new];
		self.blockTransaction = [OABlockTransaction new];
		self.config = [GBGitConfig configForRepository:self];
	}
	return self;
}

- (void) setDispatchQueue:(dispatch_queue_t)aDispatchQueue
{
	if (aDispatchQueue)
	{
		dispatchQueue = aDispatchQueue;
	}
}


+ (id) repositoryWithURL:(NSURL*)url
{
	GBRepository* r = [self new];
	r.url = [[NSURL alloc] initFileURLWithPath:[url path] isDirectory:YES]; // force ending slash "/" if needed
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
	
	url = aURL;
	
	if (!url)
	{
		self.URLBookmarkData = nil;
		self.libgitRepository = nil;
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
		
		self.libgitRepository = [[GitRepository alloc] init];
		self.libgitRepository.URL = url;
	}
}

- (NSURL*) dotGitURL
{
	if (!dotGitURL)
	{
		self.dotGitURL = [self.url URLByAppendingPathComponent:@".git"];
	}
	return dotGitURL;
}

- (GBStage*) stage
{
	if (!stage)
	{
		self.stage = [GBStage new];
		stage.repository = self;
	}
	return stage;
}

- (NSArray*) localBranches
{
	if (!localBranches) self.localBranches = [NSArray array];
	return localBranches;
}

- (NSArray*) tags
{
	if (!tags) self.tags = [NSArray array];
	return tags;
}

- (void) setTags:(NSArray *)newTags
{
	if (tags == newTags) return;
	
	tags = newTags;
    
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
	return remotes;
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
	if (![self tagForCommit:aCommit] && self.tags.count < 1) return nil; // quick lookup in dictionary
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

- (GBRef*) existingRefForRef:(GBRef*)aRef
{
	if (!aRef) return nil;
	
	if (aRef.isRemoteBranch)
	{
		GBRemote* remote = [self remoteForAlias:aRef.remoteAlias];
		for (GBRef* branch in remote.branches)
		{
			if ([branch isEqual:aRef])
			{
				return branch;
			}
		}
	}
	else if (aRef.isLocalBranch)
	{
		for (GBRef* localRef in self.localBranches)
		{
			if ([localRef isEqual:aRef])
			{
				return localRef;
			}
		}
	}
	else if (aRef.isTag)
	{
		for (GBRef* tag in self.tags)
		{
			if ([tag isEqual:aRef])
			{
				return tag;
			}
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
		NSLog(@"GBRepository: WARNING: ref %@ is expected to have a name", ref);
		return NO;
	}
	
	// Note: don't use ref.remote to avoid stale data (just in case)
	GBRemote* remote = [self remoteForAlias:ref.remoteAlias];
	
	if (!remote)
	{
		NSLog(@"GBRepository: no remote found for ref %@", ref);
		return NO;
	}
	
	if ([remote isTransientBranch:ref])
	{
		//NSLog(@"GBRepository: ref %@ is transient", ref);
		return NO;
	}
	
	return YES;
}

- (BOOL) doesHaveSubmodules
{
	return [[NSFileManager defaultManager] fileExistsAtPath:[self.path stringByAppendingPathComponent:@".gitmodules"]];
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
	
	block = [block copy];
	
	GBStashListTask* task = [[GBStashListTask alloc] init];
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

- (NSURL*) URLForRelativePath:(NSString*)relativePath
{
	if (!relativePath) return nil;
	// I've checked that this method returns file URL (isFileURL)
	//	fileURL = file://localhost/Users/oleganza/
	//	pathURL = ./Work/gitbox -- file://localhost/Users/oleganza/
	//	pathURL isFileURL = 1
	//	pathURL path = /Users/oleganza/Work/gitbox
	//	pathURL absolute path = /Users/oleganza/Work/gitbox
	return [NSURL URLWithString:[relativePath stringByAddingAllPercentEscapesUsingEncoding:NSUTF8StringEncoding] relativeToURL:self.url];
}





#pragma mark Update



- (void) updateConfiguredRemoteBranchWithBlock:(void(^)())block
{
	block = [block copy];
	GBLocalRemoteAssociationTask* task = [GBLocalRemoteAssociationTask task];
	task.localBranchName = self.currentLocalRef.name;
	task.repository = self;
	[self launchTask:task withBlock:^{
		GBRef* ref = task.remoteBranch;
		
		if (!ref.commitId)
		{
			GBRef* existingRef = [self existingRefForRef:task.remoteBranch];
			if (existingRef.commitId)
			{
				ref = existingRef;
			}
//			else
//			{
//				NSLog(@"GBRepository: Cannot find existing ref for configured ref %@ [existing: %@]", ref, existingRef);
//			}
		}
		
		//NSLog(@"GBRepository: loaded configured branch: %@", ref);
		
		self.currentLocalRef.configuredRemoteBranch = ref;
		
		if ((!self.currentRemoteBranch || 
			 [self.currentRemoteBranch isRemoteBranch]) && 
			[self.currentLocalRef isLocalBranch])
		{
			self.currentRemoteBranch = self.currentLocalRef.configuredRemoteBranch;
		}

		if (block) block();
	}];
}


- (void) updateLocalRefsWithBlock:(void(^)(BOOL didChange))aBlock
{
	aBlock = [aBlock copy];
	
	GBRef* currentRef = self.currentLocalRef;
	GBRef* targetRef = self.currentRemoteBranch;
	
	[self updateRemotesWithBlock:^{
		[self loadLocalRefsWithBlock:^{
			[self updateCurrentLocalRefWithBlock:^{
				[self updateConfiguredRemoteBranchWithBlock:^{
					
					BOOL didChange = !(OAAreEqual(currentRef.commitId, self.currentLocalRef.commitId) &&
									   OAAreEqual(currentRef.name,     self.currentLocalRef.name) &&
									   OAAreEqual(targetRef.commitId, self.currentRemoteBranch.commitId) &&
									   OAAreEqual(targetRef.name,     self.currentRemoteBranch.name));
					
					if (aBlock) aBlock(didChange);
				}];
			}];
		}];
	}];
}


- (void) updateRemotesIfNeededWithBlock:(void(^)())aBlock
{
	if (self.remotes.count > 0) 
	{
		if (aBlock) aBlock();
		return;
	}
	[self updateRemotesWithBlock:aBlock];
}

- (void) updateRemotesWithBlock:(void(^)())aBlock
{
	aBlock = [aBlock copy];
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
	block = [block copy];
	GBLocalRefsTask* task = [GBLocalRefsTask task];
	task.repository = self;
	[self launchTask:task withBlock:^{
		self.localBranches = task.branches;
		GBVersionComparator* comparator = [GBVersionComparator defaultComparator];
		self.tags = [task.tags sortedArrayUsingComparator:^(id tag1, id tag2) {
			return [comparator compareVersion:[tag1 name] toVersion:[tag2 name]];
		}];
		//NSLog(@">>> Updated tags: %@", [[self.tags valueForKey:@"name"] componentsJoinedByString:@", "]);
		for (NSString* remoteAlias in task.remoteBranchesByRemoteAlias)
		{
			GBRemote* remote = [self.remotes objectWithValue:remoteAlias forKey:@"alias"];
			
			// Pushed, but not yet pulled branches will be missing in this list. So we should simply replace refs, but append/update.
			
			NSArray* refs = [task.remoteBranchesByRemoteAlias objectForKey:remoteAlias];

			// ??
//			NSMutableArray* listedBranchesMissingInLocalList = [[remote.branches mutableCopy] autorelease];
//			[listedBranchesMissingInLocalList removeObjectsInArray:refs]; // uses [GBRef isEqual:]
//			
//			if (listedBranchesMissingInLocalList.count > 0)
//			{
//				refs = [refs arrayByAddingObjectsFromArray:listedBranchesMissingInLocalList];
//			}
			
			remote.branches = refs;
			[remote updateBranches];
		}
		
		if (block) block();
	}];
}


- (void) updateCurrentLocalRefWithBlock:(void(^)())block
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
	GBRef* ref = [GBRef new];
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
	
	[self.stage updateConflictState];
	
	if (block) block();
}




- (void) updateLocalBranchCommitsWithBlock:(void(^)())block
{
	if (!self.currentLocalRef)
	{
		if (block) block();
		return;
	}
	block = [block copy];
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
	
	block = [block copy];
	GBHistoryTask* task = [GBHistoryTask task];
	task.repository = self;
	task.branch = self.currentRemoteBranch;
	task.substructedBranch = self.currentLocalRef;
	[self launchTask:task withBlock:^{
		NSArray* allCommits = self.localBranchCommits;
		self.unmergedCommitsCount = [task.commits count];
		for (__strong GBCommit* commit in task.commits)
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
	block = [block copy];
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
		for (__strong GBCommit* commit in task.commits)
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
	
	if (commitish1.length == 0 || commitish2.length == 0)
	{
		self.commitsDiffCount = 0;
		if (block) block();
		return;
	}
	
	block = [block copy];
	
	// There's a problem with blockTable here: if the branch was changed when this command was running, the result will be stale.
	//[self.blockTable addBlock:block forName:@"updateCommitsDiffCount" proceedIfClear:^{}];
	
	GBTask* task = [self task];
	NSString* query = [NSString stringWithFormat:@"%@...%@", commitish1, commitish2]; // '...' produces symmetric difference
	
	// Special case: if the remote branch is not pushed yet, we don't have its commitish. 
	// So simply count all commits on the current branch.
	if ([[self remoteForAlias:self.currentRemoteBranch.remoteAlias] isTransientBranch:self.currentRemoteBranch])
	{
		query = commitish1;
	}
	
	task.arguments = [NSArray arrayWithObjects:@"rev-list", query, @"--count", @"--", @".", nil];
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
		self.lastError = nil;
	}];
}



// A routine for configuring .gitmodules in .git/config. 
// 99.99% of users don't want to think about it, so it is a private method used by updateSubmodulesWithBlock:
- (void) initSubmodulesWithBlock:(void(^)())block
{
	block = [block copy];
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


// Reloads list of submodules for this repository. 
// Does not pull actual submodules or change their refs in any way.

- (void) updateSubmodulesWithBlock:(void (^)())block
{
	// Quick check for common case: if file .gitmodules does not exist, we have no submodules
	if (![self doesHaveSubmodules])
	{
		self.submodules = [NSArray array];
		if (block) block();
		return;
	}
	__weak __typeof(self) weakSelf = self;
	[self.blockTable addBlock:block forName:@"updateSubmodules" proceedIfClear:^{
		[weakSelf initSubmodulesWithBlock:^{
			GBSubmodulesTask* task = [GBSubmodulesTask taskWithRepository:weakSelf];
			[weakSelf launchTask:task withBlock:^{
				weakSelf.submodules = task.submodules;
				[weakSelf.blockTable callBlockForName:@"updateSubmodules"];
			}];
		}];
	}];
}






#pragma mark Mutation methods


- (void) configureTrackingRemoteBranch:(GBRef*)ref withLocalName:(NSString*)name block:(void(^)())block
{
	block = [block copy];
	
	if ((ref && ![ref isRemoteBranch]) || !name)
	{
		if (block) block();
		return;
	}
	
	NSString* escapedName = [name stringWithEscapingConfigKeyPart];
	
	if (!ref)
	{
		[self.libgitRepository.config removeKey:[NSString stringWithFormat:@"branch.%@.merge", escapedName]];
		if (block) block();
		return;
	}
	
	//NSLog(@"escapedName = %@", escapedName);
	[self.config setString:ref.remoteAlias forKey:[NSString stringWithFormat:@"branch.%@.remote", escapedName] withBlock:^{
		[self.config setString:[NSString stringWithFormat:@"refs/heads/%@", ref.name] forKey:[NSString stringWithFormat:@"branch.%@.merge", escapedName] withBlock:^{
			if (block) block();
		}];
	}];
}


- (void) checkoutRef:(GBRef*)ref withBlock:(void(^)())block
{
	block = [block copy];
	GBTask* task = [self task];
	task.arguments = [NSArray arrayWithObjects:@"checkout", [ref commitish], nil];
	[self launchTask:task withBlock:^{
		[task showErrorIfNeeded];
		if (block) block();
	}];
}

- (void) checkoutRef:(GBRef*)ref withNewName:(NSString*)name block:(void(^)())block
{
	block = [block copy];
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
	block = [block copy];
	GBTask* checkoutTask = [self task];
	// Note: if commit is nil, then the command will be simply "git tag <name>"
	checkoutTask.arguments = [NSArray arrayWithObjects:@"checkout", @"-b", name, aCommit.commitId, nil];
	[self launchTask:checkoutTask withBlock:^{
		[checkoutTask showErrorIfNeeded];
		[self configureTrackingRemoteBranch:self.currentRemoteBranch withLocalName:name block:block];
	}];
}

- (void) createTagWithName:(NSString*)name commitId:(NSString*)aCommitId block:(void(^)())block
{
	block = [block copy];
	GBTask* aTask = [self task];
	// Note: if commit is nil, then the command will be simply "git tag <name>"
	aTask.arguments = [NSArray arrayWithObjects:@"tag", name, aCommitId, nil]; 
	[self launchTask:aTask withBlock:^{
		[aTask showErrorIfNeeded];
		[self configureTrackingRemoteBranch:self.currentRemoteBranch withLocalName:name block:block];
	}];
}


- (void) commitWithMessage:(NSString*) message block:(void(^)())block
{
	block = [block copy];
	if (message && [message length] > 0)
	{
		GBTask* task = [self task];
		
		// By default, OSX uses NFD. Some Linux and Windows programs work incorrectly with that normalization, so we convert to NFC.
		message = [message precomposedStringWithCanonicalMapping];
		
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
	NSAlert* alert = [[NSAlert alloc] init];
	[alert addButtonWithTitle:@"OK"];
	[alert setMessageText:message];
	[alert setInformativeText:description];
	[alert setAlertStyle:NSWarningAlertStyle];
	
	[[GBMainWindowController instance] sheetQueueAddBlock:^{
		[alert beginSheetModalForWindow:[[GBMainWindowController instance] window] 
						  modalDelegate:self
						 didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
							contextInfo:NULL];
	}];
}


- (void) alertWithMessage:(NSString*)message gitOutput:(NSString*)description
{
	description = [description stringByReplacingOccurrencesOfString:@"fatal: " withString:@""];
	description = [description stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	description = [description stringByAppendingFormat:@"\n\nRepository: %@", self.path];
	
	[self alertWithMessage:message description:description];
}

- (void) alertDidEnd:(NSAlert*)alert returnCode:(NSInteger)returnCode contextInfo:(void*)ref
{
	[[alert window] orderOut:nil];
	[[GBMainWindowController instance] sheetQueueEndBlock];
}


- (void) fetchCurrentBranchWithBlock:(void(^)())block
{
	block = [block copy];
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
	block = [block copy];
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
	block = [block copy];
	GBTask* task = [self task];
	task.arguments = [NSArray arrayWithObjects:@"merge", commitish, nil];
	[self launchTask:task withBlock:^{
		if ([task isError])
		{
			NSString* msg = [task UTF8ErrorAndOutput];
			
			// Auto-merging another_new_file.txt
			// CONFLICT (content): Merge conflict in another_new_file.txt
			// Automatic merge failed; fix conflicts and then commit the result.
			
			if ([msg rangeOfString:@"CONFLICT"].length > 0)
			{
				msg = NSLocalizedString(@"Conflicting changes detected. Fix conflicts and commit the result.", @"");
			}
			// fatal: 'merge' is not possible because you have unmerged files.
			// Please, fix them up in the work tree, and then use 'git add/rm <file>' as
			// appropriate to mark resolution and make a commit, or use 'git commit -a'.
			else if ([msg rangeOfString:@"unmerged files"].length > 0 && [msg rangeOfString:@"resolution"].length > 0)
			{
				msg = NSLocalizedString(@"Stage contains unmerged files. Fix conflicting changes and commit the result.", @"");
			}
			
			// error: Your local changes to the following files would be overwritten by merge:
			// another_new_file.txt
			// Please, commit your changes or stash them before you can merge.
			// Aborting
			// Updating 5e1d882..366163a
			else if ([msg rangeOfString:@"overwritten by merge"].length > 0)
			{
				msg = NSLocalizedString(@"Commit or stash changes before you can merge.", @"");
			}
			
			self.lastError = [self errorWithCode:GBErrorCodeMergeFailed 
									 description:NSLocalizedString(@"Merge Failed", @"")
										  reason:nil
									  suggestion:msg];
		}
		if (block) block();
		self.lastError = nil;
	}];
}

- (void) cherryPickCommitId:(NSString*)aCommitId creatingCommit:(BOOL)creatingCommit message:(NSString*)message withBlock:(void(^)())block
{
	if (!aCommitId)
	{
		if (block) block();
		return;
	}
	
	block = [block copy];
	GBTask* task = [self task];
	if (creatingCommit)
	{
		task.arguments = [NSArray arrayWithObjects:@"cherry-pick", aCommitId, nil];
	}
	else
	{
		task.arguments = [NSArray arrayWithObjects:@"cherry-pick", @"--no-commit", aCommitId, nil];
	}
	
	[self launchTask:task withBlock:^{
		if (!creatingCommit || [task isError])
		{
			self.stage.currentCommitMessage = message;
		}
		if ([task isError])
		{
			[self alertWithMessage: @"Cherry-pick Failed" gitOutput:[task UTF8ErrorAndOutput]];
		}
		if (block) block();
	}];
}

- (void) cherryPickCommit:(GBCommit*)aCommit creatingCommit:(BOOL)creatingCommit withBlock:(void(^)())block
{
	[self cherryPickCommitId:aCommit.commitId creatingCommit:creatingCommit message:aCommit.message withBlock:block];
}

- (void) pullBranch:(GBRef*)aRemoteBranch withBlock:(void(^)())block
{
	block = [block copy];
	if (!aRemoteBranch)
	{
		block();
		return;
	}
	NSString* alias = aRemoteBranch.remoteAlias;
	GBRemote* aRemote = [self remoteForAlias:alias];
	
	if (!aRemote)
	{
		NSLog(@"Error: cannot find remote for alias '%@'", alias);
		if (block) block();
		return;
	}

	GBAuthenticatedTask* task = [self authenticatedTaskWithAddress:aRemote.URLString];
	task.arguments = [NSArray arrayWithObjects:@"pull", 
					  // Do not prune anything because when "--tags" option is given, Git repeatedly removes/adds the remote branch from .git/packed-refs
					  // @"--prune", // removes tags and branches missing on remote
					  @"--tags", 
					  @"--force", 
					  @"--progress",
					  aRemoteBranch.remoteAlias, 
					  [NSString stringWithFormat:@"%@:refs/remotes/%@", 
					   aRemoteBranch.name, [aRemoteBranch nameWithRemoteAlias]],
					  nil];
	[self launchRemoteTask:task withBlock:^{
		self.currentTaskProgress = 0.0;
		self.currentTaskProgressStatus = nil;
		
		if ([task isError])
		{
			/*
			 Message 1:
			 
			 error: The following untracked working tree files would be overwritten by merge:
			 3577.txt
			 Please move or remove them before you can merge.
			 Aborting
			 Updating 3b58cd4..c5ec7ec
			 
			 
			 Message 2:
			 
			 error: Your local changes to the following files would be overwritten by merge:
			 3577.txt
			 Please, commit your changes or stash them before you can merge.
			 Aborting
			 Updating 3b58cd4..c5ec7ec
			 
			 Message 3:
			 
			 '/incorrect/url' does not appear to be a git repository
			 The remote end hung up unexpectedly
			 
			 Message 4:
			 
			 error: no common commits
			 remote: received 1%...
			 ...
			 
			 Message 5:
			 
			 Auto-merging Documents/TODO.txt
			 CONFLICT (content): Merge conflict in Documents/TODO.txt
			 Automatic merge failed; fix conflicts and then commit the result.
			 
			 */
			
			NSString* msg = [task UTF8ErrorAndOutput];
			
			if ([msg rangeOfString:@"overwritten by merge"].length > 0)
			{
				self.lastError = [self errorWithCode:GBErrorCodePullFailed
										 description:NSLocalizedString(@"Pull Failed", @"")
											  reason:nil
										  suggestion:NSLocalizedString(@"Please commit your changes and try again.", @"")];
			}
			else if ([msg rangeOfString:@"remote end hung up unexpectedly"].length > 0)
			{
				self.lastError = [self errorWithCode:GBErrorCodePullFailed
										 description:NSLocalizedString(@"Pull Failed", @"")
											  reason:nil
										  suggestion:NSLocalizedString(@"Please check the repository address or network settings.", @"")];
			}
			else
			{
				self.lastError = [self errorWithCode:GBErrorCodePullFailed
										 description:NSLocalizedString(@"Pull Failed", @"")
											  reason:nil
										  suggestion:msg];
			}
		}
		if (block) block();
		self.lastError = nil;
	}];
}

- (void) fetchRemote:(GBRemote*)aRemote silently:(BOOL)silently withBlock:(void(^)())block
{
	block = [block copy];
	if (!aRemote)
	{
		if (block) block();
		return;
	}
	GBAuthenticatedTask* task = [self authenticatedTaskWithAddress:aRemote.URLString];
	task.silent = silently;
	NSMutableArray* args = [NSMutableArray arrayWithObjects:@"fetch", 
							@"--tags",
							@"--force",
							@"--progress", 
							nil];
	if (!silently)
	{
		// Do not prune anything because when "--tags" option is given, Git repeatedly removes/adds the remote branch from .git/packed-refs
		//[args addObject:@"--prune"]; // removes tags and branches missing on remote. In silent mode we don't do that to be nice with remotes not-in-sync.
	}
	[args addObject:aRemote.alias];
	
	// Declaring a proper refspec is necessary to make autofetch expectations about remote alias to work. git show-ref should always return refs for alias XYZ.
	[args addObject:[aRemote defaultFetchRefspec]];
	
	task.arguments = args;
	
	task.dispatchQueue = dispatchQueue;
	[self launchRemoteTask:task withBlock:^{
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
	}];
}


- (void) fetchBranch:(GBRef*)aRemoteBranch withBlock:(void(^)())block
{
	block = [block copy];
	if (!aRemoteBranch)
	{
		if (block) block();
		return;
	}
	NSString* alias = aRemoteBranch.remoteAlias;
	GBRemote* aRemote = [self remoteForAlias:alias];
	
	if (!aRemote)
	{
		NSLog(@"Error: cannot find remote for alias '%@'", alias);
		if (block) block();
		return;
	}
	
	GBAuthenticatedTask* task = [self authenticatedTaskWithAddress:aRemote.URLString];
	task.arguments = [NSArray arrayWithObjects:@"fetch", 
					  @"--tags", 
					  @"--force", 
					  @"--progress",
					  aRemoteBranch.remoteAlias, 
					  [NSString stringWithFormat:@"%@:refs/remotes/%@", 
					   aRemoteBranch.name, [aRemoteBranch nameWithRemoteAlias]],
					  nil];
	[self launchRemoteTask:task withBlock:^{
		self.currentTaskProgress = 0.0;
		self.currentTaskProgressStatus = nil;
		if ([task isError])
		{
			self.lastError = [self errorWithCode:GBErrorCodeFetchFailed
									 description:[NSString stringWithFormat:NSLocalizedString(@"Failed to fetch from %@",@"Error"), aRemoteBranch.remoteAlias]
										  reason:[task UTF8ErrorAndOutput]
									  suggestion:NSLocalizedString(@"Please check the repository address or network settings.",@"Error")];
		}
		if (block) block();
		self.lastError = nil;
	}];
}


- (void) pushWithForce:(BOOL)forced block:(void(^)())block
{
	[self pushBranch:self.currentLocalRef toRemoteBranch:self.currentRemoteBranch forced:(BOOL)forced withBlock:block];
}

// if aLocalBranch.commitish == nil, then it's a "push delete"
- (void) pushBranch:(GBRef*)aLocalBranch toRemoteBranch:(GBRef*)aRemoteBranch forced:(BOOL)forced withBlock:(void(^)())block
{
	block = [block copy];
	if (!aLocalBranch || !aRemoteBranch)
	{
		if (block) block();
		return;
	}
		
	GBRemote* aRemote = [self remoteForAlias:aRemoteBranch.remoteAlias];
	
	if (!aRemote)
	{
		NSLog(@"Error: cannot find remote for alias '%@'", aRemoteBranch.remoteAlias);
		if (block) block();
		return;
	}
	
	GBAuthenticatedTask* task = [self authenticatedTaskWithAddress:aRemote.URLString];
	NSString* commitish = aLocalBranch.commitish;
	NSString* refspec = [NSString stringWithFormat:@"%@:%@", commitish ? commitish : @"", aRemoteBranch.name];
	
	task.arguments = [NSArray arrayWithObjects:@"push", @"--tags", @"--progress", nil];
	if (forced) task.arguments = [task.arguments arrayByAddingObject:@"--force"];
	task.arguments = [task.arguments arrayByAddingObject:aRemoteBranch.remoteAlias];
	task.arguments = [task.arguments arrayByAddingObject:refspec];
	
	BOOL pushingToNewBranch = [aRemote isTransientBranch:aRemoteBranch];
	
	[self launchRemoteTask:task withBlock:^{
		self.currentTaskProgress = 0.0;
		self.currentTaskProgressStatus = nil;
		
		if ([task isError])
		{
			// Special case: GBAuthenticatedTask: unknown error: fatal: '/Users/oleganza/Work/gitbox/example_repos/server1' does not appear to be a git repository
			
			//To /Users/oleganza/Work/gitbox/example_repos/server
			//! [rejected]        master -> master2 (non-fast-forward)
			//error: failed to push some refs to '/Users/oleganza/Work/gitbox/example_repos/server'
			//To prevent you from losing history, non-fast-forward updates were rejected
			//Merge the remote changes (e.g. 'git pull') before pushing again.  See the
			//'Note about fast-forwards' section of 'git push --help' for details.

			NSString* msg = [task UTF8ErrorAndOutput];
			
			if ([msg rangeOfString:@"[rejected]"].length > 0 ||
				[msg rangeOfString:@"non-fast-forward"].length > 0)
			{
				self.lastError = [self errorWithCode:GBErrorCodePullFailed
										 description:NSLocalizedString(@"Push Failed", @"")
											  reason:nil
										  suggestion:NSLocalizedString(@"Please pull new commits and try again.", @"")];
			}
			else if ([msg rangeOfString:@"remote end hung up unexpectedly"].length > 0 ||
					 [msg rangeOfString:@"does not appear to be a git repository"].length > 0)
			{
				self.lastError = [self errorWithCode:GBErrorCodePullFailed
										 description:NSLocalizedString(@"Push Failed", @"")
											  reason:nil
										  suggestion:NSLocalizedString(@"Please check the repository address or network settings.", @"")];
			}
			else
			{
				msg = [msg stringByReplacingOccurrencesOfString:@"fatal:" withString:@""];
				msg = [msg stringByReplacingOccurrencesOfString:@"remote error:" withString:@""];
				msg = [msg stringByReplacingOccurrencesOfString:@"\n\t"   withString:@"\n"];
				msg = [msg stringByReplacingOccurrencesOfString:@"\n    " withString:@"\n"];
				msg = [msg stringByReplacingOccurrencesOfString:@"\n   "  withString:@"\n"];
				msg = [msg stringByReplacingOccurrencesOfString:@"\n  "   withString:@"\n"];
				msg = [msg stringByReplacingOccurrencesOfString:@"\n "    withString:@"\n"];
				self.lastError = [self errorWithCode:GBErrorCodePullFailed
										 description:NSLocalizedString(@"Push Failed", @"")
											  reason:nil
										  suggestion:[msg stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
			}
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
		
		if (pushingToNewBranch && !self.lastError)
		{
			[self fetchRemote:aRemote silently:YES withBlock:block];
		}
		else
		{
			if (block) block();
		}
		self.lastError = nil;
	}];
}

- (void) rebaseWithBlock:(void(^)())block
{
	block = [block copy];
	
	if (!self.currentRemoteBranch)
	{
		if (block) block();
		return;
	}
	
	GBRef* otherBranch = self.currentRemoteBranch;
	
	GBRemote* aRemote = [self remoteForAlias:otherBranch.remoteAlias];
	
	[self fetchRemote:aRemote silently:NO withBlock:^{
		
		GBTask* taskContinue = [self task];
		taskContinue.arguments = [NSArray arrayWithObjects:@"rebase", @"--continue", nil];
		[self launchTask:taskContinue withBlock:^{
			GBTask* task = [self task];
			task.arguments = [NSArray arrayWithObjects:@"rebase", [otherBranch nameWithRemoteAlias], nil];
			[self launchTask:task withBlock:^{
				if ([task isError])
				{
					[self alertWithMessage:NSLocalizedString(@"Rebase failed",nil) gitOutput:[task UTF8ErrorAndOutput]];
				}
				if (block) block();
			}];
			
		}];
	}];
}


- (void) rebaseCancelWithBlock:(void(^)())block
{
	block = [block copy];
	GBTask* task = [self task];
	task.arguments = [NSArray arrayWithObjects:@"rebase", @"--abort", nil];
	[self launchTask:task withBlock:^{
		if ([task isError])
		{
			[self alertWithMessage:NSLocalizedString(@"Failed to cancel rebase",nil) gitOutput:[task UTF8ErrorAndOutput]];
		}
		if (block) block();
	}];
}

- (void) rebaseSkipWithBlock:(void(^)())block
{
	block = [block copy];
	GBTask* task = [self task];
	task.arguments = [NSArray arrayWithObjects:@"rebase", @"--skip", nil];
	[self launchTask:task withBlock:^{
		if ([task isError])
		{
			[self alertWithMessage:NSLocalizedString(@"Rebase failed",nil) gitOutput:[task UTF8ErrorAndOutput]];
		}
		if (block) block();
	}];
}

- (void) rebaseContinueWithBlock:(void(^)())block
{
	block = [block copy];
	GBTask* task = [self task];
	task.arguments = [NSArray arrayWithObjects:@"rebase", @"--continue", nil];
	[self launchTask:task withBlock:^{
		if ([task isError])
		{
			[self alertWithMessage:NSLocalizedString(@"Rebase failed",nil) gitOutput:[task UTF8ErrorAndOutput]];
		}
		if (block) block();
	}];
}



- (void) resetStageWithBlock:(void(^)())block
{
	block = [block copy];
    
	GBTask* task = [self task];
	task.arguments = [NSArray arrayWithObjects:@"reset", @"--hard", @"HEAD", nil];
	[self launchTask:task withBlock:^{
		self.stage.currentCommitMessage = nil;
		if ([task isError])
		{
			[self alertWithMessage:NSLocalizedString(@"Reset failed",nil) gitOutput:[task UTF8ErrorAndOutput]];
		}
		if (block) block();
	}];
}


- (void) resetToCommit:(GBCommit*)aCommit withBlock:(void(^)())block
{
	block = [block copy];
	
	GBTask* task = [self task];
	task.arguments = [NSArray arrayWithObjects:@"reset", @"--hard", aCommit.commitId, nil];
	[self launchTask:task withBlock:^{
		self.stage.currentCommitMessage = nil;
		if ([task isError])
		{
			[self alertWithMessage:NSLocalizedString(@"Branch reset failed",nil) gitOutput:[task UTF8ErrorAndOutput]];
		}
		if (block) block();
	}];
}

- (void) resetSoftToCommit:(NSString*)commitish withBlock:(void(^)())block
{
	block = [block copy];
	
	GBTask* task = [self task];
	task.arguments = [NSArray arrayWithObjects:@"reset", @"--soft", commitish, nil];
	[self launchTask:task withBlock:^{
		self.stage.currentCommitMessage = nil;
		if ([task isError])
		{
			[self alertWithMessage:NSLocalizedString(@"Branch reset failed",nil) gitOutput:[task UTF8ErrorAndOutput]];
		}
		if (block) block();
	}];
}

- (void) resetMixedToCommit:(NSString*)commitish withBlock:(void(^)())block
{
	block = [block copy];
	
	GBTask* task = [self task];
	task.arguments = [NSArray arrayWithObjects:@"reset", @"--mixed", commitish, nil];
	[self launchTask:task withBlock:^{
		if ([task isError])
		{
			[self alertWithMessage:NSLocalizedString(@"Branch reset failed",nil) gitOutput:[task UTF8ErrorAndOutput]];
		}
		if (block) block();
	}];
}

- (void) revertCommit:(GBCommit*)aCommit withBlock:(void(^)())block
{
	block = [block copy];
	
	GBTask* task = [self task];
	task.arguments = [NSArray arrayWithObjects:@"revert", @"--no-edit", aCommit.commitId, nil];
	[self launchTask:task withBlock:^{
		self.stage.currentCommitMessage = nil;
		if ([task isError])
		{
			[self alertWithMessage:NSLocalizedString(@"Commit revert failed",nil) gitOutput:[task UTF8ErrorAndOutput]];
		}
		if (block) block();
	}];  
}

- (void) resetSubmodule:(GBSubmodule*)submodule withBlock:(void(^)())block
{
	GBTask* task = [self task];
	task.arguments = [NSArray arrayWithObjects:@"submodule", @"update", @"--init", @"--", submodule.path, nil];
	[self launchTask:task withBlock:block];
}


- (void) doGitCommand:(NSArray*)arguments withBlock:(void(^)())block
{
	if (!arguments)
	{
		if (block) block();
		return;
	}
	block = [block copy];
	GBTask* task = [self task];
	task.arguments = arguments;
	[self launchTask:task withBlock:^{
		if (block) block();
	}];
}
 

- (void) stashChangesWithMessage:(NSString*)message block:(void(^)())block
{
	block = [block copy];
	
	GBTask* task = [self task];
	
	message = [message stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	
	// By default, OSX uses NFD. Some Linux and Windows programs work incorrectly with that normalization, so we convert to NFC.
	message = [message precomposedStringWithCanonicalMapping];

	if (![GBTask isSnowLeopard])
	{
		task.arguments = [NSArray arrayWithObjects:@"stash", @"save", @"--include-untracked", message, nil];
	}
	else
	{
		task.arguments = [NSArray arrayWithObjects:@"stash", @"save", message, nil];
	}
	[self launchTask:task withBlock:^{
		if ([task isError])
		{
			[self alertWithMessage:[NSString stringWithFormat:NSLocalizedString(@"Failed to stash “%@”",nil), message] gitOutput:[task UTF8ErrorAndOutput]];
		}
		if (block) block();
	}];
}


- (void) applyStash:(GBStash*)aStash withBlock:(void(^)())block
{
	block = [block copy];
	
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
			[self alertWithMessage:[NSString stringWithFormat:NSLocalizedString(@"Failed to apply stash “%@”",nil), aStash.message] gitOutput:[task UTF8ErrorAndOutput]];
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
					[self alertWithMessage:[NSString stringWithFormat:NSLocalizedString(@"Failed to remove stash %@",nil), stash.ref] gitOutput:[task UTF8ErrorAndOutput]];
				}
				[group leave];
			}];
		}
	} continuation:block];
}


- (void) removeRefs:(NSArray*)refs withBlock:(void(^)())block
{
	NSMutableArray* newtags = [self.tags mutableCopy];
	[newtags removeObjectsInArray:refs];
	self.tags = newtags;
	
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
					[self alertWithMessage:[NSString stringWithFormat:ref.isTag ? 
											NSLocalizedString(@"Failed to remove tag %@",nil) : 
											NSLocalizedString(@"Failed to remove branch %@",nil), ref.name] 
							   gitOutput:[task UTF8ErrorAndOutput]];
				}
				[group leave];
			}];
		}
	} continuation:block];
}

- (void) removeRemoteRefs:(NSArray*)refs withBlock:(void(^)())block
{
	// git push origin :refs/tags/12345
	// git push origin :refs/heads/branch
	
	block = [block copy];
	
	if (self.currentRemoteBranch && [refs containsObject:self.currentRemoteBranch])
	{
		self.currentRemoteBranch = nil;
		[self configureTrackingRemoteBranch:nil
							  withLocalName:self.currentLocalRef.name 
									 block:^{
										 [self removeRemoteRefs:refs withBlock:block];
									 }];
		return;
	}
	
	[OABlockGroup groupBlock:^(OABlockGroup *group) {
		for (GBRef* ref in refs)
		{
			if ([ref isTag])
			{
				for (GBRemote* aRemote in self.remotes)
				{
					[group enter];
					GBTask* task = [self task];
					task.arguments = [NSArray arrayWithObjects:@"push", aRemote.alias, [NSString stringWithFormat:@":refs/tags/%@", ref.name], nil];
					[self launchTask:task withBlock:^{
						if ([task isError])
						{
							[self alertWithMessage:[NSString stringWithFormat:NSLocalizedString(@"Failed to remove tag %@",nil), ref.name] gitOutput:[task UTF8ErrorAndOutput]];
						}
						[group leave];
					}];
				}
			}
			else
			{
				[group enter];
				GBTask* task = [self task];
				task.arguments = [NSArray arrayWithObjects:@"push", ref.remoteAlias, [NSString stringWithFormat:@":refs/heads/%@", ref.name], nil];
				[self launchTask:task withBlock:^{
					if ([task isError])
					{
						[self alertWithMessage:[NSString stringWithFormat:NSLocalizedString(@"Failed to remove branch %@",nil), ref.name] gitOutput:[task UTF8ErrorAndOutput]];
					}
					[group leave];
				}];
			}
		}
	} continuation:block];
	
}




#pragma mark Utility methods


- (id) task
{
	GBTask* task = [GBTask new];
	task.repository = self;
	return task;
}

- (id) taskWithProgress
{
	GBTaskWithProgress* task = [GBTaskWithProgress new];
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

- (id) authenticatedTaskWithAddress:(NSString*)address
{
	GBAuthenticatedTask* task = [GBAuthenticatedTask new];
	task.remoteAddress = address;
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
	// Avoid forking a process until the queue is empty.
	block = [block copy];
	dispatch_async(dispatchQueue, ^{
		dispatch_async(dispatch_get_main_queue(), ^{
			[aTask launchInQueue:dispatchQueue withBlock:block];
		});
	});
}

- (void) launchRemoteTask:(OATask*)aTask withBlock:(void(^)())block
{
	// Avoid forking a process until the queue is empty.
	block = [block copy];
	dispatch_async(dispatchQueue, ^{
		dispatch_async(dispatch_get_main_queue(), ^{
			[aTask launchInQueue:remoteDispatchQueue withBlock:block];
		});
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

- (NSError*) errorWithCode:(GBErrorCode)aCode
               description:(NSString*)aDescription
                    reason:(NSString*)aReason
                suggestion:(NSString*)aSuggestion
{
	
	NSMutableDictionary* dict = [NSMutableDictionary dictionary];
	
	if (aDescription) [dict setObject:aDescription forKey:NSLocalizedDescriptionKey];
	if (aReason)      [dict setObject:aReason      forKey:NSLocalizedFailureReasonErrorKey];
	if (aSuggestion)  [dict setObject:aSuggestion  forKey:NSLocalizedRecoverySuggestionErrorKey];
	
	return [NSError errorWithDomain:GBErrorDomain
							   code:aCode
						   userInfo:dict];
}

@end
