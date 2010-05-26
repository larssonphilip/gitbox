#import "GBActivityController.h"
#import "OATask.h"
#import "OAActivity.h"

@implementation GBActivityController

static GBActivityController* sharedGBActivityController;

@synthesize activities;
@synthesize outputTextView;



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
  self.activities = nil;
  self.outputTextView = nil;
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


- (void) periodicOutputSync
{
  [self performSelector:@selector(periodicOutputSync) withObject:nil afterDelay:0.5];
  OAActivity* activity = nil;
  NSString* text = [activity textOutput];
  [self.outputTextView insertText:text];
}





#pragma mark NSWindowController


- (void) windowDidLoad
{
  [super windowDidLoad];
}  



#pragma mark NSWindowDelegate


- (void)windowDidBecomeKey:(NSNotification *)notification
{
  [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(periodicOutputSync) object:nil];
  [self periodicOutputSync];
}

- (void)windowDidResignKey:(NSNotification *)notification
{
  [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(periodicOutputSync) object:nil];
}

@end
