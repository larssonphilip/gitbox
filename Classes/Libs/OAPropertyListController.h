
// This is a NSUserDefaults (almost) compatible class for writing and reading arbitrary plist.

@interface OAPropertyListController : NSObject
{
  BOOL isDirty;
  NSURL* plistURL;
  id plist;
}

@property(nonatomic, copy) NSURL* plistURL;
@property(nonatomic, strong) id plist;

- (id)objectForKey:(NSString*)name;
- (void)setObject:(id)value forKey:(NSString *)name;

- (void) synchronizeLater;
- (BOOL) synchronizeIfNeeded;
- (BOOL) synchronize;

@end
