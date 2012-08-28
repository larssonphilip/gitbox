#import "GBRepositorySettingsViewController.h"

@interface GBRepositoryBranchesAndTagsController : GBRepositorySettingsViewController

@property(nonatomic, strong) NSMutableArray* branchesBinding;
@property(nonatomic, strong) NSMutableArray* tagsBinding;
@property(nonatomic, strong) NSMutableArray* remoteBranchesBinding;

@property(nonatomic, strong) IBOutlet NSArrayController* branchesController;
@property(nonatomic, strong) IBOutlet NSArrayController* tagsController;
@property(nonatomic, strong) IBOutlet NSArrayController* remoteBranchesController;

@property(nonatomic, strong) IBOutlet NSButton* deleteBranchButton;
@property(nonatomic, strong) IBOutlet NSButton* deleteTagButton;
@property(nonatomic, strong) IBOutlet NSButton* deleteRemoteBranchButton;

- (IBAction) deleteBranch:(id)sender;
- (IBAction) deleteTag:(id)sender;
- (IBAction) deleteRemoteBranch:(id)sender;

@end
