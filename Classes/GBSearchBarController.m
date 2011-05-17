#import "GBSearchBarController.h"
#import "NSObject+OASelectorNotifications.h"

@interface GBSearchBarController () <NSTextFieldDelegate>
- (void) updateStatusLabel;
@end

@implementation GBSearchBarController

@synthesize visible;
@synthesize spinning;
@synthesize progress;
@dynamic searchString;
@synthesize contentView;
@synthesize delegate;
@synthesize resultsCount;

@synthesize barView;
@synthesize searchField;
@synthesize progressIndicator;
@synthesize statusLabel;


#pragma mark Init



- (void) dealloc 
{
  self.barView = nil;
  self.contentView = nil;
  self.searchField = nil;
  self.progressIndicator = nil;
  self.statusLabel = nil;
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
    [self updateStatusLabel];
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
  if (!self.searchField) return;
  [self.searchField setRefusesFirstResponder:NO];
  [self.view.window makeFirstResponder:self.searchField];
  [self.searchField selectText:nil];
}

- (void) unfocus
{
  if (!self.searchField) return;
  [self.view.window makeFirstResponder:self.contentView];
}


- (NSString*) searchString
{
  return [self.searchField stringValue];
}

- (void) setSearchString:(NSString*)str
{
  [self.searchField setStringValue:str];
  if ([str length] < 1)
  {
    [self setSpinning:NO];
  }
  [self updateStatusLabel];
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

  [self updateStatusLabel];
}

- (void) setSpinning:(BOOL)flag
{
  spinning = flag;
  
  if (flag)
  {
    [self.searchField.cell setCancelButtonCell:nil];
    [self.progressIndicator startAnimation:self];
  }
  else
  {
    [self.searchField.cell resetCancelButtonCell];
    [self.progressIndicator stopAnimation:self];
  }
  
  [self updateStatusLabel];
}


- (void) updateStatusLabel
{
  if (self.resultsCount < 1)
  {
    if (spinning)
    {
      [self.statusLabel setStringValue:NSLocalizedString(@"Searching in history...", @"")];
    }
    else
    {
      [self.statusLabel setStringValue:NSLocalizedString(@"No results", @"")];
    }
  }
  else
  {
    [self.statusLabel setStringValue:[NSString stringWithFormat:(self.resultsCount == 1) ? NSLocalizedString(@"Found %d commit%@", nil) : NSLocalizedString(@"Found %d commits%@", nil), spinning ? @"..." : @""]];
  }
}

@end
