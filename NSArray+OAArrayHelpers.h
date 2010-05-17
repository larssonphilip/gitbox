@interface NSArray (OAArrayHelpers)

- (id) firstObject;
- (NSArray*) reversedArray;
- (id) objectAtIndex:(NSUInteger)index or:(id)defaultObject;

@end

@interface NSMutableArray (OAArrayHelpers)
- (NSMutableArray*) reverse;
@end