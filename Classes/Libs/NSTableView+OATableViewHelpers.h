
@interface NSTableView (OATableViewHelpers)

- (void) withDelegate:(id<NSTableViewDelegate>)aDelegate doBlock:(void(^)())block;

@end
