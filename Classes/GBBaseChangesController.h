@class GBRepositoryController;
@interface GBBaseChangesController : NSViewController<NSTableViewDelegate, NSUserInterfaceValidations>

@property(nonatomic, retain) IBOutlet NSTableView* tableView;
@property(nonatomic, retain) IBOutlet NSArrayController* statusArrayController; 
@property(nonatomic, retain) IBOutlet NSView* headerView; 
@property(nonatomic, retain) GBRepositoryController* repositoryController;
@property(nonatomic, retain) NSArray* changes;
@property(nonatomic, retain) NSArray* changesWithHeaderForBindings; // bound to statusArrayController

#pragma mark Interrogation

- (NSArray*) selectedChanges;
- (NSWindow*) window;
- (NSCell*) headerCell;
- (CGFloat) headerHeight;
- (NSIndexSet*) changesIndexesForTableIndexes:(NSIndexSet*)indexSet;


#pragma mark Update

- (void) update;


#pragma mark Actions

- (IBAction) selectFirstLineIfNeeded:_;
- (IBAction) stageShowDifference:_;
- (IBAction) stageRevealInFinder:_;
- (IBAction) selectLeftPane:_;
- (BOOL) validateSelectLeftPane:_;
@end
