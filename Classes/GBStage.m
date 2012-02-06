#import "GBStage.h"
#import "GBChange.h"
#import "GBRepository.h"
#import "GBTask.h"
#import "GBRefreshIndexTask.h"
#import "GBStagedChangesTask.h"
#import "GBAllStagedFilesTask.h"
#import "GBUnstagedChangesTask.h"
#import "GBUntrackedChangesTask.h"
#import "OABlockGroup.h"
#import "OABlockOperations.h"
#import "NSData+OADataHelpers.h"
#import "NSArray+OAArrayHelpers.h"
#import "NSObject+OASelectorNotifications.h"

@interface GBStage ()
@property(nonatomic, assign, getter=isUpdating) BOOL updating;
@property(nonatomic, assign, getter=isRebaseConflict) BOOL rebaseConflict;
@property(nonatomic, copy) NSData* previousChangesData;
@property(nonatomic, copy) void(^transactionPendingBlock)();
- (void) arrangeChanges;
- (void) launchTaskByChunksWithArguments:(NSArray*)args paths:(NSArray*)allPaths block:(void(^)())block taskCallback:(void(^)(GBTask*))taskCallback atomic:(BOOL)atomic;
- (void) flushBlocks:(NSMutableArray*)mutableArray;
@end


@implementation GBStage {
	BOOL stageTransactionInProgress;
}

@synthesize updating;

@synthesize stagedChanges;
@synthesize unstagedChanges;
@synthesize untrackedChanges;
@synthesize currentCommitMessage;
@synthesize rebaseConflict;
@synthesize previousChangesData;

@synthesize transactionPendingBlock=_transactionPendingBlock;

#pragma mark - Init

- (void) dealloc
{
	[stagedChanges release];
	[unstagedChanges release];
	[untrackedChanges release];
	[currentCommitMessage release];
	[previousChangesData release];
	[_transactionPendingBlock release];
	[super dealloc];
}

- (id) init
{
	if ((self = [super init]))
	{
	}
	return self;
}

- (NSString*) description
{
	return [NSString stringWithFormat:@"<GBStage:%p %@ (%d staged, %d not staged, %d untracked)>", 
			self, 
			self.repository.url, 
			(int)self.stagedChanges.count, 
			(int)self.unstagedChanges.count, 
			(int)self.untrackedChanges.count];
}


#pragma mark - Interrogation


- (BOOL) isDirty
{
	return (self.stagedChanges.count + self.unstagedChanges.count) > 0;
}

- (BOOL) isStashable
{
	return (self.stagedChanges.count + self.unstagedChanges.count + self.untrackedChanges.count) > 0;
}

- (BOOL) isCommitable
{
	return self.stagedChanges.count > 0;
}

// Returns a good default human-readable message like "somefile.c, other.txt, Makefile and 5 others"
- (NSString*) defaultStashMessage
{
	// Displaying only file names, skipping duplicates.
	
	NSArray* stashableChanges = [(self.stagedChanges ? self.stagedChanges : [NSArray array]) arrayByAddingObjectsFromArray:(self.unstagedChanges ? self.unstagedChanges : [NSArray array])];
	
	int totalChanges = stashableChanges.count;
	
	NSMutableSet* uniqueNames = [NSMutableSet set]; // also would produce some sort of randomness to avoid displaying same top files.
	
	for (GBChange* change in stashableChanges)
	{
		NSString* name = change.fileURL.absoluteString.lastPathComponent;
		[uniqueNames addObject:name];
	}
	
	NSArray* list = [uniqueNames allObjects];
	
	if ([list count] < 1) return NSLocalizedString(@"No changes", @"GBStage");
	
	if ([list count] <= 4)
	{
		// Simply list all files
		list = [list sortedArrayUsingSelector:@selector(self)];
		return [list componentsJoinedByString:@", "];
	}
	
	// Show first N files and then count of the rest (which will be > 1)
	int visibleFiles = 2;
	
	return [NSString stringWithFormat:NSLocalizedString(@"%@ and %d more files", @"GBStage"), 
			[[[list subarrayWithRange:NSMakeRange(0, visibleFiles)] sortedArrayUsingSelector:@selector(self)] componentsJoinedByString:@", "],
			totalChanges - visibleFiles];
}






#pragma mark - GBCommit overrides


- (BOOL) isStage
{
	return YES;
}

- (GBStage*) asStage
{
	return self;
}


