#import "GBTask.h"

@interface GBExtractFileTask : GBTask

@property(nonatomic,copy) NSString* objectId;
@property(nonatomic,copy) NSString* commitId;
@property(nonatomic,copy) NSString* folder;
@property(nonatomic,strong) NSURL* originalURL;
@property(nonatomic,strong) NSURL* targetURL;

@end
