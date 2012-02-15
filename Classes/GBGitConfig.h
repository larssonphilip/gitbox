@class GBRepository;
@interface GBGitConfig : NSObject

@property(nonatomic, assign) GBRepository* repository;

// Returns singleton instance for ~/.gitconfig
+ (GBGitConfig*) userConfig;

// Returns managing instance for <repo>/.git/config
+ (GBGitConfig*) configForRepository:(GBRepository*)repo;

- (BOOL) isUserConfig;


// Sync API

- (NSString*) stringForKey:(NSString*)key;
- (void) setString:(NSString*)value forKey:(NSString*)key;

- (NSString*) userName;
- (NSString*) userEmail;


// Async API

- (void) stringForKey:(NSString*)key withBlock:(void(^)(NSString* value))aBlock;
- (void) setString:(NSString*)value forKey:(NSString*)key withBlock:(void(^)())aBlock;
- (void) removeKey:(NSString*)key;

- (void) ensureDisabledPathQuoting:(void(^)())aBlock;
- (void) setName:(NSString*)name email:(NSString*)email withBlock:(void(^)())block;


@end
