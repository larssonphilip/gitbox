#import "GBRepositorySettingsController.h"
#import "GBRepositorySettingsViewController.h"
#import "GBRepository.h"

#import "GBRepositorySummaryController.h"
#import "GBRepositoryBranchesAndTagsController.h"
#import "GBRepositoryRemotesController.h"
#import "GBRepositoryConfigController.h"

NSString* const GBRepositorySettingsSummary         = @"GBRepositorySettingsSummary";
NSString* const GBRepositorySettingsBranchesAndTags = @"GBRepositorySettingsBranchesAndTags";
NSString* const GBRepositorySettingsRemoteServers   = @"GBRepositorySettingsRemoteServers";
NSString* const GBRepositorySettingsGitConfig       = @"GBRepositorySettingsGitConfig";

@interface GBRepositorySettingsController () <NSTabViewDelegate>
@property(nonatomic, strong) NSArray* viewControllers;
@property(nonatomic, strong, readwrite) NSMutableDictionary* userInfo;
@property(nonatomic, assign, getter=isDirty) BOOL dirty;
@property(nonatomic, assign, getter=areTabsPrepared) BOOL tabsPrepared;
@property(nonatomic, assign, readwrite, getter=isDisabled) BOOL disabled;
- (void) syncSelectedTab;
- (void) selectTabViewItemAtIndex:(NSInteger)i;
@end

@implementation GBRepositorySettingsController

@synthesize repository;
@synthesize userInfo;
@synthesize selectedTab;
@synthesize cancelButton;
@synthesize saveButton;
@synthesize tabView;
@synthesize viewControllers;
@synthesize dirty;
@synthesize tabsPrepared;
@synthesize disabled;


+ (id) controllerWithTab:(NSString*)tab repository:(GBRepository*)repo
{
	GBRepositorySettingsController* ctrl = [[GBRepositorySettingsController alloc] initWithWindowNibName:@"GBRepositorySettingsController"];
	ctrl.repository = repo;
	ctrl.selectedTab = tab;
	return ctrl;
}

- (id)initWithWindow:(NSWindow *)aWindow
{
	if ((self = [super initWithWindow:aWindow]))
	{
		selectedTab = [GBRepositorySettingsSummary copy];
		self.userInfo = [NSMutableDictionary dictionary];
	}
	return self;
}

- (void) dealloc
{
}

- (void) presentSheetInMainWindow
{
	// Not the best place to init controllers, but at least we have the repository here.
	self.viewControllers = [NSArray arrayWithObjects:
							[[GBRepositorySummaryController alloc] initWithRepository:self.repository],
							[[GBRepositoryBranchesAndTagsController alloc] initWithRepository:self.repository],
							[[GBRepositoryRemotesController alloc] initWithRepository:self.repository],
							[[GBRepositoryConfigController alloc] initWithRepository:self.repository],
							nil];
	
	for (GBRepositorySettingsViewController* ctrl in self.viewControllers)
	{
		ctrl.settingsController = self;
	}
	
	[super presentSheetInMainWindow];
}

- (void) performCompletionHandler:(BOOL)cancelled
{
	for (GBRepositorySettingsViewController* ctrl in self.viewControllers)
	{
		if (cancelled)
		{
			[ctrl cancel];
		}
		else
		{
			[ctrl save];
		}
	}
	[super performCompletionHandler:cancelled];
}

- (IBAction) cancel:(id)sender
{
	[self performCompletionHandler:YES];
}

- (IBAction) save:(id)sender
{
	[self performCompletionHandler:NO];
}

- (void) setDirty:(BOOL)flag
{
	if (flag == dirty) return;
	dirty = flag;
	
	if (dirty)
	{
		//[self.cancelButton setHidden:NO];
		[self.saveButton setTitle:NSLocalizedString(@"OK", nil)];
	}
	else
	{
		//[self.cancelButton setHidden:YES];
		[self.saveButton setTitle:NSLocalizedString(@"OK", nil)];
	}
}

- (void) setSelectedTab:(NSString*)tabName
{
	if (!tabName) tabName = GBRepositorySettingsSummary;
	if (selectedTab == tabName) return;
	
	selectedTab = [tabName copy];
	
	[self syncSelectedTab];
}

