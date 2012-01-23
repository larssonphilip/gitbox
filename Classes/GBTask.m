#import "GBRepository.h"
#import "GBTask.h"

#import "NSData+OADataHelpers.h"


@implementation GBTask

@synthesize repository;
@synthesize ignoreMissingRepository;

# pragma mark Init

+ (id) taskWithRepository:(GBRepository*)repo
{
	GBTask* task = [self task];
	task.repository = repo;
	return task;
}

- (id) copyWithZone:(NSZone *)zone
{
	GBTask* newTask = [super copyWithZone:zone];
	newTask.repository = self.repository;
	return newTask;
}


# pragma mark Executables

+ (BOOL) isSnowLeopard
{
	return !NSClassFromString(@"NSPopover");
}

+ (NSString*) bundledGitVersion
{
	if ([self isSnowLeopard])
	{
		 // because Git 1.7.7 requires newer version of libcurl which is not installed by default on Snow Leopard without dev tools or with older dev tools.
		return @"1.7.5.4";
	}
	return @"1.7.7.2.3.g19dee";
}

+ (NSString*) pathToBundledBinary:(NSString*)name
{
	static NSString* cachedPathToGitBinary = nil;
	if (cachedPathToGitBinary && [name isEqual:@"git"]) return cachedPathToGitBinary;
	
	NSArray* paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
	
	if ([paths count] < 1)
	{
		NSLog(@"GBTask: Application Support directory is not found using NSSearchPathForDirectoriesInDomains!");
		return nil;
	}
	
	NSString* applicationSupportPath = [paths objectAtIndex:0];
	NSString* gitboxAppSupportPath = [applicationSupportPath stringByAppendingPathComponent:@"Gitbox"];
	NSString* pathToBundle = [gitboxAppSupportPath stringByAppendingPathComponent:[NSString stringWithFormat:@"git-%@/git.bundle", [self bundledGitVersion]]];
	
	NSFileManager* fm = [[[NSFileManager alloc] init] autorelease];
	
	if (![fm fileExistsAtPath:pathToBundle])
	{
		NSError* error = nil;
		NSString* parentBundlePath = [pathToBundle stringByDeletingLastPathComponent];
		if (![fm createDirectoryAtPath:parentBundlePath
		   withIntermediateDirectories:YES 
							attributes:nil 
								 error:&error])
		{
			NSLog(@"ERROR: GBTask: cannot create directory %@", parentBundlePath);
			NSAssert(0, @"GBTask: cannot create directory for extracted git.bundle!");
			return nil;
		}
		
		NSString* pathToTar = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"git.bundle-%@", [self bundledGitVersion]] ofType:@"tar"];
		if (!pathToTar)
		{
			NSLog(@"ERROR: Missing git.bundle.tar in the application package!");
			NSAssert(0, @"Missing git.bundle.tar in the application package!");
			return nil;
		}
		
		OATask* unpackTask = [OATask task];
		unpackTask.executableName = @"tar";
		unpackTask.arguments = [NSArray arrayWithObjects:@"-xf", pathToTar, @"-C", parentBundlePath, nil];
		unpackTask.currentDirectoryPath = [pathToTar stringByDeletingLastPathComponent];
		[unpackTask launchAndWait];
		
		// Note: asking nsbundle for the path again won't work: needs some time. (So we don't.)
	}
	
	if (!pathToBundle)
	{
		NSLog(@"ERROR: pathToBundle is nil!");
		NSAssert(0, @"pathToBundle is nil");
		return nil;
	}
	
	NSBundle* gitBundle = [NSBundle bundleWithPath:pathToBundle];
	NSString* pathToBinary = [gitBundle pathForResource:name ofType:nil inDirectory:@"libexec/git-core"];
	
	if ([name isEqual:@"git"]) cachedPathToGitBinary = [pathToBinary retain];
	return pathToBinary;
}



#pragma mark Helpers


- (void) willLaunchTask
{
	if (!self.repository && !self.ignoreMissingRepository)
	{
		NSException *exception = [NSException exceptionWithName:@"RepositoryIsNil"
														 reason:@"You may use [GBRepository task] to get a new configured GBTask"  userInfo:nil];
		@throw exception;
	}
	
	if (!self.currentDirectoryPath) 
	{
		self.currentDirectoryPath = self.repository.url.path;
	}
	if (!self.executableName && !self.launchPath)
	{
		self.executableName = @"git";
		self.launchPath = [GBTask pathToBundledBinary:self.executableName];
	}
}

@end
