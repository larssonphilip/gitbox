#import "GBSubmoduleController.h"
#import "GBSubmodule.h"

@implementation GBSubmoduleController

@synthesize submodule=_submodule;

- (void) dealloc
{
	self.submodule = nil;
	[super dealloc];
}

+ (GBSubmoduleController*) controllerWithSubmodule:(GBSubmodule*)submodule
{
	if (!submodule) return nil;
	return [[[self alloc] initWithSubmodule:submodule] autorelease];
}

- (id) initWithSubmodule:(GBSubmodule*)submodule
{
	if (self = [super initWithURL:submodule.localURL])
	{
		self.submodule = submodule;
	}
	return self;
}

@end
