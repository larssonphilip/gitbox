#import "OAFSEventStream.h"

NSString* const OAFSEventStreamNotification = @"OAFSEventStreamNotification";

@interface OAFSEventStream ()
@property(nonatomic, retain) NSCountedSet* pathsBag;
@property(nonatomic, assign) BOOL started;
@property(nonatomic, assign) FSEventStreamRef streamRef;
- (void) update;
- (void) start;
- (void) stop;
@end

@implementation OAFSEventStream

@synthesize streamRef;
@synthesize dispatchQueue;
@synthesize latency;
@synthesize watchRoot;
@synthesize ignoreSelf;
@synthesize pathsBag;
@synthesize started;
@synthesize enabled;
@dynamic paths;

- (void)dealloc
{
  [self stop];
  if (dispatchQueue) dispatch_release(dispatchQueue);
  [pathsBag release]; pathsBag = nil;
  [super dealloc];
}


- (id)init
{
  if ((self = [super init]))
  {
    self.pathsBag = [NSCountedSet set];
    self.latency = 0.1;
  }
  return self;
}

- (NSArray*) paths
{
  return [[self.pathsBag allObjects] sortedArrayUsingSelector:@selector(self)];
}

- (void) addPath:(NSString*)aPath
{
  [self.pathsBag addObject:aPath];
  [self update];
}

- (void) removePath:(NSString*)aPath
{
  [self.pathsBag removeObject:aPath];
  [self update];
}

- (void) setEnabled:(BOOL)flag
{
  if (enabled == flag) return;
  enabled = flag;
  [self update];
}

- (void) flushEvents
{
  if (streamRef) FSEventStreamFlushSync(streamRef);
}



#pragma mark Private


- (void) update
{
  if ([self isEnabled])
  {
    [self stop];
    [self start];
  }
  else
  {
    [self stop];
  }
}

- (void) start
{
  if (!self.pathsBag) self.pathsBag = [NSCountedSet set];
  CFArrayRef pathsToWatch = (CFArrayRef)[self.pathsBag allObjects];
//  
//  streamContext.version = 0;
//  streamContext.info = (void*)self;
//  streamContext.retain = NULL;
//  streamContext.release = NULL;
//  streamContext.copyDescription = NULL;
//  
//  CFAbsoluteTime latency = 0.9999; /* seconds */
//  
//  /* Create the stream, passing in a callback */
//  streamRef = FSEventStreamCreate(NULL,
//                                  OAFSEventStreamCallback,
//                                  &streamContext,
//                                  pathsToWatch,
//                                  kFSEventStreamEventIdSinceNow, /* Or a previous event ID */
//                                  latency,
//                                  kFSEventStreamCreateFlagUseCFTypes|
//                                  //kFSEventStreamCreateFlagNoDefer|  // (looks like this flag does not change the behaviour...)
//                                  // kFSEventStreamCreateFlagIgnoreSelf| <- since we are shelling out anyway and have a custom mechanism to handle self updates, we should listen for ours updates here by default.
//                                  kFSEventStreamCreateFlagWatchRoot
//                                  );
//  FSEventStreamScheduleWithRunLoop(streamRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
//  FSEventStreamStart(streamRef);
}

- (void) stop
{
  if (streamRef)
  {
    FSEventStreamStop(streamRef);
    FSEventStreamInvalidate(streamRef);
    FSEventStreamRelease(streamRef);
    streamRef = NULL;
  }
}

@end
