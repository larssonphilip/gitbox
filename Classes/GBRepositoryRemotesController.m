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
	return NSLocalizedString(@"Remote Repositories", @"");
}

- (void) cancel
{
	self.remotesDictionaries = [NSMutableArray array];
}

- (void) save
{
	[self syncRemotesDictionariesWithRepository];
}

- (void) viewDidLoad
{
	[super viewDidLoad];
	
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
	
	NSMutableArray* removedAliases = [oldAliases mutableCopy];
	[removedAliases removeObjectsInArray:newAliases];
	
	NSMutableArray* addedAliases = [newAliases mutableCopy];
	[addedAliases removeObjectsInArray:oldAliases];
	
	BOOL didChange = NO;
	
	for (NSString* alias in removedAliases)
	{
		GBTask* task = [self.repository task];
		task.arguments = [NSArray arrayWithObjects:@"config", 
						  @"--remove-section", 
						  [NSString stringWithFormat:@"remote.%@", alias], 
						  nil];
		[self.repository launchTaskAndWait:task];
		didChange = YES;
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
			didChange = YES;
		}
	}
	
	// Since we listen to FSEvent, changes done here should automatically apply
	//if (dirtyFlag) [self.repository updateRemotesWithBlock:^{}];
	
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
			didChange = YES;
		}
	}
	
	if (didChange)
	{
		double delayInSeconds = 0.0;
		dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
		dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
			[NSApp sendAction:@selector(fetch:) to:nil from:nil];
		});
	}
}

@end
