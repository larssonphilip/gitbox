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


@end

@interface NSMutableArray (OAArrayHelpers)
- (NSMutableArray*) reverse;
@end