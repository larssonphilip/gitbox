
#import "GBRepositoryRefreshStateMachine.h"

/*

Factors:

1. Internal "needs update" flag - when the app itself knows that something has changed.
2. External notification "folder did update" - could be used or not used.
3. The previous history of changes - when was the last time we have really update the state.
4. Current timeout (multiplied by 1.5 each time it's increased)
 
States:
 
1. Needs update something.
2. Does not need update anything, no idle history.
3. Does not need update anything, has idle history.

*/

@implementation GBRepositoryRefreshStateMachine

- (void) start
{
	// start timer
}

- (void) stop
{
	// stop timer, reset flags
}



@end
