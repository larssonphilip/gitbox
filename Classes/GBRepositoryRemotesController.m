#import "GBRepositoryRemotesController.h"
#import "GBRepository.h"
#import "GBRemote.h"
#import "GBTask.h"

@interface GBRepositoryRemotesController ()
- (NSMutableArray*) remotesDictionariesForRepository:(GBRepository*)repo;
- (void) syncRemotesDictionariesWithRepository;
@end

@implementation GBRepositoryRemotesController

@synthesize remotesDictionaries;

- (void) dealloc
{
	[remotesDictionaries release]; remotesDictionaries = nil;
	[super dealloc];
}

- (id) initWithRepository:(GBRepository *)repo
{
	if ((self = [super initWithRepository:repo]))
	{
		self.remotesDictionaries = [NSMutableArray array];
	}
	return self;
}

- (NSString*) title
{
	return NSLocalizedString(@"Servers", @"");
}

- (void) cancel
{
	self.remotesDictionaries = [NSMutableArray array];
}

- (void) save
{
	[self syncRemotesDictionariesWithRepository];
}

- (void) viewDidAppear
{
	[super viewDidAppear];
	
	self.remotesDictionaries = [self remotesDictionariesForRepository:self.repository];
}



#pragma mark Private


- (NSMutableArray*) remotesDictionariesForRepository:(GBRepository*)repo
{
	NSMutableArray* list = [NSMutableArray array];
	for (GBRemote* remote in self.repository.remotes)
	{
		[list addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
						 remote.alias, @"alias",
						 remote.URLString, @"URLString",
						 nil]];
	}
	
	if ([list count] == 0) // new repo, add a default "origin" entry
	{
		[list addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
						 @"origin", @"alias",
						 @"", @"URLString",
						 nil]];    
	}
	
	return list;
}


- (void) syncRemotesDictionariesWithRepository
{
	NSArray* oldAliases = [self.repository.remotes valueForKey:@"alias"];
	NSArray* newAliases = [self.remotesDictionaries valueForKey:@"alias"];
	
	NSMutableArray* removedAliases = [[oldAliases mutableCopy] autorelease];
	[removedAliases removeObjectsInArray:newAliases];
	
	NSMutableArray* addedAliases = [[newAliases mutableCopy] autorelease];
	[addedAliases removeObjectsInArray:oldAliases];
	
	for (NSString* alias in removedAliases)
	{
		GBTask* task = [self.repository task];
		task.arguments = [NSArray arrayWithObjects:@"config", 
						  @"--remove-section", 
						  [NSString stringWithFormat:@"remote.%@", alias], 
						  nil];
		[self.repository launchTaskAndWait:task];
	}
	
	for (NSString* alias in addedAliases)
	{
		NSString* URLString = nil;
		for (NSDictionary* dict in self.remotesDictionaries)
		{
			if ([[dict objectForKey:@"alias"] isEqualToString:alias])
			{
				URLString = [dict objectForKey:@"URLString"];
			}
		}
		
		if (URLString && [URLString length] > 0)
		{
			GBTask* task = [self.repository task];
			task.arguments = [NSArray arrayWithObjects:@"config", 
							  [NSString stringWithFormat:@"remote.%@.fetch", alias], 
							  [NSString stringWithFormat:@"+refs/heads/*:refs/remotes/%@/*", alias],
							  nil];
			
			[self.repository launchTaskAndWait:task];
			
			task = [self.repository task];
			task.arguments = [NSArray arrayWithObjects:@"config", 
							  [NSString stringWithFormat:@"remote.%@.url", alias], 
							  URLString,
							  nil];
			
			[self.repository launchTaskAndWait:task];
		}
	}
	
	// Since we listen to FSEvent, changes done here should automatically apply
	//if (dirtyFlag) [self.repository loadRemotesWithBlock:^{}];
	
	for (GBRemote* remote in self.repository.remotes)
	{
		NSDictionary* updatedDict = nil;
		for (NSDictionary* dict in self.remotesDictionaries)
		{
			if ([[dict objectForKey:@"alias"] isEqualToString:remote.alias])
			{
				updatedDict = dict;
			}
		}
		
		NSString* newURLString = [updatedDict objectForKey:@"URLString"];
		if (newURLString && [newURLString length] > 0 && ![newURLString isEqualToString:remote.URLString])
		{
			//dirtyFlag = YES;
			GBTask* task = [self.repository task];
			task.arguments = [NSArray arrayWithObjects:@"config", 
							  [NSString stringWithFormat:@"remote.%@.url", remote.alias], 
							  newURLString,
							  nil];
			[self.repository launchTaskAndWait:task];
		}
	}
}

@end
