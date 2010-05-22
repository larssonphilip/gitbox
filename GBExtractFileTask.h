#import "GBTask.h"

@interface GBExtractFileTask : GBTask
{
  NSString* objectId;
  NSURL* originalURL;
  NSURL* temporaryURL;
}

@property(retain) NSString* objectId;
@property(retain) NSURL* originalURL;
@property(retain) NSURL* temporaryURL;

@end
