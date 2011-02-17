@class GBToolbarController;
@class NSViewController;
@protocol GBMainWindowItem <NSObject>
@optional
- (GBToolbarController*) toolbarController;
- (NSViewController*) viewController;
@end
