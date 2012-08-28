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
@property(nonatomic, assign) BOOL spinning;
@property(nonatomic, assign) double progress;
@property(nonatomic, assign) NSUInteger resultsCount;
@property(nonatomic, strong) IBOutlet NSView* contentView; // this outlet should be connected in the parent NIB
@property(nonatomic, weak) IBOutlet id<GBSearchBarControllerDelegate> delegate;
@property(nonatomic, weak) IBOutlet NSTextField* statusLabel;

- (void) setVisible:(BOOL)visible animated:(BOOL)animated;
- (IBAction) searchFieldDidChange:(id)sender;

- (void) focus;
- (void) unfocus;

// Private outlets for GBSearchBarController NIB.
@property(nonatomic, strong) IBOutlet NSView* barView;
@property(nonatomic, strong) IBOutlet GBSearchBarTextField *searchField;
@property(nonatomic, strong) IBOutlet NSProgressIndicator *progressIndicator;

@end
