// This is a base utility class for GBStageViewController and GBCommitViewController.
// It should not be visible to any other class in the app.

#import <Quartz/Quartz.h>
#import <QuickLook/QuickLook.h>
#import "GBChangeDelegate.h"

@class GBRepositoryController;
@class GBCommit;
@interface GBBaseChangesController : NSViewController<NSTableViewDelegate, NSUserInterfaceValidations, QLPreviewPanelDataSource, QLPreviewPanelDelegate, GBChangeDelegate>

// Public API

@property(nonatomic, unsafe_unretained) GBRepositoryController* repositoryController;
@property(nonatomic, strong) GBCommit* commit;


// NIB API

@property(nonatomic, strong) IBOutlet NSTableView* tableView;
@property(nonatomic, strong) IBOutlet NSArrayController* statusArrayController;
@property(nonatomic, strong) IBOutlet NSView* headerView;
@property(nonatomic, strong) NSArray* changesWithHeaderForBindings; // bound to statusArrayController


// Subclass API

@property(nonatomic, strong) NSArray* changes;

- (NSArray*) selectedChanges;
- (NSCell*) headerCell;
- (CGFloat) headerHeight;

- (IBAction) selectFirstLineIfNeeded:(id)sender;
- (IBAction) showFileHistory:_;
- (IBAction) stageShowDifference:_;
- (IBAction) stageRevealInFinder:_;
- (IBAction) selectLeftPane:(id)sender;
- (BOOL) validateSelectLeftPane:(id)sender;

@end
