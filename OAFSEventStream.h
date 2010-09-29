#include <CoreServices/CoreServices.h>

@protocol OAFSEventStreamDelegate<NSObject>
@end


@interface OAFSEventStream : NSObject
{
  NSInteger paused;
  FSEventStreamRef streamRef;
  FSEventStreamContext streamContext;
}

@property(nonatomic,retain) NSMutableDictionary* blocksByPaths;
@property(assign) id<OAFSEventStreamDelegate> delegate;

- (void) start;
- (void) stop;

- (void) pause;
- (void) resume;

- (void) addPath:(NSString*)aPath withBlock:(void(^)())block;
- (void) removePath:(NSString*)aPath;

@end
