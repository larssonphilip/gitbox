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
@property(assign) BOOL shouldLogEvents;

- (void) start;
- (void) stop;

- (void) pause;
- (void) resume;

- (void) addPath:(NSString*)aPath withBlock:(OAFSEventStreamCallbackBlock)block;
- (void) removePath:(NSString*)aPath;

- (void) eventDidHappenWithPath:(NSString*)path id:(FSEventStreamEventId)eventId flags:(FSEventStreamEventFlags)eventFlags;

@end