- (NSString*) message
{
	NSUInteger modifications = self.stagedChanges.count + self.unstagedChanges.count;
	NSUInteger newFiles = self.untrackedChanges.count;
	
	if (modifications + newFiles <= 0)
	{
		return NSLocalizedString(@"Working directory clean", @"GBStage");
	}
	
	NSMutableArray* titles = [NSMutableArray array];
	
	if (modifications > 0)
	{
		if (modifications == 1)
		{
			[titles addObject:[NSString stringWithFormat:NSLocalizedString(@"%d modified file",@"GBStage"), modifications]];
		}
		else
		{
			[titles addObject:[NSString stringWithFormat:NSLocalizedString(@"%d modified files",@"GBStage"), modifications]];
		}
		
	}
	if (newFiles > 0)
	{
		if (newFiles == 1)
		{
			[titles addObject:[NSString stringWithFormat:NSLocalizedString(@"%d new file",@"GBStage"), newFiles]];
		}
		else
		{
			[titles addObject:[NSString stringWithFormat:NSLocalizedString(@"%d new files",@"GBStage"), newFiles]];
		}
	}  
	
	return [titles componentsJoinedByString:@", "];
}

- (NSUInteger) totalPendingChanges
{
	NSUInteger modifications = self.stagedChanges.count + self.unstagedChanges.count;
	NSUInteger newFiles = self.untrackedChanges.count;
	return modifications + newFiles;
}





#pragma mark - Actions


- (void) updateConflictState
{
	self.rebaseConflict = ([[NSFileManager defaultManager] fileExistsAtPath:[self.repository.dotGitURL.path stringByAppendingPathComponent:@"rebase-apply"]]);
}

- (void) updateStageWithBlock:(void(^)(BOOL contentDidChange))block
{
	NSMutableData* accumulatedData = [NSMutableData data];
	
	block = [[block copy] autorelease];

	
	[self beginStageTransaction:^{
	
		[self.repository launchTask:[GBRefreshIndexTask taskWithRepository:self.repository] withBlock:^{
			
			GBStagedChangesTask* stagedChangesTask = [GBStagedChangesTask taskWithRepository:self.repository];
			[self.repository launchTask:stagedChangesTask withBlock:^{
				
				[OABlockGroup groupBlock:^(OABlockGroup* blockGroup){
					
					if (stagedChangesTask.terminationStatus == 0)
					{
						self.stagedChanges = stagedChangesTask.changes;
						NSData* data = stagedChangesTask.output;
						if (data) [accumulatedData appendData:data];
					}
					else
					{
						// diff-tree failed: we don't have a HEAD commit, try another task
						GBAllStagedFilesTask* stagedChangesTask2 = [GBAllStagedFilesTask taskWithRepository:self.repository];
						[blockGroup enter];
						[self.repository launchTask:stagedChangesTask2 withBlock:^{
							self.stagedChanges = stagedChangesTask2.changes;
							NSData* data = stagedChangesTask2.output;
							if (data) [accumulatedData appendData:data];
							[blockGroup leave];
						}];
					}
					
				} continuation: ^{
					
					GBUnstagedChangesTask* unstagedChangesTask = [GBUnstagedChangesTask taskWithRepository:self.repository];
					[self.repository launchTask:unstagedChangesTask withBlock:^{
						self.unstagedChanges = unstagedChangesTask.changes;
						
						NSData* data = unstagedChangesTask.output;
						if (data) [accumulatedData appendData:data];
						
						GBUntrackedChangesTask* untrackedChangesTask = [GBUntrackedChangesTask taskWithRepository:self.repository];
						[self.repository launchTask:untrackedChangesTask withBlock:^{
							self.untrackedChanges = untrackedChangesTask.changes;
							
							NSData* data = untrackedChangesTask.output;
							if (data) [accumulatedData appendData:data];
							
							[self arrangeChanges];
							[self updateConflictState];
							updating = NO;
							
							// Now, we can calculate if we have different data or not.
							
							BOOL didChange = !self.previousChangesData || ![self.previousChangesData isEqualToData:accumulatedData];
							
							self.previousChangesData = accumulatedData;
							
	//						if ([self.repository.path rangeOfString:@"clean worki"].length > 0)
	//						{
	//							NSLog(@"GBStage update: staged: %d unstaged: %d untracked: %d", self.stagedChanges.count, self.unstagedChanges.count, self.untrackedChanges.count);
	//						}
							
							[self endStageTransaction];
							
							if (block) block(didChange);
							
							[self notifyWithSelector:@selector(stageDidUpdateChanges:)];
							
						}]; // untracked
					}]; // unstaged
				}]; // group
			}]; // staged
		}]; // refresh-index
	}]; // beginStageTransaction
}


