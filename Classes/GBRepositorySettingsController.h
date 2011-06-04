
#import "GBWindowControllerWithCallback.h"

@class GBRepository;
@class GBRepositorySettingsViewController;

@interface GBRepositorySettingsController : GBWindowControllerWithCallback<NSWindowDelegate>

@property(nonatomic, retain) GBRepository* repository;
@property(nonatomic, retain) IBOutlet NSButton* cancelButton;
@property(nonatomic, retain) IBOutlet NSButton* saveButton;
@property(nonatomic, retain) IBOutlet NSTabView* tabView;

- (IBAction) cancel:(id)sender;
- (IBAction) save:(id)sender;


// Protected

- (void) viewControllerDidChangeDirtyStatus:(GBRepositorySettingsViewController*)ctrl;

@end
