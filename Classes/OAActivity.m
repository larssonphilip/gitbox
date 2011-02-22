#import "OATask.h"
#import "OAActivity.h"


@implementation OAActivity

@synthesize task;
@synthesize isRunning;

@synthesize date;
@synthesize path;
@synthesize command;
@synthesize status;

@synthesize textOutput;

#pragma mark Init

- (void) dealloc
{
  self.date = nil;
  self.path = nil;
  self.command = nil;
  self.status = nil;
  self.textOutput = nil;
  [super dealloc];
}

- (id) init
{
  if ((self = [super init]))
  {
    self.date = [NSDate date];
  }
  return self;
}


#pragma mark Interrogation

- (NSString*) textOutput
{
  if (!textOutput)
  {
    return [self.task UTF8Output];
  }
  return [[textOutput retain] autorelease];
}

- (NSString*) line
{
  return [NSString stringWithFormat:@"%@\t%@\t%@", self.path, self.command, self.status];
}

@end
