#import "GBSubmodule.h"
#import "GBRepository.h"
#import "GBTask.h"

NSString* const GBSubmoduleStatusNotCloned   = @"GBSubmoduleStatusNotCloned";
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
// I've checked that this method returns file URL (isFileURL)
//	fileURL = file://localhost/Users/oleganza/
//	pathURL = ./Work/gitbox -- file://localhost/Users/oleganza/
//	pathURL isFileURL = 1
//	pathURL path = /Users/oleganza/Work/gitbox
//	pathURL absolute path = /Users/oleganza/Work/gitbox
	return [NSURL URLWithString:self.path relativeToURL:self.parentRepository.url];
}

- (BOOL) isCloned
{
	return ![self.status isEqualToString:GBSubmoduleStatusNotCloned];
}

- (void) updateHeadWithBlock:(void(^)())block
{
	GBTask* task = [self.parentRepository task];
	task.arguments = [NSArray arrayWithObjects:@"submodule", @"update", @"--init", @"--", self.localURL.path, nil];
	[self.parentRepository launchTask:task withBlock:block];
}


@end
