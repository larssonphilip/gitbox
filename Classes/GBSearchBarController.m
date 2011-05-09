#import "GBSearchBarController.h"
#import "NSObject+OASelectorNotifications.h"

//@interface GBSearchBarTextView : NSTextView
//@end
//@implementation GBSearchBarTextView
//- (IBAction) performFindPanelAction:(id)sender
//{
//  //  typedef enum {
//  //    NSFindPanelActionShowFindPanel = 1,
//  //    NSFindPanelActionNext = 2,
//  //    NSFindPanelActionPrevious = 3,
//  //    NSFindPanelActionReplaceAll = 4,
//  //    NSFindPanelActionReplace = 5,
//  //    NSFindPanelActionReplaceAndFind = 6,
//  //    NSFindPanelActionSetFindString = 7,
//  //    NSFindPanelActionReplaceAllInSelection = 8
//  //  } NSFindPanelAction;
//  
//  NSFindPanelAction action = [sender tag];
//  if (action == NSFindPanelActionShowFindPanel || 
//      action == NSFindPanelActionSetFindString)
//  {
//    [self selectAll:nil];
//  }
//}
//- (BOOL)tryToPerform:(SEL)anAction with:(id)anObject
//{
//  return [super tryToPerform:anAction with:anObject];
//}
//- (void)doCommandBySelector:(SEL)aSelector
//{
//  [super doCommandBySelector:aSelector];
//}
//@end


@interface GBSearchBarTextField ()
//@property(nonatomic,retain) GBSearchBarTextView* myTextView;
@end

@implementation GBSearchBarTextField : NSSearchField
//@synthesize myTextView;
//- (void) dealloc
//{
//  self.myTextView = nil;
//  [super dealloc];
//}
//- (NSText *)currentEditor
//{
//  NSText* text = [super currentEditor];
//  [text setNextResponder:self];
//  NSLog(@"GBSearchbArTextField currentEditor: responder chain for editor: %@", [text OAResponderChain]);
//  return text;
//}
//- (BOOL)acceptsFirstResponder
//{
//  return YES;
//}
@end


@interface GBSearchBarController () <NSTextFieldDelegate>
@end

@implementation GBSearchBarController

@synthesize visible;
@dynamic searchString;
@synthesize contentView;
@synthesize delegate;

@synthesize barView;
@synthesize searchField;
@synthesize progressIndicator;



#pragma mark Init



- (void) dealloc 
{
  self.barView = nil;
  self.contentView = nil;
  self.searchField = nil;
  self.progressIndicator = nil;
  [super dealloc];
}

- (void) awakeFromNib
{
  [super awakeFromNib];
  
  if (!self.barView)
  {
    NSNib* privateNib = [[[NSNib alloc] initWithNibNamed:@"GBSearchBarController" bundle:[NSBundle mainBundle]] autorelease];
    [privateNib instantiateNibWithOwner:self topLevelObjects:NULL];
    
    [self.barView setFrame:[self.view bounds]];
    [self.view addSubview:self.barView];
    
    [self.searchField setRefusesFirstResponder:YES];
  }
}



#pragma mark Events




- (IBAction)searchFieldDidChange:(id)sender;
{
  self.searchString = [self.searchField stringValue];
  [self notifyWithSelector:@selector(searchBarControllerDidChangeString:)];
}

// handling of ESC key
- (BOOL) control:(NSControl*)control textView:(NSTextView*)textView doCommandBySelector:(SEL)commandSelector
{
  if (control == searchField && commandSelector == @selector(cancelOperation:))
  {
    [self notifyWithSelector:@selector(searchBarControllerDidCancel:)];
    return YES;
  }
  // when Cmd+F is pressed, should select all text.
  if (control == searchField && commandSelector == @selector(performFindPanelAction:))
  {
    [self.searchField selectText:nil];
    return YES;
  }
  return NO;
}



#pragma mark Appearance


- (void) focus
{
  [self.searchField setRefusesFirstResponder:NO];
  [self.view.window makeFirstResponder:self.searchField];
  [self.searchField selectText:nil];
}

- (void) unfocus
{
  [self.view.window makeFirstResponder:self.contentView];
}


- (NSString*) searchString
{
  return [self.searchField stringValue];
}

- (void) setSearchString:(NSString*)str
{
  [self.searchField setStringValue:str];
}

- (void) setVisible:(BOOL)newVisible
{
  [self setVisible:newVisible animated:NO];
}

- (void) setVisible:(BOOL)newVisible animated:(BOOL)animated
{
  if (newVisible == visible) return;
  
  visible = newVisible;
  
  [self.searchField setRefusesFirstResponder:!visible];
  
  if (animated)
  {
    if (visible)
    {
      [self focus];
    }
    else
    {
      [self unfocus];
    }
  }
  
  CGFloat searchBarHeight = self.view.frame.size.height;
  
  // move off-screen
  NSPoint newOrigin = self.view.frame.origin;
  if (visible)  newOrigin.y = [self.view superview].frame.size.height;
  [self.view setFrameOrigin:newOrigin];
  [self.view setHidden:NO];
  
  newOrigin.y -= visible ? searchBarHeight : -searchBarHeight;
  
  
  NSSize newSize = self.contentView.frame.size;
  newSize.height -= visible ? searchBarHeight : -searchBarHeight;
  
  if (animated)
  {
    // slide down or up
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration: 0.1];
    [[self.view animator] setFrameOrigin:newOrigin];
    // shrink or grow the contentView
    [[self.contentView animator] setFrameSize:newSize];
    [NSAnimationContext endGrouping];
  }
  else
  {
    [self.view setFrameOrigin:newOrigin];
    [self.contentView setFrameSize:newSize];
  }

}

- (void) setSpinnerAnimated:(BOOL)animated;
{
  // TODO: find if this is needed
  if ([[searchField stringValue] length] == 0)  return;
  
  if (animated)
  {
    [searchField.cell setCancelButtonCell:nil];
    [progressIndicator startAnimation:self];
  }
  else
  {
    [searchField.cell resetCancelButtonCell];
    [progressIndicator stopAnimation:self];
  }
}


@end
