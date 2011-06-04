#import "GBRepositorySettingsController.h"
#import "GBRepositorySettingsViewController.h"
#import "GBRepository.h"

@interface GBRepositorySettingsController () <NSTabViewDelegate>
@property(nonatomic, retain) NSArray* viewControllers;
@end

@implementation GBRepositorySettingsController

@synthesize repository;
@synthesize cancelButton;
@synthesize saveButton;
@synthesize tabView;
@synthesize viewControllers;

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
    self.viewControllers = [NSArray arrayWithObjects:
                            
                            nil];
  }
  return self;
}


- (void) performCompletionHandler:(BOOL)cancelled
{
  // TODO: go through all view controllers and save or cancel them if needed
  
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
  }
  
}



#pragma mark NSTabViewDelegate


- (void)tabView:(NSTabView *)aTabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
  
}


@end
