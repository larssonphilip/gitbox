#import <Foundation/Foundation.h>

@interface GitConfig : NSObject

- (id) initGlobalConfig;
- (id) initWithURL:(NSURL*)configURL;
- (id) initWithRepositoryURL:(NSURL*)repoURL;

- (void) close;

- (NSString*) stringForKey:(NSString*)key;
- (void) setString:(NSString*)string forKey:(NSString*)key;
- (void)enumerateKeysAndObjectsUsingBlock:(void (^)(id key, id obj, BOOL *stop))block;
@end
