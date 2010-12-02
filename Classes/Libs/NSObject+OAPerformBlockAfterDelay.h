
@interface NSObject (OAPerformBlockAfterDelay)

+ (id) performBlock:(void(^)())aBlock afterDelay:(NSTimeInterval)seconds;
+ (void) cancelPreviousPerformBlock:(id)aWrappingBlockHandle;

@end
