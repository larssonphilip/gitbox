@interface GBRepositorySettingsViewController : NSViewController
@property(nonatomic, copy) NSString* title;

- (void) userDidCancel;
- (void) userDidSave;

@end
