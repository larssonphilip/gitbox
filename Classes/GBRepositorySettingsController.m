#import "GBRepositorySettingsController.h"
#import "GBRepositorySettingsViewController.h"
#import "GBRepository.h"

#import "GBRepositorySummaryController.h"
#import "GBRepositoryBranchesAndTagsController.h"


@interface GBRepositorySettingsController () <NSTabViewDelegate>
@property(nonatomic, retain) NSArray* viewControllers;
@property(nonatomic, assign, getter=isDirty) BOOL dirty;
@end

@implementation GBRepositorySettingsController

@synthesize repository;
@synthesize cancelButton;
@synthesize saveButton;
@synthesize tabView;
@synthesize viewControllers;
@synthesize dirty;

- (void) dealloc
{
  [repository release]; repository = nil;
  [viewControllers release]; viewControllers = nil;
  
  [cancelButton release]; cancelButton = nil;
  [saveButton release]; saveButton = nil;
  [tabView release]; tabView = nil;
  
  [super dealloc];
}

- (id)initWithWindow:(NSWindow *)aWindow
{
  if ((self = [super initWithWindow:aWindow]))
  {
  }
  return self;
}

- (void) presentSheetInMainWindow
{
  // Not the best place to init controllers, but at least we have the repository here.
  self.viewControllers = [NSArray arrayWithObjects:
                          [[[GBRepositorySummaryController alloc] initWithRepository:self.repository] autorelease],
                          [[[GBRepositoryBranchesAndTagsController alloc] initWithRepository:self.repository] autorelease],
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
    [self.cancelButton setHidden:NO];
    [self.saveButton setTitle:NSLocalizedString(@"Save", nil)];
  }
  else
  {
    [self.cancelButton setHidden:YES];
    [self.saveButton setTitle:NSLocalizedString(@"OK", nil)];
  }
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
  
  NSArray* tabItems = [[[self.tabView tabViewItems] copy] autorelease];
  for (NSTabViewItem* item in tabItems)
  {
    [self.tabView removeTabViewItem:item];
  }
  
  // Add items for each view controller
  
  for (GBRepositorySettingsViewController* vc in self.viewControllers)
  {
    NSTabViewItem* item = [[[NSTabViewItem alloc] initWithIdentifier:nil] autorelease];
    [item setLabel:vc.title ? vc.title : @""];
    [item setView:[vc view]];
    [self.tabView addTabViewItem:item];
    [vc viewDidLoad];
  }
  
  // TODO: select another controller if client asked. Avoid double calling of viewDidAppear.
  
  [[self.viewControllers objectAtIndex:0] viewDidAppear];
  
  self.dirty = YES;
  self.dirty = NO;
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
  completion = [[completion copy] autorelease];
  
  NSAlert* alert = [[[NSAlert alloc] init] autorelease];
  
  if (message) [alert setMessageText:message];
  if (desc) [alert setInformativeText:desc];
  [alert setAlertStyle:NSCriticalAlertStyle];
  
  [alert addButtonWithTitle:okOrNil ? okOrNil : NSLocalizedString(@"OK", nil)];
  [alert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
  
  [completion retain];
  [alert beginSheetModalForWindow:[self window]
                    modalDelegate:self 
                   didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) 
                      contextInfo:completion];
}

- (void) alertDidEnd:(NSAlert*)alert returnCode:(NSInteger)returnCode contextInfo:(void(^)(BOOL))completion
{
  if (completion) completion(returnCode == NSAlertFirstButtonReturn);
  [completion release];
}



@end
