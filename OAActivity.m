#import "OATask.h"
#import "OAActivity.h"
#import "NSData+OADataHelpers.h"


@implementation OAActivity

@synthesize task;

#pragma mark Init


#pragma mark Interrogation

- (NSString*) textOutput
{
  return [self.task.output UTF8String];
}

@end
