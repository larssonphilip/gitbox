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

@synthesize path=_path;
@synthesize parentURL=_parentURL;
@synthesize remoteURL=_remoteURL;
@synthesize status=_status;
@synthesize commitId=_commitId;
@synthesize dispatchQueue;

- (void) dealloc
{
	//NSLog(@"GBSubmodule#dealloc");
	if (dispatchQueue) dispatch_release(dispatchQueue);
	[_remoteURL release];
	[_path release];
	[_parentURL release];
	[_status release];
	[_commitId release];
	[super dealloc];
}

- (NSURL*) localURL
{
	return [NSURL fileURLWithPath:[self.parentURL.path stringByAppendingPathComponent:self.path]];
}

- (NSString*) description
{
	return [NSString stringWithFormat:@"<%@:%p path:%@ URL:%@ status:%@ head:%@>", [self class], self, self.path, self.remoteURL, self.status, self.commitId];
}

- (void) setDispatchQueue:(dispatch_queue_t)aDispatchQueue
{
	if (aDispatchQueue)
	{
		if (dispatchQueue) dispatch_release(dispatchQueue);
		dispatch_retain(aDispatchQueue);
		dispatchQueue = aDispatchQueue;
	}
}


@end
