@interface GBRepositoriesGroup : NSObject
@property(nonatomic, copy) NSString* name;
@property(nonatomic, retain) NSArray* items;

- (NSString*) untitledGroupName;

@end
