@class GBToolbarController;
@class NSViewController;
@protocol GBMainWindowItem <NSObject>
@optional
@property(nonatomic, retain) NSWindow* window;
- (NSString*) windowTitle;
- (NSURL*) windowRepresentedURL;
- (GBToolbarController*) toolbarController;
- (NSViewController*) viewController;
- (void) willDeselectWindowItem;
- (void) didSelectWindowItem;
@end
