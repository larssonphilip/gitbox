// Updates system activity indicator on iPhone and internal property which can be bound to NSProgressIndicator "animate" binding.

// Used in projects (time revisited):
// - oleganza/gitbox (22.05.2010)
// - patryst/iphone (22.05.2010)
// - cde/iphone (21.05.2010)
// - facilescan/iphone (21.05.2010)

@interface OAActivityIndicator : NSObject
{
  NSInteger count;
  BOOL value;
}

// Bind NSProgressIndicator "animate" to "value"
@property(nonatomic,assign) BOOL value;


// Methods for shared instance (useful for a single-window applications such as iPhone app)
+ (OAActivityIndicator*)sharedIndicator;
+ (void) push;
+ (void) pop;
+ (BOOL) isActive;

- (void) push;
- (void) pop;
- (BOOL) isActive;

@end
