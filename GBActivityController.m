#import "GBActivityController.h"
#import "OATask.h"
#import "OAActivity.h"

@implementation GBActivityController

static GBActivityController* sharedGBActivityController;

@synthesize activities;
@synthesize outputTextView;
@synthesize outputTextField;
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
  self.outputTextField = nil;
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
  //[self performSelector:@selector(periodicOutputSync) withObject:nil afterDelay:0.5];
  OAActivity* activity = nil;
  if ([[self.arrayController selectedObjects] count] == 1)
  {
    activity = [[self.arrayController selectedObjects] objectAtIndex:0];
  }
  if (activity)
  {
    NSString* text = activity.textOutput;
    NSLog(@"OAActivityController: syncing %d bytes of text", [text length]);
    [self.outputTextField setStringValue:text];    
  }
}


- (void) periodicCleanUp
{
  [self performSelector:@selector(periodicCleanUp) withObject:nil afterDelay:60*60.0];
  // TODO: remove old items
}

- (void) addActivity:(OAActivity*)activity
{
  if (self.arrayController)
  {
    [self.arrayController addObject:activity];
  }
  else // nib is not loaded yet
  {
    [self.activities addObject:activity];
  }

}



#pragma mark NSWindowController


- (void) windowDidLoad
{
  [super windowDidLoad];
}  



#pragma mark NSWindowDelegate


- (void)windowDidBecomeKey:(NSNotification *)notification
{
  [self syncActivityOutput];
}

- (void)windowDidResignKey:(NSNotification *)notification
{
}


#pragma mark NSTableViewDelegate


- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
  [self syncActivityOutput];
}


@end
