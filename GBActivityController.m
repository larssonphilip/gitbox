#import "GBActivityController.h"
#import "OATask.h"
#import "OAActivity.h"

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
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
  self.activities = nil;
  self.outputTextView = nil;
  self.tableView = nil;
  self.arrayController = nil;
  [super dealloc];
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
  [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(syncActivityOutput) object:nil];
  
  if (![[self window] isVisible]) return;
  
  OAActivity* activity = nil;
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
      
      if (activity.isRunning)
      {
        [self performSelector:@selector(syncActivityOutput) withObject:nil afterDelay:0.5];
      }
    }    
  }
}


- (void) addActivity:(OAActivity*)activity
{
  NSUInteger maxNumberOfActivities = 1000;
  if ([self.activities count] > maxNumberOfActivities + 20) // 20 is a little overlap to avoid refreshing the array too often
  {
    self.activities = [[[self.activities subarrayWithRange:NSMakeRange([self.activities count] - maxNumberOfActivities, maxNumberOfActivities)] mutableCopy] autorelease];
  }
  
  if (self.arrayController)
  {
    [self.arrayController addObject:activity];
    [self.arrayController setSelectionIndex:[[self.arrayController content] count] - 1];
    [self syncActivityOutput];  
  }
  else // nib is not loaded yet
  {
    [self.activities addObject:activity];
  }
  
  if (self.tableView)
  {
    NSInteger numberOfRows = [self.tableView numberOfRows];
    if (numberOfRows > 0)
    {
      [self.tableView scrollRowToVisible:numberOfRows - 1];
    }
  }
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


@end
