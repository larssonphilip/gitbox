@class GBSearchBarController;

@protocol GBSearchBarControllerDelegate<NSObject>
@optional
- (void) searchBarControllerDidChangeString:(GBSearchBarController*)ctrl;
- (void) searchBarControllerDidCancel:(GBSearchBarController*)ctrl;
@end

@interface GBSearchBarTextField : NSSearchField
@end

@interface GBSearchBarController : NSViewController

@property(nonatomic, copy)   NSString* searchString;
@property(nonatomic, assign) BOOL visible;
@property(nonatomic, retain) IBOutlet NSView* contentView; // this outlet should be connected in the parent NIB
@property(nonatomic, assign) IBOutlet id<GBSearchBarControllerDelegate> delegate;

- (void) setVisible:(BOOL)visible animated:(BOOL)animated;
- (IBAction) searchFieldDidChange:(id)sender;
- (void) setSpinnerAnimated:(BOOL)visible;

- (void) focus;
- (void) unfocus;

// Private outlets for GBSearchBarController NIB.
@property(nonatomic, retain) IBOutlet NSView* barView;
@property(nonatomic, retain) IBOutlet GBSearchBarTextField *searchField;
@property(nonatomic, retain) IBOutlet NSProgressIndicator *progressIndicator;

@end
