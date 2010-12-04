// You have master-detail UI and you want to jump between items quickly.
// This controller implements a smart logic to achieve a good performance by delaying updates.
// It also avoids delay if you are not switching too fast.

@interface OAFastJumpController : NSObject

+ (id) controller;
- (void) delayBlockIfNeeded:(void(^)())aBlock;
- (void) cancel; // discard delayed block and reset state
- (void) flush; // call delayed block and reset state
@end
