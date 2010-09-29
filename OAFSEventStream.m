#import "OAFSEventStream.h"


void OAFSEventStreamCallback( ConstFSEventStreamRef streamRef,
                             void* info,
                             size_t numEvents,
                             void* eventPaths,
                             const FSEventStreamEventFlags eventFlags[],
                             const FSEventStreamEventId eventIds[])
{
  OAFSEventStream* stream = (OAFSEventStream*)info;
  int i;
  char **paths = eventPaths;
  
  for (i=0; i<numEvents; i++)
  {
    /* flags are unsigned long, IDs are uint64_t */
    NSLog(@"Change %llu in %s, flags %lu\n", eventIds[i], paths[i], eventFlags[i]);
  }
}


@implementation OAFSEventStream
@synthesize blocksByPaths;
@synthesize delegate;

- (void) dealloc
{
  self.blocksByPaths = nil;
  [super dealloc];
}

- (NSMutableDictionary*) blocksByPaths
{
  if (!blocksByPaths)
  {
    self.blocksByPaths = [NSMutableDictionary dictionary];
  }
  return blocksByPaths;
}

- (void) addPath:(NSString*)aPath withBlock:(void(^)())block
{
  [self.blocksByPaths setObject:block forKey:aPath];
  
}

- (void) removePath:(NSString*)aPath
{
  [self.blocksByPaths removeObjectForKey:aPath];
}

- (void) start
{
  CFArrayRef pathsToWatch = (CFArrayRef)[self.blocksByPaths allKeys];
  
  streamContext.version = 0;
  streamContext.info = (void*)self;
  streamContext.retain = NULL;
  streamContext.release = NULL;
  streamContext.copyDescription = NULL;
  
  CFAbsoluteTime latency = 1.0; /* seconds */
  
  /* Create the stream, passing in a callback */
  streamRef = FSEventStreamCreate(NULL,
                               OAFSEventStreamCallback,
                               &streamContext,
                               pathsToWatch,
                               kFSEventStreamEventIdSinceNow, /* Or a previous event ID */
                               latency,
                               kFSEventStreamCreateFlagIgnoreSelf
                               );
  FSEventStreamScheduleWithRunLoop(streamRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
  FSEventStreamStart(streamRef);
}

- (void) stop
{
  FSEventStreamUnscheduleFromRunLoop(streamRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
  FSEventStreamStop(streamRef);
  FSEventStreamRelease(streamRef);
}

- (void) pause
{
  paused++;
  if (paused == 1) FSEventStreamStop(streamRef);
}

- (void) resume
{
  paused--;
  if (paused == 0) FSEventStreamStart(streamRef);
}




@end
