@class GBRepositoryController;
@interface GBBaseChangesController : NSViewController<NSTableViewDelegate, NSUserInterfaceValidations>

@property(retain) IBOutlet NSTableView* tableView;
@property(retain) IBOutlet NSArrayController* statusArrayController; 
@property(retain) GBRepositoryController* repositoryController;
@property(retain) NSArray* changes; // bound to statusArrayController

#pragma mark Interrogation

- (NSArray*) selectedChanges;
- (NSWindow*) window;


#pragma mark Update

- (void) update;


#pragma mark Actions

- (IBAction) stageShowDifference:_;
- (IBAction) stageRevealInFinder:_;

@end
