@class GBToolbarController;
@class NSViewController;
@protocol GBMainWindowItem <NSObject>
- (NSString*) windowTitle;
- (NSURL*) windowRepresentedURL;
@optional
- (GBToolbarController*) toolbarController;
- (NSViewController*) viewController;
@end
