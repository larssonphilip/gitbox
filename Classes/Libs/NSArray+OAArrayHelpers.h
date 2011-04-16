// Used in projects (time revisited):
// - oleganza/gitbox (22.05.2010)

@interface NSArray (OAArrayHelpers)

- (id) firstObject;
- (NSArray*) reversedArray;
- (id) objectAtIndex:(NSUInteger)index or:(id)defaultObject;
- (BOOL) anyIsTrue:(SEL)selector;
- (BOOL) allAreTrue:(SEL)selector;
- (id) objectWithValue:(id)value forKey:(NSString*)key;
- (id) objectWithValue:(id)value forKeyPath:(NSString*)keyPath;
- (NSArray*) mapWithBlock:(id(^)(id))mapBlock;

// Example for size=2: [] => [], [1] => [[1]], [1,2,3,4,5] => [[1,2], [3,4], [5]]
- (NSArray*) arrayOfChunksBySize:(NSUInteger)chunkSize;

@end

@interface NSMutableArray (OAArrayHelpers)
- (NSMutableArray*) reverse;
@end