@class GBRepositoryController;
@interface GBBaseChangesController : NSViewController<NSTableViewDelegate, NSUserInterfaceValidations>

@property(retain) IBOutlet NSTableView* tableView;
@property(retain) IBOutlet NSArrayController* statusArrayController; 
@property(retain) IBOutlet NSView* headerView; 
@property(retain) GBRepositoryController* repositoryController;
@property(retain) NSArray* changes;
@property(retain) NSArray* changesWithHeaderForBindings; // bound to statusArrayController

#pragma mark Interrogation

- (NSArray*) selectedChanges;
- (NSWindow*) window;
- (NSCell*) headerCell;
- (CGFloat) headerHeight;


#pragma mark Update

- (void) update;


#pragma mark Actions

- (IBAction) selectFirstLineIfNeeded:_;
- (IBAction) stageShowDifference:_;
- (IBAction) stageRevealInFinder:_;
- (IBAction) selectLeftPane:_;
- (BOOL) validateSelectLeftPane:_;
@end
