#import "GBToolbarController.h"

#import "GBPromptController.h"

#import "NSMenu+OAMenuHelpers.h"
#import "NSArray+OAArrayHelpers.h"
#import "NSString+OAStringHelpers.h"


@interface GBToolbarController ()
@property(nonatomic, readonly) NSToolbarItem* sidebarPaddingItem;
- (void) updateAlignment;
@end


@implementation GBToolbarController

@synthesize toolbar;
@synthesize window;
@synthesize sidebarWidth;
@dynamic sidebarPaddingItem;


- (void) dealloc
{
  if (toolbar.delegate == self) toolbar.delegate = nil;
  [toolbar release]; toolbar = nil;
  self.window = nil;
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


- (NSToolbarItem*) sidebarPaddingItem
{
  return [self toolbarItemForIdentifier:@"GBSidebarPadding"];
}



#pragma mark Helpers for subclasses



- (NSToolbarItem*) toolbarItemForIdentifier:(NSString*)itemIdentifier
{
  if (!itemIdentifier) return nil;
  
  for (NSToolbarItem* item in [self.toolbar items])
  {
    if ([[item itemIdentifier] isEqual:itemIdentifier])
    {
      return item;
    }
  }
  return nil;
}

- (void) appendItemWithIdentifier:(NSString*)itemIdentifier
{
  [self.toolbar insertItemWithItemIdentifier:itemIdentifier atIndex:[[self.toolbar items] count]];
}

- (NSInteger) indexOfItemWithIdentifier:(NSString*)itemIdentifier
{
  NSInteger itemIndex = -1;
  
  if (!itemIdentifier) return itemIndex;
  
  NSInteger c = [[self.toolbar items] count];
  for (NSInteger i = 0; i < c; i++)
  {
    if ([[[[self.toolbar items] objectAtIndex:i] itemIdentifier] isEqual:itemIdentifier])
    {
      itemIndex = i;
      break;
    }
  }
  
  return itemIndex;
}

- (void) removeItemWithIdentifier:(NSString*)itemIdentifier
{
  NSInteger itemIndex = [self indexOfItemWithIdentifier:itemIdentifier];
  if (itemIndex < 0) return;
  [self.toolbar removeItemAtIndex:itemIndex];
}

- (void) replaceItemWithIdentifier:(NSString*)itemIdentifier1 withItemWithIdentifier:(NSString*)itemIdentifier2
{
  NSInteger itemIndex = [self indexOfItemWithIdentifier:itemIdentifier1];
  if (itemIndex < 0) return;
  [self.toolbar insertItemWithItemIdentifier:itemIdentifier2 atIndex:itemIndex];
}

- (void) removeAdditionalItems
{
  NSInteger c = [[self.toolbar items] count];
  for (NSInteger i = 2; i < c; i++)
  {
    [self.toolbar removeItemAtIndex:2]; // 2 means we are removing the third item until there's no items left
  }
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
  [self removeAdditionalItems];
  [self updateAlignment];
}


- (void) updateAlignment
{
  static CGFloat spaceForMissingSettingsButton = 38.0; // remove this when settings button will come back
  CGFloat paddingOffset = -11.0 - 76.0 + spaceForMissingSettingsButton; // right spacing + "add" and "settings" buttons widths and their paddings
  
  NSToolbarItem* spaceItem = self.sidebarPaddingItem;
  
  NSSize size = [spaceItem minSize];
  size.width = self.sidebarWidth + paddingOffset;
  [spaceItem setMaxSize:size];
  [spaceItem setMinSize:size];
}


@end
