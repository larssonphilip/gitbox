/*
 
 Usage: add a block with addBlock and always balance it with endBlock:
 
  [queue addBlock:^{

    ...
    [queue endBlock];

  }];
*/

@interface OABlockQueue : NSObject

@property(nonatomic) NSInteger maxConcurrentOperationCount; // 1 by default
@property(nonatomic) NSInteger operationCount;
@property(nonatomic, retain) NSMutableArray* queue;

- (void) addBlock:(void(^)())aBlock;
- (void) endBlock;

@end
