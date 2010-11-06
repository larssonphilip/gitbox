#import "GBTask.h"

@interface GBExtractFileTask : GBTask

@property(retain) NSString* objectId;
@property(retain) NSURL* originalURL;
@property(nonatomic,retain) NSURL* targetURL;

@end
