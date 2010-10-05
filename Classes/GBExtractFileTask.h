#import "GBTask.h"

@interface GBExtractFileTask : GBTask
{
  NSString* objectId;
  NSURL* originalURL;
  NSURL* temporaryURL;
}

@property(nonatomic,retain) NSString* objectId;
@property(nonatomic,retain) NSURL* originalURL;
@property(nonatomic,retain) NSURL* temporaryURL;

@end
