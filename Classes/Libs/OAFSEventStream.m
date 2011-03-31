#import "OAFSEventStream.h"

NSString* const OAFSEventStreamNotification = @"OAFSEventStreamNotification";

@interface OAFSEventStream ()
@property(nonatomic, retain) NSCountedSet* pathsBag;
@property(nonatomic, assign) BOOL started;
- (void) update;
@end

@implementation OAFSEventStream

@synthesize dispatchQueue;
@synthesize latency;
@synthesize watchRoot;
@synthesize ignoreSelf;
@synthesize pathsBag;
@synthesize started;
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

- (void) start
{
  self.started = YES;
  [self update];
}

- (void) stop
{
  self.started = NO;
  [self update];  
}


#pragma mark Private


- (void) update
{
  
}


@end
