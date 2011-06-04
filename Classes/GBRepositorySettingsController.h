
#import "GBWindowControllerWithCallback.h"

@class GBRepository;

@interface GBRepositorySettingsController : GBWindowControllerWithCallback<NSWindowDelegate>

@property(nonatomic, retain) GBRepository* repository;
@property(nonatomic, retain) IBOutlet NSButton* cancelButton;
@property(nonatomic, retain) IBOutlet NSButton* saveButton;
@property(nonatomic, retain) IBOutlet NSTabView* tabView;

- (IBAction) cancel:(id)sender;
- (IBAction) save:(id)sender;

@end