// Legacy method, shouldn't be called from anywhere.
- (void) loadChangesWithBlock:(void(^)())block
{
	block = [[block copy] autorelease];
	[self updateStageWithBlock:^(BOOL f){
		if (block) block();
	}];
}












#pragma mark - Stage Modification Methods





- (void) stageDeletedPaths:(NSArray*)pathsToDelete withBlock:(void(^)())block
{
	block = [[block copy] autorelease];
	
	if ([pathsToDelete count] <= 0)
	{
		if (block) block();
		return;
	}
	
	[self launchTaskByChunksWithArguments:[NSArray arrayWithObjects:@"update-index", @"--remove", @"--", nil]
									paths:pathsToDelete
									block:block
							 taskCallback:^(GBTask *task) {
								 [task showErrorIfNeeded];
							 } atomic:YES];
}

- (void) stageAddedPaths:(NSArray*)pathsToAdd withBlock:(void(^)())block
{
	block = [[block copy] autorelease];
	
	if ([pathsToAdd count] <= 0)
	{
		if (block) block();
		return;
	}
	
	[self launchTaskByChunksWithArguments:[NSArray arrayWithObjects:@"add", @"--force", @"--", nil]
									paths:pathsToAdd
									block:block
							 taskCallback:^(GBTask *task) {
								 [task showErrorIfNeeded];
							 } atomic:YES];
}

- (void) stageChanges:(NSArray*)theChanges withBlock:(void(^)())block
{
	block = [[block copy] autorelease];
	
	NSMutableArray* pathsToDelete = [NSMutableArray array];
	NSMutableArray* pathsToAdd = [NSMutableArray array];
	for (GBChange* aChange in theChanges)
	{
		[aChange setStagedSilently:YES];
		if ([aChange isDeletedFile])
		{
			[pathsToDelete addObject:aChange.srcURL.relativePath];
		}
		else
		{
			[pathsToAdd addObject:aChange.fileURL.relativePath];
		}
	}
	
	[self stageDeletedPaths:pathsToDelete withBlock:^{
		[self stageAddedPaths:pathsToAdd withBlock:block];
	}];
}

- (void) unstageChanges:(NSArray*)theChanges withBlock:(void(^)())block
{
	block = [[block copy] autorelease];
	if ([theChanges count] <= 0)
	{
		if (block) block();
		return;
	}
	NSMutableArray* addedPaths = [NSMutableArray array];
	NSMutableArray* otherPaths = [NSMutableArray array];
	for (GBChange* aChange in theChanges)
	{
		[aChange setStagedSilently:NO];
		if ([aChange isAddedFile])
		{
			[addedPaths addObject:aChange.fileURL.relativePath];
		}
		else
		{
			[otherPaths addObject:aChange.fileURL.relativePath];
		}
	}
	
	//
	// run two tasks: "git reset" and "git rm --cached"
	//       do not run if paths list is empty
	//       use a single common queue to make it easier to order the tasks
	//       "git rm --cached" is needed in case when HEAD does not yet exist
	
	// [task showErrorIfNeeded] is not used because git spits out error code even if the unstage is successful.
	
	[self launchTaskByChunksWithArguments:[NSArray arrayWithObjects:@"reset", @"--", nil]
									paths:otherPaths
									block:
	 ^{
		 [self launchTaskByChunksWithArguments:[NSArray arrayWithObjects:@"rm", @"--cached", @"--force", @"--", nil]
										 paths:addedPaths
										 block:block 
								  taskCallback:nil
										atomic:YES];
	 } taskCallback:nil
			 atomic:YES];
}

- (void) stageAllWithBlock:(void(^)())block
{
	block = [[block copy] autorelease];
	[self beginStageTransaction:^{
		GBTask* task = [self.repository task];
		task.arguments = [NSArray arrayWithObjects:@"add", @".", nil];
		[self.repository launchTask:task withBlock:^{
			[task showErrorIfNeeded];
			[self endStageTransaction];
			if (block) block();
		}];
	}];
}

