#import "GBRemote.h"
#import "GBRepository.h"
#import "GBRef.h"
#import "GBRemoteRefsTask.h"

#import "NSFileManager+OAFileManagerHelpers.h"
#import "NSArray+OAArrayHelpers.h"


@interface GBRemote ()
@property(nonatomic,retain) NSArray* transientBranches;
@property(nonatomic,assign) BOOL isUpdatingRemoteBranches;
- (BOOL) doesNeedFetchNewBranches:(NSArray*)theBranches andTags:(NSArray*)theTags;
@end

@implementation GBRemote

@synthesize alias;
@synthesize URLString;
@synthesize fetchRefspec;
@synthesize branches;
@synthesize transientBranches;

@synthesize repository;
@synthesize isUpdatingRemoteBranches;
@synthesize needsFetch;

- (void) dealloc
{
	self.alias = nil;
	self.URLString = nil;
	self.fetchRefspec = nil;
	self.branches = nil;
	self.transientBranches = nil;
	[super dealloc];
}


#pragma mark Init


- (NSArray*) branches
{
	if (!branches) self.branches = [NSArray array];
	return [[branches retain] autorelease];
}

- (NSArray*) transientBranches
{
	if (!transientBranches) self.transientBranches = [NSArray array];
	return [[transientBranches retain] autorelease];
}

- (NSString*)description
{
	return [NSString stringWithFormat:@"<%@:%p %@ %@ [%lu refs, %lu transient refs]>", [self class], self, self.alias, self.URLString, self.branches.count, self.transientBranches.count];
}



#pragma mark Interrogation


- (GBRef*) defaultBranch
{
	for (GBRef* ref in self.branches)
	{
		if ([ref.name isEqualToString:@"master"]) return ref;
	}
	return [self.branches firstObject];
}

- (NSArray*) pushedAndNewBranches
{
	return [self.branches arrayByAddingObjectsFromArray:self.transientBranches];
}

- (void) updateNewBranches
{
	NSArray* names = [self.branches valueForKey:@"name"];
	NSMutableArray* updatedNewBranches = [NSMutableArray array];
	//BOOL hasRemovedTransientBranch = NO;
	for (GBRef* aBranch in self.transientBranches)
	{
		if (aBranch.name && ![names containsObject:aBranch.name])
		{
			[updatedNewBranches addObject:aBranch];
		}
		else
		{
			//hasRemovedTransientBranch = YES;
		}
	}
	self.transientBranches = updatedNewBranches;
////	NSLog(@">>> [GBRemote updateNewBranches] %@ : transientBranches: %@", self, self.transientBranches);
//	if (hasRemovedTransientBranch)
//	{
////		NSLog(@"DEBUG: Removed transient branch!");
//	}
}

- (void) updateBranches
{
	[self updateNewBranches];
}

- (BOOL) copyInterestingDataFromRemoteIfApplicable:(GBRemote*)otherRemote
{
	if (self.alias && [otherRemote.alias isEqualToString:self.alias])
	{
		self.transientBranches = otherRemote.transientBranches;
		[self updateBranches];
		return YES;
	}
	return NO;
}

- (NSString*) defaultFetchRefspec
{
	return [NSString stringWithFormat:@"+refs/heads/*:refs/remotes/%@/*", self.alias];
}




#pragma mark Actions


- (BOOL) isTransientBranch:(GBRef*)branch
{
	if (!branch) return NO;
	return ![self.branches containsObject:branch];
}

- (void) addNewBranch:(GBRef*)branch
{
	self.transientBranches = [self.transientBranches arrayByAddingObject:branch];
}

- (void) updateBranchesSilently:(BOOL)silently withBlock:(void(^)())block
{
	block = [[block copy] autorelease];
	
	if (self.isUpdatingRemoteBranches)
	{
		if (block) block();
		return;
	}
	
	self.isUpdatingRemoteBranches = YES;
	
	GBRemoteRefsTask* aTask = [GBRemoteRefsTask task];
	aTask.remoteAddress = self.URLString;
	aTask.silent = silently;
	aTask.repository = self.repository;
	aTask.remote = self;
	[self.repository launchRemoteTask:aTask withBlock:^{
		self.isUpdatingRemoteBranches = NO;
		if (![aTask isError])
		{
			// Do not update branches and tags, but simply tell the caller that it needs to fetch tags and branches for real.
			self.needsFetch = [self doesNeedFetchNewBranches:aTask.branches andTags:aTask.tags];
			
			if (block) block();
			
			self.needsFetch = NO; // reset the status after the callback
		}
		else
		{
			if (block) block();
		}
	}];
}

- (BOOL) doesNeedFetchNewBranches:(NSArray*)theBranches andTags:(NSArray*)theTags
{
	// Set needsFetch = YES if one of the following is true:
	// 1. There's a new branch
	// 2. The branch exists, but commitId differ
	// 3. The tag does not exists
	
	// This code is not optimal, but if you don't have thousands of branches, this should be enough.
	
	for (GBRef* updatedRef in theBranches)
	{
		BOOL foundAnExistingBranch = NO;
		for (GBRef* existingRef in self.branches)
		{
			if ([updatedRef.name isEqual:existingRef.name])
			{
				foundAnExistingBranch = YES;
				if (![updatedRef.commitId isEqual:existingRef.commitId])
				{
					//NSLog(@"NEEDS FETCH? refs are different: %@ -> %@ [%@]", existingRef, updatedRef, self.alias);
					return YES;
				}
			}
		}
		if (!foundAnExistingBranch)
		{
			//NSLog(@"NEEDS FETCH? did not find an existing ref for %@ [%@]", updatedRef, self.alias);
			return YES;
		}
	}
	
	NSMutableArray* newTagNames = [[[theTags valueForKey:@"name"] mutableCopy] autorelease];
#warning FIXME: crashed here on repository.tags; need a proper zeroing.
	
	[newTagNames removeObjectsInArray:[self.repository.tags valueForKey:@"name"]];
	
	if (newTagNames.count > 0)
	{
		//NSLog(@"NEEDS FETCH? new tag names found: %@ [%@]", [newTagNames componentsJoinedByString:@", "], self.alias);
		return YES;
	}
	
	return NO;
}


@end
