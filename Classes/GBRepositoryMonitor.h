#import <Foundation/Foundation.h>

// TODO: move FS listening from GBFolderMonitor and make that class obsolete

//extern NSString* const GBRepositoryMonitorDidUpdateRefs

@class OAFSEventStream;
@interface GBRepositoryMonitor : NSObject

@property(nonatomic, copy, readonly) NSString* path;

- (id) initWithPath:(NSString*)path eventStream:(OAFSEventStream*)eventStream;

- (void) start;
- (void) stop;

- (void) setNeedsUpdateStage; // does not refresh refs
- (void) setNeedsUpdateRefs;  // refreshes both refs and stage

- (void) updateIfNeeded:(void(^)())completionBlock;

- (void) pauseDotGit;   // pauses notifications from /.git, should be balanced with resumeDotGit.
- (void) resumeDotGit;  // balances pauseDotGit

- (void) pauseWorkingDirectory;
- (void) resumeWorkingDirectory;

@end
