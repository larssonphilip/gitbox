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

- (NSMenu*) sidebarItemMenu
{
	NSMenu* aMenu = [[[NSMenu alloc] initWithTitle:@""] autorelease];
	
	[self addOpenMenuItemsToMenu:aMenu];

	// TODO: add options to add existing folder as a submodule or a URL
	
//	[aMenu addItem:[NSMenuItem separatorItem]];
//	[aMenu addItem:[[[NSMenuItem alloc] 
//					 initWithTitle:NSLocalizedString(@"Add Repository...", @"Sidebar") action:@selector(openDocument:) keyEquivalent:@""] autorelease]];
//	[aMenu addItem:[[[NSMenuItem alloc] 
//					 initWithTitle:NSLocalizedString(@"Clone Repository...", @"Sidebar") action:@selector(cloneRepository:) keyEquivalent:@""] autorelease]];
	
	return aMenu;
}

@end
