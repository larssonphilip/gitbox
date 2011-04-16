#import "OATask.h"
#import "GBActivity.h"
#import "NSData+OADataHelpers.h"

@interface GBActivity ()
@property(nonatomic, retain) NSMutableData* data;
@end 

@implementation GBActivity

@synthesize task;
@synthesize isRunning;
@synthesize isRetained;

@synthesize date;
@synthesize path;
@synthesize command;
@synthesize status;

@synthesize textOutput;
@synthesize data;
@synthesize dataLength;

#pragma mark Init

- (void) dealloc
{
  [date release]; date = nil;
  [path release]; path = nil;
  [command release]; command = nil;
  [status release]; status = nil;
  [textOutput release]; textOutput = nil;
  [data release]; data = nil;
  [dataLength release]; dataLength = nil;
  [super dealloc];
}

- (id) init
{
  if ((self = [super init]))
  {
    self.date = [NSDate date];
    self.data = [NSMutableData dataWithLength:0];
  }
  return self;
}

- (void) appendData:(NSData*)chunk
{
  if (!chunk) return;
  [self.data appendData:chunk];
  self.textOutput = [self.data UTF8String];
  NSUInteger l = [self.data length];
  self.dataLength = l ? [NSString stringWithFormat:@"%d", (int)l] : @"";
}


#pragma mark Interrogation

- (NSString*) line
{
  return [NSString stringWithFormat:@"%@\t%@\t%@", self.path, self.command, self.status];
}

@end
