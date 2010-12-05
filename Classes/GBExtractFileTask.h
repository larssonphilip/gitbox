#import "GBTask.h"

@interface GBExtractFileTask : GBTask

@property(nonatomic,retain) NSString* objectId;
@property(nonatomic,retain) NSString* commitId;
@property(nonatomic,retain) NSURL* originalURL;
@property(nonatomic,retain) NSURL* targetURL;

@end
