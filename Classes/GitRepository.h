
#import <Foundation/Foundation.h>

// ObjC interface to libgit2.
@class GitConfig;
@interface GitRepository : NSObject
@property(nonatomic, retain) NSURL* URL;
+ (GitRepository*) repositoryWithURL:(NSURL*)url;
- (GitConfig*) config;
- (NSString*) commitIdForRefName:(NSString*)refName;
@end
