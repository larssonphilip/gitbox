/*
 
 Usage: add a block with addBlock and always balance it with endBlock:
 
  [queue addBlock:^{

    ...
    [queue endBlock];

  }];
*/

@interface OABlockQueue : NSObject

@property(nonatomic, copy) NSString* name;
@property(nonatomic, strong) NSMutableArray* queue;

@property(nonatomic, assign) NSInteger maxConcurrentOperationCount; // 1 by default
@property(nonatomic, assign) NSInteger operationCount;

+ (OABlockQueue*) queueWithName:(NSString*)aName concurrency:(NSInteger)maxConcurrentOps;

- (void) addBlock:(void(^)())aBlock;
- (void) prependBlock:(void(^)())aBlock;
- (void) endBlock;

@end
