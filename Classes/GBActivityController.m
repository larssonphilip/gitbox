#import "GBActivityController.h"
#import "OATask.h"
#import "GBActivity.h"
#import "NSArray+OAArrayHelpers.h"

@implementation GBActivityController

static GBActivityController* sharedGBActivityController;

@synthesize activities;
@synthesize outputTextView;
@synthesize tableView;
@synthesize arrayController;


#pragma mark Init


+ (id) sharedActivityController
{
  if (!sharedGBActivityController)
  {
    sharedGBActivityController = [[self alloc] initWithWindowNibName:@"GBActivityController"];
  }
  return sharedGBActivityController;
}

- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  self.activities = nil;
  self.outputTextView = nil;
  self.tableView = nil;
  self.arrayController = nil;
  [super dealloc];
}

- (id) initWithWindowNibName:(NSString *)windowNibName
{
  if ((self = [super initWithWindowNibName:windowNibName]))
  {
    // subscribe for the OATask notifications.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(taskDidLaunch:) 
                                                 name:OATaskDidLaunchNotification 
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(taskDidUpdate:) 
                                                 name:OATaskDidEnterQueueNotification 
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(taskDidUpdate:) 
                                                 name:OATaskDidReceiveDataNotification 
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(taskDidTerminate:) 
                                                 name:OATaskDidTerminateNotification 
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(taskDidDeallocate:) 
                                                 name:OATaskDidDeallocateNotification
                                               object:nil];

  }
  return self;
}

- (NSMutableArray*) activities
{
  if (!activities)
  {
    self.activities = [NSMutableArray array];
  }
  return [[activities retain] autorelease];
}



#pragma mark Update


- (void) syncActivityOutput
{
  if (![[self window] isVisible]) return;
  
  GBActivity* activity = nil;
  if ([[self.arrayController selectedObjects] count] == 1)
  {
    activity = [[self.arrayController selectedObjects] objectAtIndex:0];
    if (activity)
    {
      NSString* text = activity.textOutput;
      //NSLog(@"OAActivityController: syncing %d bytes of text", [text length]);
      if (text)
      {
        [self.outputTextView setString:text];
      }
      else
      {
        [self.outputTextView setString:@""]; // setting nil corrupts entire text system in a window
      }
    }    
  }
}


- (void) addActivity:(GBActivity*)activity
{
  static int maxNumberOfActivities = 100;  
  
  if ([self.activities count] > maxNumberOfActivities + (maxNumberOfActivities/10)) // a little overlap to avoid refreshing the array too often
  {
    NSMutableArray* keptActivities = [NSMutableArray array];
    
    int c = maxNumberOfActivities;
    for (GBActivity* a in [self.activities reversedArray])
    {
      if (a.isRunning)
      {
        [keptActivities insertObject:a atIndex:0];
      }
      else if (c > 0)
      {
        c--;
        [keptActivities insertObject:a atIndex:0];
      }
    }
    
    self.activities = keptActivities;
  }
  
  [self.activities addObject:activity];
  
  if (self.arrayController)
  {
    [self.arrayController rearrangeObjects];
    [self syncActivityOutput];
  }

  // For now simply do not scroll to the end. Should be smarter later.
//  if (self.tableView)
//  {
//    NSInteger numberOfRows = [self.tableView numberOfRows];
//    if (numberOfRows > 0)
//    {
//      [self.tableView scrollRowToVisible:numberOfRows - 1];
//    }
//  }
}



#pragma mark NSWindowController


- (void) windowDidLoad
{
  [super windowDidLoad];
}  




#pragma mark NSWindowDelegate


- (void)windowDidBecomeKey:(NSNotification*)notification
{
  [self syncActivityOutput];
}

- (void)windowDidResignKey:(NSNotification*)notification
{
  
}


#pragma mark NSTableViewDelegate


- (void)tableViewSelectionDidChange:(NSNotification*)aNotification
{
  [self syncActivityOutput];
}





#pragma mark OATask notifications


- (GBActivity*) activityForTask:(OATask*)aTask
{
  for (GBActivity* activity in self.activities)
  {
    if (activity.task == aTask) return activity;
  }
  return nil;
}

- (void) taskDidUpdate:(NSNotification*)notif
{
  OATask* aTask = [notif object];
  NSData* chunk = [[notif userInfo] objectForKey:@"data"];
  GBActivity* activity = [self activityForTask:aTask];
  if (!activity) return;
  
  [activity appendData:chunk];
  
  if (aTask.isWaiting)
  {
    activity.status = NSLocalizedString(@"Waiting...", @"Task");
  }
  else if (aTask.isRunning)
  {
    activity.status = NSLocalizedString(@"Running...", @"Task");
  }
  else
  {
    if ([aTask terminationStatus] == 0)
    {
      activity.status = NSLocalizedString(@"Finishing...", @"Task");
    }
    else
    {
      activity.status = [NSString stringWithFormat:@"%@ [%d]", NSLocalizedString(@"Finishing...", @"Task"), [aTask terminationStatus]];
    }
  }
  [self syncActivityOutput];
}

- (void) taskDidTerminate:(NSNotification*)notif
{
  [self taskDidUpdate:notif];
}

- (void) taskDidLaunch:(NSNotification*)notif
{
  GBActivity* activity = [[[GBActivity alloc] init] autorelease];
  
  OATask* aTask = [notif object];
  activity.task = aTask;
  activity.isRunning = YES;
  activity.path = aTask.currentDirectoryPath;
  activity.command = [aTask command];
  
  [self addActivity:activity];
  
  [self taskDidUpdate:notif];
}

// Achtung: the notification can be posted from other thread
- (void) taskDidDeallocate:(NSNotification*)notif
{
  __block OATask* aTask = [[notif object] nonretainedObjectValue]; // __block prevents retaining
  int status = [aTask terminationStatus];
  dispatch_async(dispatch_get_main_queue(), ^{
    GBActivity* activity = [self activityForTask:aTask];
    activity.isRunning = NO;
    activity.task = nil;
    
    if (status == 0)
    {
      activity.status = NSLocalizedString(@"Finished", @"Task");
    }
    else
    {
      activity.status = [NSString stringWithFormat:@"%@ [%d]", NSLocalizedString(@"Finished", @"Task"), status];
    }
    
    [activity trimIfNeeded];
    
    [self syncActivityOutput];
  });
}



@end
