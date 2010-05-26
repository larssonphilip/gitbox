#import "OATask.h"
#import "OAActivity.h"
#import "NSData+OADataHelpers.h"


@implementation OAActivity

@synthesize task;
@synthesize isRunning;

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

- (NSString*) textOutput
{
  if (!textOutput)
  {
    return [self.task.output UTF8String];
  }
  return [[textOutput retain] autorelease];
}

@end
