#import "GBRepository.h"
#import "GBGitConfig.h"
#import "OABlockTable.h"
#import "GBTask.h"


@interface GBGitConfig ()
@property(nonatomic, strong) OABlockTable* blockTable;
@property(nonatomic, assign) BOOL disabledPathQuoting;
@end

@implementation GBGitConfig

@synthesize blockTable;
@synthesize disabledPathQuoting;
@synthesize repository;


+ (GBGitConfig*) userConfig
{
	static GBGitConfig* volatile userConfig = nil;
	static dispatch_once_t userConfigOnce = 0;
	dispatch_once( &userConfigOnce, ^{ 
		userConfig = [[self alloc] init];
		
	});
	return userConfig;
}

+ (GBGitConfig*) configForRepository:(GBRepository*)repo
{
	GBGitConfig* config = [self new];
	config.repository = repo;
	return config;
}

- (id) init
{
	if ((self = [super init]))
	{
		self.blockTable = [OABlockTable new];
	}
	return self;
}

- (BOOL) isUserConfig
{
	return !self.repository;
}


// Sync API


- (NSString*) stringForKey:(NSString*)key
{
	OATask* task              = [OATask task];
	task.currentDirectoryPath = [self.repository path];
	task.launchPath           = [GBTask pathToBundledBinary:@"git"];
	
	if ([self isUserConfig])
	{
		task.arguments = [NSArray arrayWithObjects:@"config", @"--global", key,  nil];
	}
	else
	{
		task.arguments = [NSArray arrayWithObjects:@"config", key,  nil];
	}
	[task launchAndWait];
	
	return [task UTF8OutputStripped];
}

- (void) setString:(NSString*)value forKey:(NSString*)key
{
	OATask* task              = [OATask task];
	task.currentDirectoryPath = [self.repository path];
	task.launchPath           = [GBTask pathToBundledBinary:@"git"];
	
	if ([self isUserConfig])
	{
		task.arguments = [NSArray arrayWithObjects:@"config", @"--global", key, value, nil];
	}
	else
	{
		task.arguments = [NSArray arrayWithObjects:@"config", key, value, nil];
	}
	[task launchAndWait];
}

- (void) removeKey:(NSString*)key
{
	OATask* task              = [OATask task];
	task.currentDirectoryPath = [self.repository path];
	task.launchPath           = [GBTask pathToBundledBinary:@"git"];
	
	if ([self isUserConfig])
	{
		task.arguments = [NSArray arrayWithObjects:@"config", @"--global", @"--unset-all", key, nil];
	}
	else
	{
		task.arguments = [NSArray arrayWithObjects:@"config", @"--unset-all", key, nil];
	}
	[task launchAndWait];
}

- (NSString*) userName
{
	return [self stringForKey:@"user.name"];
}

- (NSString*) userEmail
{
	return [self stringForKey:@"user.email"];
}




// Async API


- (void) stringForKey:(NSString*)key withBlock:(void(^)(NSString* value))aBlock
{
	aBlock = [aBlock copy];
	
	OATask* task              = [OATask task];
	task.currentDirectoryPath = [self.repository path];
	task.launchPath           = [GBTask pathToBundledBinary:@"git"];
	
	if ([self isUserConfig])
	{
		task.arguments = [NSArray arrayWithObjects:@"config", @"--global", key,  nil];
	}
	else
	{
		task.arguments = [NSArray arrayWithObjects:@"config", key,  nil];
	}
	
	if (self.repository)
	{
		[self.repository launchTask:task withBlock:^{
			if (aBlock) aBlock([task UTF8OutputStripped]);
		}];
	}
	else
	{
		[task launchWithBlock:^{
			if (aBlock) aBlock([task UTF8OutputStripped]);
		}];    
	}
}

- (void) setString:(NSString*)value forKey:(NSString*)key withBlock:(void(^)())aBlock
{
	aBlock = [aBlock copy];
	
	OATask* task              = [OATask task];
	task.currentDirectoryPath = [self.repository path];
	task.launchPath           = [GBTask pathToBundledBinary:@"git"];
	
	if ([self isUserConfig])
	{
		task.arguments = [NSArray arrayWithObjects:@"config", @"--global", key, value, nil];
	}
	else
	{
		task.arguments = [NSArray arrayWithObjects:@"config", key, value, nil];
	}
	
	if (self.repository)
	{
		[self.repository launchTask:task withBlock:^{
			if (aBlock) aBlock();
		}];
	}
	else
	{
		[task launchWithBlock:^{
			if (aBlock) aBlock();
		}];    
	}  
}

- (void) ensureDisabledPathQuoting:(void(^)())aBlock
{
	if (self.disabledPathQuoting)
	{
		if (aBlock) aBlock();
		return;
	}
	__weak __typeof(self) weakSelf = self;
	[self.blockTable addBlock:aBlock forName:@"ensureDisabledPathQuoting" proceedIfClear:^{
		[weakSelf setString:@"false" forKey:@"core.quotepath" withBlock:^{
			weakSelf.disabledPathQuoting = YES;
			[weakSelf.blockTable callBlockForName:@"ensureDisabledPathQuoting"];
		}];
	}];
}

- (void) setName:(NSString*)name email:(NSString*)email withBlock:(void(^)())aBlock
{
	aBlock = [aBlock copy];
	__weak __typeof(self) weakSelf = self;
	[self setString:name forKey:@"user.name" withBlock:^{
		[weakSelf setString:email forKey:@"user.email" withBlock:^{
			if (aBlock) aBlock();
		}];
	}];
}




@end
