#import "GBRepositorySettingsViewController.h"

@interface GBRepositoryRemotesController : GBRepositorySettingsViewController
@property(nonatomic,retain) NSMutableArray* remotesDictionaries;
@end

@interface GBRepositoryRemotesArrayController : NSArrayController
@property(nonatomic, assign) IBOutlet GBRepositoryRemotesController* remotesController;
@end