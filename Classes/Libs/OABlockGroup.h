@interface OABlockGroup : NSObject

+ (void) groupBlock:(void(^)(OABlockGroup*))groupBlock continuation:(void(^)())continuationBlock;

- (void) enter;
- (void) leave;

@end