- (void) revertChanges:(NSArray*)theChanges withBlock:(void(^)())block
{
	if (theChanges.count <= 0)
	{
		if (block) block();
		return;
	}
	
	block = [[block copy] autorelease];
	NSMutableArray* paths = [NSMutableArray array];
	for (GBChange* aChange in theChanges)
	{
		[aChange setStagedSilently:NO];
		[paths addObject:aChange.fileURL.relativePath];
	}
	
	[self launchTaskByChunksWithArguments:[NSArray arrayWithObjects:@"checkout", @"HEAD", @"--", nil]
									paths:paths
									block:block
							 taskCallback:nil
								   atomic:YES];
}

- (void) deleteFilesInChanges:(NSArray*)theChanges withBlock:(void(^)())block
{
	block = [[block copy] autorelease];
	
	[self beginStageTransaction:^{
		
		NSMutableArray* URLsToTrash = [NSMutableArray array];
		NSMutableArray* pathsToGitRm = [NSMutableArray array];
		
		for (GBChange* aChange in theChanges)
		{
			if (!aChange.staged && aChange.fileURL)
			{
				if ([aChange isUntrackedFile])
				{
					[URLsToTrash addObject:aChange.fileURL];
				}
				else
				{
					[pathsToGitRm addObject:aChange.fileURL.relativePath];
				}
			}
		}
		
		// move to trash
		
		void (^trashingBlock)() = ^{
			if ([URLsToTrash count] > 0)
			{
				[[NSWorkspace sharedWorkspace] recycleURLs:URLsToTrash 
										 completionHandler:^(NSDictionary *newURLs, NSError *error){
											 if (block) block();
										 }];    
			}
			else
			{
				[self endStageTransaction];
				if (block) block();
			}
		};
		
		if ([pathsToGitRm count] > 0)
		{
			[self launchTaskByChunksWithArguments:[NSArray arrayWithObjects:@"rm", @"--force", @"--", nil]
											paths:pathsToGitRm
											block:trashingBlock
									 taskCallback:nil
										   atomic:NO];
		}
		else
		{
			trashingBlock();
		}
	}];

}



#pragma mark - Stage Transaction


- (void) beginStageTransaction:(void(^)())block
{
	if (!block) return;
	
	if (!stageTransactionInProgress)
	{
		stageTransactionInProgress = YES;
		block();
	}
	else
	{
		self.transactionPendingBlock = OABlockConcat(self.transactionPendingBlock, block);
	}
}

- (void) endStageTransaction
{
	stageTransactionInProgress = NO;
	void(^block)() = [[self.transactionPendingBlock copy] autorelease];
	self.transactionPendingBlock = nil;
	if (block) block();
}




#pragma mark - Private



// helper method to process more than 4096 files in chunks
- (void) launchTaskByChunksWithArguments:(NSArray*)args paths:(NSArray*)allPaths block:(void(^)())block taskCallback:(void(^)(GBTask*))taskCallback atomic:(BOOL)atomic
{
	taskCallback = [[taskCallback copy] autorelease];
	block = [[block copy] autorelease];
	
	void(^content)() = ^{
		[OABlockGroup groupBlock:^(OABlockGroup *group) {
			for (NSArray* paths in [allPaths arrayOfChunksBySize:1000])
			{
				[group enter];
				GBTask* task = [self.repository task];
				paths = [paths valueForKey:@"stringByEscapingGitFilename"];
				task.arguments = [args arrayByAddingObjectsFromArray:paths];
				[self.repository launchTask:task withBlock:^{
					if (taskCallback) taskCallback(task);
					[group leave];
				}];
			}
		} continuation:^{
			if (atomic) [self endStageTransaction];
			if (block) block();
		}];
	};
	
	if (atomic)
	{
		content = [[content copy] autorelease];
		[self beginStageTransaction:^{
			content();
		}];
	}
	else
	{
		content();
	}
}



- (void) arrangeChanges
{
	NSMutableArray* sortedChanges = [NSMutableArray array];
	[sortedChanges addObjectsFromArray:self.stagedChanges];
	[sortedChanges addObjectsFromArray:self.unstagedChanges];
	[sortedChanges addObjectsFromArray:self.untrackedChanges];
	[sortedChanges sortUsingSelector:@selector(compareByPath:)];
	
	self.changes = sortedChanges;
}


- (void) flushBlocks:(NSMutableArray*)mutableArray
{
	if (!mutableArray) return;
	
	NSArray* blocks = [mutableArray copy];
	[mutableArray removeAllObjects];
	for (void(^block)() in blocks)
	{
		block();
	}
	[blocks release];
}

@end
