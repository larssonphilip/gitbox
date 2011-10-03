@class GBChange;
@protocol GBChangeDelegate<NSObject>
- (void) stageChange:(GBChange*)aChange;
- (void) unstageChange:(GBChange*)aChange;
- (void) doubleClickChange:(GBChange*)aChange;
@end
