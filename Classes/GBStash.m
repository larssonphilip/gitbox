#import "GBStash.h"

@implementation GBStash

@synthesize ref;
@synthesize date;
@synthesize rawMessage;
@dynamic message;

- (void) dealloc
{
  self.ref = nil;
  self.date = nil;
  self.rawMessage = nil;
  [super dealloc];
}

+ (NSTimeInterval) oldStashesTreshold
{
  return 30.0*24*3600;
}

- (NSString*) message
{
  return [[self.rawMessage 
           stringByReplacingOccurrencesOfString:@"On master: " withString:@""] 
          stringByReplacingOccurrencesOfString:@"WIP on master: " withString:@""];
}

- (NSString*) menuTitle
{
  NSString* msg = self.message;
  
  // Take the first line
  msg = [[msg componentsSeparatedByString:@"\n"] objectAtIndex:0];
  
  // Truncate message if it's too long
  int maxLength = 64;
  if ([msg length] > maxLength)
  {
    msg = [[msg substringToIndex:maxLength - 3] stringByAppendingString:@"..."];
  }
  
  if (!self.date) return msg;
  
  NSDate* today = [NSDate date];
  NSDateFormatter* formatter = [[[NSDateFormatter alloc] init] autorelease];
  NSString* dateString = @"";
  if ([today timeIntervalSinceDate:self.date] < 12*3600.0)
  {
    [formatter setDateFormat:[NSDateFormatter dateFormatFromTemplate:@"HH:mm" options:0 locale:[NSLocale currentLocale]]];
    dateString = [formatter stringFromDate:self.date];
  }
  else
  {
    [formatter setDateFormat:[NSDateFormatter dateFormatFromTemplate:@"MMM d, y HH:mm" options:0 locale:[NSLocale currentLocale]]];
    dateString = [formatter stringFromDate:self.date];
  }
  
  msg = [msg stringByAppendingFormat:@" (%@)", dateString];
  
  return msg;
}

@end
