#import "GBRepositorySettingsViewController.h"

@interface GBRepositoryBranchesAndTagsController : GBRepositorySettingsViewController

@property(nonatomic, retain) NSMutableArray* branchesBinding;
@property(nonatomic, retain) NSMutableArray* tagsBinding;
@property(nonatomic, retain) NSMutableArray* remoteBranchesBinding;

@property(nonatomic, retain) IBOutlet NSArrayController* branchesController;
@property(nonatomic, retain) IBOutlet NSArrayController* tagsController;
@property(nonatomic, retain) IBOutlet NSArrayController* remoteBranchesController;

@property(nonatomic, retain) IBOutlet NSButton* deleteBranchButton;
@property(nonatomic, retain) IBOutlet NSButton* deleteTagButton;
@property(nonatomic, retain) IBOutlet NSButton* deleteRemoteBranchButton;

- (IBAction) deleteBranch:(id)sender;
- (IBAction) deleteTag:(id)sender;
- (IBAction) deleteRemoteBranch:(id)sender;

@end
