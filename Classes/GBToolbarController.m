#import "GBToolbarController.h"

#import "GBPromptController.h"

#import "NSMenu+OAMenuHelpers.h"
#import "NSArray+OAArrayHelpers.h"
#import "NSString+OAStringHelpers.h"


@interface GBToolbarController ()
@property(nonatomic, retain) NSMutableDictionary* itemsByIdentifier;
- (void) updateAlignment;
@end


@implementation GBToolbarController

@synthesize toolbar;
@synthesize window;
@synthesize sidebarWidth;
@synthesize itemsByIdentifier;

// obsolete
@synthesize currentBranchPopUpButton;
@synthesize pullPushControl;
@synthesize pullButton;
@synthesize remoteBranchPopUpButton;
@synthesize progressIndicator;
@synthesize commitButton;


- (void) dealloc
{
  self.toolbar = nil; // setter will safely reset delegate as needed
  self.window = nil;
  self.itemsByIdentifier = nil;

  // obsolete
  self.currentBranchPopUpButton = nil;
  self.pullPushControl = nil;
  self.pullButton = nil;
  self.remoteBranchPopUpButton = nil;
  self.progressIndicator = nil;
  self.commitButton = nil;
  [super dealloc];
}


- (void) setSidebarWidth:(CGFloat)aWidth
{
  sidebarWidth = aWidth;
  [self updateAlignment];
}


- (void) setToolbar:(NSToolbar *)aToolbar
{
  if (toolbar == aToolbar) return;
  
  if ([toolbar delegate] == self) [toolbar setDelegate:nil];
  [toolbar release];
  toolbar = [aToolbar retain];
  [toolbar setDelegate:self];
  
  [self update];
}


- (NSToolbarItem*) toolbarItemForIdentifier:(NSString*)itemIdentifier
{
  return [self.itemsByIdentifier objectForKey:itemIdentifier];
  return nil;
}




#pragma NSToolbarDelegate



//- (NSToolbarItem*)toolbar:(NSToolbar*)aToolbar itemForItemIdentifier:(NSString*)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
//{
//  // get the item from dictionary or create if missing
//  
//}







#pragma mark UI update methods




- (void) update
{
  [self updateAlignment];
}


- (void) updateAlignment
{
  static CGFloat spaceForMissingSettingsButton = 38.0; // remove this when settings button will come back
  CGFloat paddingOffset = -11.0 - 76.0 + spaceForMissingSettingsButton; // right spacing + "add" and "settings" buttons widths and their paddings
  static NSInteger spaceItemIndex = 1;
  
  if ([[self.toolbar items] count] <= spaceItemIndex) return;
  NSToolbarItem* spaceItem = [[self.toolbar items] objectAtIndex:spaceItemIndex];
  
  NSSize size = [spaceItem minSize];
  size.width = self.sidebarWidth + paddingOffset;
  [spaceItem setMaxSize:size];
  [spaceItem setMinSize:size];
}



@end
