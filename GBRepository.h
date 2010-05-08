@interface GBRepository : NSObject
{
  NSString* path;
}

+ (BOOL) isValidRepositoryAtPath:(NSString*)path;

@property(nonatomic,retain) NSString* path;

@end
