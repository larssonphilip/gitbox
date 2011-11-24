
#import "GBRepositoryMonitor.h"

/*

Factors:

1. Internal "needs update" flag - when the app itself knows that something has changed.
2. External notification "folder did update" - could be used or not used.
3. The previous history of changes - when was the last time we have really updated the state.
4. Current timeout (multiplied by 1.5 each time it's increased)
 
States:
 
1. Needs update something.
2. Does not need update anything, no idle history.
3. Does not need update anything, has idle history.

*/

@interface GBRepositoryMonitor ()

@property(nonatomic, copy, readwrite) NSString* path;
@property(nonatomic, assign) BOOL needsUpdateStage; // will update stage only
@property(nonatomic, assign) BOOL needsUpdateRefs; // will update refs and stage

- (void) didTouchDotGit;
- (void) didTouchWorkingDirectory;

@end

@implementation GBRepositoryRefreshStateMachine

@synthesize path=_path;
@synthesize needsUpdateStage;
@synthesize needsUpdateRefs;

- (id) initWithPath:(NSString*)path eventStream:(OAFSEventStream*)eventStream
{
	if (self = [super init])
	{
		self.path = path;
	}
	return self;
}

- (void)dealloc
{
    [_path release];
    [super dealloc];
}

- (void) start
{
	// start timer
}

- (void) stop
{
	// stop timer, reset flags
}



@end
