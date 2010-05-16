@interface GBRemote : NSObject
{
  NSString* alias;
  NSString* URLString;
  NSArray* branches;
}

@property(nonatomic,retain) NSString* alias;
@property(nonatomic,retain) NSString* URLString;
@property(nonatomic,retain) NSArray* branches;

@end
