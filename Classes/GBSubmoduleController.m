#import "GBSubmoduleController.h"
#import "GBSubmodule.h"
#import "GBRepository.h"
#import "GBStage.h"
#import "GBSubmoduleCell.h"
#import "GBSidebarItem.h"

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
		
		self.sidebarItem = [[[GBSidebarItem alloc] init] autorelease];
		self.sidebarItem.object = self;
		self.sidebarItem.draggable = NO;
		self.sidebarItem.selectable = YES;
		self.sidebarItem.editable = NO;
		self.sidebarItem.cell = [[[GBSubmoduleCell alloc] initWithItem:self.sidebarItem] autorelease];
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

- (IBAction) resetSubmodule:(id)sender
{
	[self pushSpinning];
	[self pushDisabled];
	
	// Retain here because the parentRepo might be replaced already when checkout is done.
	GBStage* stage = self.submodule.parentRepository.stage;
	
	[self.submodule updateHeadWithBlock:^{
		
		// 1. Predict the status before we actually update the stage of the parent to avoid blinking of "checkout" button
		// 2. Don't need that because we'll stop spinning when stage is updated.
		// 3. This doesn't really work, so let's predict the status.
		self.submodule.status = GBSubmoduleStatusUpToDate; 

#warning TODO: check that this does not break anything. Should normally go to parent repo ctrl.
		[stage updateStageWithBlock:^(BOOL contentDidChange) {
			[self popSpinning];
			[self popDisabled];
		}];
	}];
}

@end
