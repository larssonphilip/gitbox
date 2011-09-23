#import <Foundation/Foundation.h>

@interface GitConfig : NSObject

- (id) initWithRepositoryURL:(NSURL*)repoURL;
- (id) initGlobalConfig;
- (void) close;

@end