- (void) didUpdateDisabledStatus
{
	[self.cancelButton setEnabled:disabled < 1];
	[self.saveButton setEnabled:disabled < 1];
}

- (void) pushDisabled
{
	self.disabled++;
	[self didUpdateDisabledStatus];
}

- (void) popDisabled
{
	self.disabled--;
	[self didUpdateDisabledStatus];
}




#pragma mark Notifications from tabs


- (void) viewControllerDidChangeDirtyStatus:(GBRepositorySettingsViewController*)ctrl
{
	// update the buttons titles and labels
	BOOL anyDirty = NO;
	
	for (GBRepositorySettingsViewController* ctrl in self.viewControllers)
	{
		anyDirty = anyDirty || [ctrl isDirty];
		if (anyDirty) break;
	}
	
	self.dirty = anyDirty;
}



#pragma mark NSWindowDelegate


- (void)windowDidLoad
{
	[super windowDidLoad];
	
	// Remove items added in the Nib
	
	NSArray* tabItems = [[self.tabView tabViewItems] copy];
	for (NSTabViewItem* item in tabItems)
	{
		[self.tabView removeTabViewItem:item];
	}
	
	// Add items for each view controller
	
	for (GBRepositorySettingsViewController* vc in self.viewControllers)
	{
		NSTabViewItem* item = [[NSTabViewItem alloc] initWithIdentifier:nil];
		[item setLabel:vc.title ? vc.title : @""];
		[item setView:[vc view]];
		[self.tabView addTabViewItem:item];
		[vc viewDidLoad];
	}
	
	self.dirty = YES;
	self.dirty = NO;
	
	self.tabsPrepared = YES;
	
	[self syncSelectedTab];
}



#pragma mark NSTabViewDelegate


- (void)tabView:(NSTabView *)aTabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
	for (GBRepositorySettingsViewController* c in self.viewControllers)
	{
		if ([c view] == [tabViewItem view])
		{
			[c viewDidAppear];
			break;
		}
	}
}



#pragma mark Confirmation sheet


- (void) criticalConfirmationWithMessage:(NSString*)message description:(NSString*)desc ok:(NSString*)okOrNil completion:(void(^)(BOOL))completion
{
	completion = [completion copy];
	
	NSAlert* alert = [[NSAlert alloc] init];
	
	if (message) [alert setMessageText:message];
	if (desc) [alert setInformativeText:desc];
	[alert setAlertStyle:NSCriticalAlertStyle];
	
	[alert addButtonWithTitle:okOrNil ? okOrNil : NSLocalizedString(@"OK", nil)];
	[alert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
	
	[alert beginSheetModalForWindow:[self window]
					  modalDelegate:self 
					 didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) 
						contextInfo:(__bridge_retained void *)(completion)];
}

- (void) alertDidEnd:(NSAlert*)alert returnCode:(NSInteger)returnCode contextInfo:(void*)ctx
{
	void(^completion)(BOOL) = (__bridge_transfer void(^)(BOOL))ctx;
	if (completion) completion(returnCode == NSAlertFirstButtonReturn);
}




#pragma mark Private



- (void) syncSelectedTab
{
	if (![self areTabsPrepared]) return;
	
	// Note: selectTabViewItem notifies the delegate
	if (selectedTab == GBRepositorySettingsSummary)
	{
		[self selectTabViewItemAtIndex:0];
	}
	else if (selectedTab == GBRepositorySettingsBranchesAndTags)
	{
		[self selectTabViewItemAtIndex:1];
	}
	else if (selectedTab == GBRepositorySettingsRemoteServers)
	{
		[self selectTabViewItemAtIndex:2];
	}
	else if (selectedTab == GBRepositorySettingsGitConfig)
	{
		[self selectTabViewItemAtIndex:3];
	}
}


- (void) selectTabViewItemAtIndex:(NSInteger)i
{
	if (i >= 0 && i < [[self.tabView tabViewItems] count])
	{
		[self.tabView selectTabViewItem:[self.tabView tabViewItemAtIndex:i]];
	}
}


@end
