#import "OAFSEventStream.h"
#import "NSString+OAStringHelpers.h"

void OAFSEventStreamCallback( ConstFSEventStreamRef streamRef,
                             void* info,
                             size_t numEvents,
                             void* eventPaths, // assuming CFArray/NSArray because of kFSEventStreamCreateFlagUseCFTypes
                             const FSEventStreamEventFlags eventFlags[],
                             const FSEventStreamEventId eventIds[])
{
  OAFSEventStream* stream = (OAFSEventStream*)info;  
  for (NSUInteger index = 0; index < numEvents; index++)
  {
    NSString* eventPath = [[(NSArray*)eventPaths objectAtIndex:index] stringByStandardizingPath];
    [stream eventDidHappenWithPath:eventPath id:eventIds[index] flags:eventFlags[index]];
  }
}


@implementation OAFSEventStream
@synthesize blocksByPaths;
@synthesize coalescedPathsByPaths;
@synthesize shouldLogEvents;

- (void) dealloc
{
  self.blocksByPaths = nil;
  self.coalescedPathsByPaths = nil;
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

- (NSMutableDictionary*) coalescedPathsByPaths
{
  if (!coalescedPathsByPaths)
  {
    self.coalescedPathsByPaths = [NSMutableDictionary dictionary];
  }
  return coalescedPathsByPaths;
}

- (void) addPath:(NSString*)aPath withBlock:(OAFSEventStreamCallbackBlock)block
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
  
  CFAbsoluteTime latency = 0.2; /* seconds */
  
  /* Create the stream, passing in a callback */
  streamRef = FSEventStreamCreate(NULL,
                               OAFSEventStreamCallback,
                               &streamContext,
                               pathsToWatch,
                               kFSEventStreamEventIdSinceNow, /* Or a previous event ID */
                               latency,
                                 kFSEventStreamCreateFlagUseCFTypes|
                                 kFSEventStreamCreateFlagIgnoreSelf|
                                 kFSEventStreamCreateFlagWatchRoot
                               );
  FSEventStreamScheduleWithRunLoop(streamRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
  FSEventStreamStart(streamRef);
  
//  kFSEventStreamCreateFlagWatchRoot
//      Request notifications of changes along the path to the path(s) you're watching. 
//      For example, with this flag, if you watch "/foo/bar" and it is renamed to "/foo/bar.old", 
//      you would receive a RootChanged event. The same is true if the directory "/foo" were renamed. 
//      The event you receive is a special event: the path for the event is the original path you specified,
//      the flag kFSEventStreamEventFlagRootChanged is set and event ID is zero. 
//      RootChanged events are useful to indicate that you should rescan a particular hierarchy 
//      because it changed completely (as opposed to the things inside of it changing). 
//      If you want to track the current location of a directory, 
//      it is best to open the directory before creating the stream so that 
//      you have a file descriptor for it and can issue an F_GETPATH fcntl() to find the current path.
}

- (void) stop
{
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
  self.coalescedPathsByPaths = nil;
  FSEventStreamUnscheduleFromRunLoop(streamRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
  FSEventStreamStop(streamRef);
  FSEventStreamRelease(streamRef);
}

- (void) pushPause
{
  paused++;
  if (paused == 1)
  {
    
    FSEventStreamStop(streamRef);
  }
}

- (void) popPause
{
  paused--;
  if (paused == 0)
  {
    
    FSEventStreamStart(streamRef);
  }
}

- (void) delayCallbackForPath:(NSString*)watchedPath
{
  //NSLog(@"!! %@", watchedPath);
  [NSObject cancelPreviousPerformRequestsWithTarget:self
                                           selector:@selector(delayedCallbackForPath:)
                                             object:watchedPath];
  [self performSelector:@selector(delayedCallbackForPath:)
             withObject:watchedPath
             afterDelay:0.3];
}

- (void) delayedCallbackForPath:(NSString*)watchedPath
{
  //NSLog(@".. %@", watchedPath);
  OAFSEventStreamCallbackBlock block = [self.blocksByPaths objectForKey:watchedPath];
  NSString* changedPath = [self.coalescedPathsByPaths objectForKey:watchedPath];
  if (block && changedPath && !paused) block(changedPath);
  [self.coalescedPathsByPaths removeObjectForKey:watchedPath];
}

- (void) eventDidHappenWithPath:(NSString*)path id:(FSEventStreamEventId)eventId flags:(FSEventStreamEventFlags)eventFlags
{
  if (shouldLogEvents)
  {
    NSMutableArray* flags = [NSMutableArray array];
    if (eventFlags == kFSEventStreamEventFlagNone)
    {
      [flags addObject: @"None"];
    }
    else
    {
      if (eventFlags & kFSEventStreamEventFlagMustScanSubDirs) [flags addObject: @"MustScanSubDirs"];
      if (eventFlags & kFSEventStreamEventFlagUserDropped)     [flags addObject: @"UserDropped"];
      if (eventFlags & kFSEventStreamEventFlagKernelDropped)   [flags addObject: @"KernelDropped"];
      if (eventFlags & kFSEventStreamEventFlagEventIdsWrapped) [flags addObject: @"EventIdsWrapped"];
      if (eventFlags & kFSEventStreamEventFlagHistoryDone)     [flags addObject: @"HistoryDone"];
      if (eventFlags & kFSEventStreamEventFlagRootChanged)     [flags addObject: @"RootChanged"];
      if (eventFlags & kFSEventStreamEventFlagMount)           [flags addObject: @"Mount"];
      if (eventFlags & kFSEventStreamEventFlagUnmount)         [flags addObject: @"Unmount"];
    }
    
    NSLog(@"OAFSEventStream: event with path %@ (flags: %@)", path, [flags componentsJoinedByString:@"|"]);    
  }
  
  OAFSEventStreamCallbackBlock block = [self.blocksByPaths objectForKey:path];
  NSString* watchedPath = nil;
  if (block)
  {
    watchedPath = path;
  }
  else
  {
    NSString* longestCommonPrefix = @"";
    for (NSString* wp in self.blocksByPaths)
    {
      NSString* commonPrefix = [path commonPrefixWithPath:wp];
      if ([commonPrefix isEqualToString:wp] &&
          [commonPrefix length] > [longestCommonPrefix length])
      {
        longestCommonPrefix = commonPrefix;
      }
    }
    if ([longestCommonPrefix length] == 0) return;
    
    watchedPath = longestCommonPrefix;
  }
  NSString* shortestCoalescedPath = [self.coalescedPathsByPaths objectForKey:watchedPath];
  if (!shortestCoalescedPath || [shortestCoalescedPath length] > [path length])
  {
    [self.coalescedPathsByPaths setObject:path forKey:watchedPath];
  }
  [self delayCallbackForPath:watchedPath];
}



@end
