#import "GBWindowControllerWithCallback.h"
#import "GBMainWindowController.h"

@implementation GBWindowControllerWithCallback

@synthesize completionHandler;

- (void) dealloc
{
	 completionHandler = nil;
}

- (void) performCompletionHandler:(BOOL)cancelled
{
	if (self.completionHandler) self.completionHandler(cancelled);
	self.completionHandler = nil;
}

- (void) presentSheetInMainWindow
{
	[self presentSheetInMainWindowSilent:NO];
}

- (void) presentSheetInMainWindowSilent:(BOOL)silent
{
	void(^block)(BOOL) = self.completionHandler;
	
	__typeof(self) strongSelf = self; // suppress "retain cycle" message
	self.completionHandler = ^(BOOL cancelled){
		if (block) block(cancelled);
		[[GBMainWindowController instance] dismissSheet:strongSelf];
	};
	[[GBMainWindowController instance] presentSheet:self silent:silent];
}

@end
