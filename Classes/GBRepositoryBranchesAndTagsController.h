#import "GBRepositorySettingsViewController.h"

@interface GBRepositoryBranchesAndTagsController : GBRepositorySettingsViewController

@property(nonatomic, retain) NSArray* branchesBinding;
@property(nonatomic, retain) NSArray* tagsBinding;

- (IBAction) deleteBranch:(id)sender;
- (IBAction) deleteTag:(id)sender;

@end
