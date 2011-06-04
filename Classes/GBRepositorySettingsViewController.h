
@class GBRepository;
@class GBRepositorySettingsController;
@interface GBRepositorySettingsViewController : NSViewController

@property(nonatomic, assign) GBRepositorySettingsController* settingsController;
@property(nonatomic, retain) GBRepository* repository;
@property(nonatomic, copy) NSString* title;
@property(nonatomic, assign, getter=isDirty) BOOL dirty;

- (id)initWithRepository:(GBRepository*)repo;

- (void) viewDidLoad;
- (void) cancel;
- (void) save;

@end
