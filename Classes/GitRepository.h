
#import <Foundation/Foundation.h>

// ObjC interface to libgit2.

@interface GitRepository : NSObject
@property(nonatomic, retain) NSURL* URL;
+ (GitRepository*) repositoryWithURL:(NSURL*)url;
@end
