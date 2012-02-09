#import "GBSubmodule.h"
#import "GBRepository.h"
#import "GBTask.h"

NSString* const GBSubmoduleStatusNotCloned   = @"GBSubmoduleStatusNotCloned";
NSString* const GBSubmoduleStatusJustCloned  = @"GBSubmoduleStatusJustCloned";
NSString* const GBSubmoduleStatusUpToDate    = @"GBSubmoduleStatusUpToDate";
NSString* const GBSubmoduleStatusNotUpToDate = @"GBSubmoduleStatusNotUpToDate";

@interface GBSubmodule ()
@end 

@implementation GBSubmodule

@synthesize parentRepository=_parentRepository;
@synthesize remoteURL=_remoteURL;
@synthesize path=_path;
@synthesize status=_status;

- (void) dealloc
{
	//NSLog(@"GBSubmodule#dealloc");
	self.remoteURL = nil;
	self.path      = nil;
	self.status    = nil;
	
	[super dealloc];
}

- (NSURL*) localURL
{
	return [self.parentRepository URLForRelativePath:self.path];
}

- (void) updateHeadWithBlock:(void(^)())block
{
	GBTask* task = [self.parentRepository task];
	task.arguments = [NSArray arrayWithObjects:@"submodule", @"update", @"--init", @"--", self.localURL.path, nil];
	[self.parentRepository launchTask:task withBlock:block];
}


@end
