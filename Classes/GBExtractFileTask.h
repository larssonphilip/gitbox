#import "GBTask.h"

@interface GBExtractFileTask : GBTask

@property(nonatomic,copy) NSString* objectId;
@property(nonatomic,copy) NSString* commitId;
@property(nonatomic,copy) NSString* folder;
@property(nonatomic,retain) NSURL* originalURL;
@property(nonatomic,retain) NSURL* targetURL;

@end
