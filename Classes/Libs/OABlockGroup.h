@interface OABlockGroup : NSObject
{
  int counter;
}

@property(nonatomic, copy) void(^block)();

+ (OABlockGroup*) groupWithBlock:(void(^)())block;

- (void) enter;
- (void) leave;
- (void) verify;

@end
