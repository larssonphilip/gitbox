#import "OAFSEventStream.h"
#import "GBFolderMonitor.h"

@interface GBFolderMonitor ()
@property(nonatomic, retain) NSDate* folderResumeDate;
@property(nonatomic, retain) NSDate* dotgitResumeDate;
@property(nonatomic, assign) NSInteger folderPauseCounter;
@property(nonatomic, assign) NSInteger dotgitPauseCounter;
@property(nonatomic, assign, readwrite) BOOL folderIsUpdated;
@property(nonatomic, assign, readwrite) BOOL dotgitIsUpdated;
@property(nonatomic, assign, readwrite) BOOL dotgitIsPaused;
@end

@implementation GBFolderMonitor

@synthesize eventStream;
@synthesize path;
@synthesize target;
@synthesize action;
@synthesize folderResumeDate;
@synthesize dotgitResumeDate;
@synthesize folderPauseCounter;
@synthesize dotgitPauseCounter;
@synthesize folderIsUpdated;
@synthesize dotgitIsUpdated;
@synthesize dotgitIsPaused;

- (void) dealloc
{
  // using setters to correctly remove the path and the observer from eventStream
  self.eventStream = nil;
  self.path = nil;
  self.folderResumeDate = nil;
  self.dotgitResumeDate = nil;
  [super dealloc];
}

- (void) setEventStream:(OAFSEventStream *)newEventStream
{
  if (newEventStream == eventStream) return;
  
  if (path) [eventStream removePath:path];
  if (eventStream) [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                                   name:OAFSEventStreamNotification 
                                                                 object:eventStream];
  
  [eventStream release];
  eventStream = [newEventStream retain];
  
  if (eventStream) [[NSNotificationCenter defaultCenter] addObserver:self
                                                            selector:@selector(eventStreamDidUpdate:)
                                                                name:OAFSEventStreamNotification
                                                              object:eventStream];
  if (path) [eventStream addPath:path];
}

- (void) setPath:(NSString *)aPath
{
  if (aPath == path) return;
  
  if (path) [eventStream removePath:path];
  
  [path release];
  path = [aPath copy];
  
  if (path) [eventStream addPath:path];
}

- (void) pauseDotGit
{
  self.dotgitPauseCounter++;
}

- (void) resumeDotGit
{
  self.dotgitPauseCounter--;
  if (self.dotgitPauseCounter == 0) 
  {
    self.dotgitResumeDate = [NSDate date];
  }
}

- (void) pauseFolder
{
  self.folderPauseCounter++;
}

- (void) resumeFolder
{
  self.folderPauseCounter--;
  if (self.folderPauseCounter == 0) 
  {
    self.folderResumeDate = [NSDate date];
  }
}

- (NSString*) description
{
  return [NSString stringWithFormat:@"<GBFolderMonitor:%p path=%@ eventStream=%@ target=%@ action=%@>", self, self.path, self.eventStream, self.target, self.action ? NSStringFromSelector(self.action) : nil];
}



#pragma mark Private


- (void) eventStreamDidUpdate:(NSNotification*)aNotification
{
  NSArray* events = [[aNotification userInfo] objectForKey:@"events"];
  if (!events)
  {
    NSLog(@"GBFolderMonitor: no 'events' key in notification userInfo!");
    return;
  }
  
  if (!self.path)
  {
    NSLog(@"GBFolderMonitor: self.path = nil, but did receive a notification! %@", aNotification);
    return;
  }
  
  BOOL folderDidChange = NO;
  BOOL dotgitDidChange = NO;
  
  NSString* dotGitPath = [self.path stringByAppendingPathComponent:@".git"];
  
  for (OAFSEvent* event in events)
  {
    if ([event containedInFolder:self.path])
    {
      if ([event.path isEqualToString:dotGitPath] || [event.path rangeOfString:[dotGitPath stringByAppendingString:@"/"]].location == 0)
      {
        dotgitDidChange = YES;
      }
      else
      {
        folderDidChange = YES;
      }
    }
    if (dotgitDidChange && folderDidChange) break;
  }
  
  if (!folderDidChange && !dotgitDidChange) return;

  // When folder on pause, should skip all events. 
  // Also we check if it was on pause less than <latency> sec. ago to skip those events too 
  // because they originate from the paused state.
  
  if (self.folderPauseCounter)
  {
    //NSLog(@"GBFolderMonitor: folder is on pause, skipping events: %@", events);
    return;
  }
  if (self.folderResumeDate)
  {
    NSTimeInterval timeSinceResume = [[NSDate date] timeIntervalSinceDate:self.folderResumeDate]; 
    if (timeSinceResume <= self.eventStream.latency)
    {
      NSLog(@"GBFolderMonitor: folder was on pause %f sec. ago (event latency %f), skipping events: %@", timeSinceResume, self.eventStream.latency, events);
      return;
    }
  }
  
  BOOL skipDotGitEvents = NO;
  
  if (self.dotgitPauseCounter)
  {
    NSLog(@"GBFolderMonitor: .git is on pause");
    skipDotGitEvents = YES;
  }
  else
  {
    if (self.dotgitResumeDate)
    {
      NSTimeInterval timeSinceResume = [[NSDate date] timeIntervalSinceDate:self.dotgitResumeDate]; 
      if (timeSinceResume <= self.eventStream.latency)
      {
        NSLog(@"GBFolderMonitor: .git was on pause %f sec. ago (event latency %f)", timeSinceResume, self.eventStream.latency);
        skipDotGitEvents = YES;
      }
    }
  }
  
  if (skipDotGitEvents)
  {
    if (!folderDidChange)
    {
      NSLog(@"GBFolderMonitor: only .git changed and .git is on pause, skipping events: %@", events);
      return;
    }
    else
    {
      NSLog(@"GBFolderMonitor: .git is on pause, but the folder changed");
    }
  }
  
  self.folderIsUpdated = folderDidChange;
  self.dotgitIsUpdated = dotgitDidChange;
  self.dotgitIsPaused = skipDotGitEvents;
  
//  NSLog(@"GBFolderMonitor: publishing status:%@%@%@",
//        (self.folderIsUpdated ? @" folderIsUpdated" : @""),
//        (self.dotgitIsUpdated ? @", dotgitIsUpdated" : @""),
//        (self.dotgitIsPaused ? @", dotgitIsPaused" : @"")
//        );

  if (!self.target || !self.action)
  {
    NSLog(@"WARNING: GBFolderMonitor: target or action is not set! Cannot publish status for events: %@", events);
  }
  
  if (self.action) [self.target performSelector:self.action withObject:self];
  
  // reset flags after calling target.action
  self.folderIsUpdated = NO;
  self.dotgitIsUpdated = NO;
  self.dotgitIsPaused = NO;
}




@end
