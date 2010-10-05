#include <CoreServices/CoreServices.h>

typedef void (^OAFSEventStreamCallbackBlock)(NSString*);

@interface OAFSEventStream : NSObject
{
  NSInteger paused;
  FSEventStreamRef streamRef;
  FSEventStreamContext streamContext;
  BOOL shouldLogEvents;
}

@property(nonatomic,retain) NSMutableDictionary* blocksByPaths;
@property(nonatomic,retain) NSMutableDictionary* coalescedPathsByPaths;
@property(assign) BOOL shouldLogEvents;

- (void) start;
- (void) stop;

- (void) pushPause;
- (void) popPause;

- (void) pushPauseForPath:(NSString*)aPath;
- (void) popPauseForPath:(NSString*)aPath;

- (void) addPath:(NSString*)aPath withBlock:(OAFSEventStreamCallbackBlock)block;
- (void) removePath:(NSString*)aPath;

- (void) eventDidHappenWithPath:(NSString*)path id:(FSEventStreamEventId)eventId flags:(FSEventStreamEventFlags)eventFlags;

@end
