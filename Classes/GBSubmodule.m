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
		dispatchQueue = aDispatchQueue;
	}
}



#pragma mark - Persistence



- (id) plistRepresentation
{
	return [NSDictionary dictionaryWithObjectsAndKeys:
			self.path, @"path",
			self.parentURL.path, @"parentPath",
			[self.remoteURL absoluteString], @"remoteURLString",
			self.commitId, @"commitId",
			self.status, @"status",
			nil];
}

- (void) setPlistRepresentation:(id)plist
{
	self.path = [plist objectForKey:@"path"];
	self.parentURL = [NSURL fileURLWithPath:[plist objectForKey:@"parentPath"]];
	self.remoteURL = [NSURL URLWithString:[plist objectForKey:@"remoteURLString"]];
	self.commitId = [plist objectForKey:@"commitId"];
	self.status = [plist objectForKey:@"status"];
}


@end
