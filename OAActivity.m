#import "OATask.h"
#import "OAActivity.h"
#import "NSData+OADataHelpers.h"


@implementation OAActivity

@synthesize task;

@synthesize path;
@synthesize command;
@synthesize status;

@synthesize textOutput;

#pragma mark Init

- (void) dealloc
{
  self.path = nil;
  self.command = nil;
  self.status = nil;
  self.textOutput = nil;
  [super dealloc];
}


#pragma mark Interrogation

- (NSString*) recentTextOutput
{
  NSString* recentString = [self.task.output UTF8String];
  if (recentString)
  {
    self.textOutput = recentString;
  }
  return self.textOutput;
}

@end
