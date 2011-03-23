// This is a base utility class for GBStageViewController and GBCommitViewController.
// It should not be visible to any other class in the app.

#import <Quartz/Quartz.h>
#import <QuickLook/QuickLook.h>

@class GBRepositoryController;
@class GBCommit;
@interface GBBaseChangesController : NSViewController<NSTableViewDelegate, NSUserInterfaceValidations, QLPreviewPanelDataSource, QLPreviewPanelDelegate>

// Public API

@property(nonatomic, assign) GBRepositoryController* repositoryController;
@property(nonatomic, retain) GBCommit* commit;


// NIB API

@property(nonatomic, retain) IBOutlet NSTableView* tableView;
@property(nonatomic, retain) IBOutlet NSArrayController* statusArrayController;
@property(nonatomic, retain) IBOutlet NSView* headerView;
@property(nonatomic, retain) NSArray* changesWithHeaderForBindings; // bound to statusArrayController


// Subclass API

@property(nonatomic, retain) NSArray* changes;

- (NSArray*) selectedChanges;
- (NSCell*) headerCell;
- (CGFloat) headerHeight;

- (IBAction) selectFirstLineIfNeeded:(id)sender;
- (IBAction) stageShowDifference:_;
- (IBAction) stageRevealInFinder:_;
- (IBAction) selectLeftPane:(id)sender;
- (BOOL) validateSelectLeftPane:(id)sender;

@end
