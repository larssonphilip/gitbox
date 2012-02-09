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
@synthesize commitId=_commitId;

- (void) dealloc
{
	//NSLog(@"GBSubmodule#dealloc");
	[_remoteURL release];
	[_path release];
	[_status release];
	[_commitId release];
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

- (NSString*) description
{
	return [NSString stringWithFormat:@"<%@:%p path:%@ URL:%@ status:%@ head:%@>", [self class], self, self.path, self.remoteURL, self.status, self.commitId];
}


@end
