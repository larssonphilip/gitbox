#include "GBHistoryViewController.h"

@class GBSearchBarView;

@interface GBSearchBarController : NSViewController {
	IBOutlet NSSearchField *searchField;
  IBOutlet NSProgressIndicator *progressIndicator;
  BOOL alreadyVisible;
}

@property(retain) NSView* parentView;
@property(retain) NSView* siblingView;
@property(retain) GBHistoryViewController* historyController;

- (IBAction) updateFilter:sender;
- (BOOL) control:(NSControl*)control textView:(NSTextView*)textView doCommandBySelector:(SEL)commandSelector;

- (void) loadView;
- (void) dealloc;

- (void) setViewVisible:(BOOL)visible;
- (void) setSpinnerAnimated:(BOOL)visible;

@end
