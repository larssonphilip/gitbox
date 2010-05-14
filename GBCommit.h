@interface GBCommit : NSObject
{
  NSString* revision;
  NSArray* changes;

  NSString* comment;
  NSString* authorName;
  NSString* authorEmail;
  NSDate* date;
  
  BOOL isWorkingDirectory;
}

@property(retain) NSString* revision;
@property(retain) NSArray* changes;

@property(retain) NSString* comment;
@property(retain) NSString* authorName;
@property(retain) NSString* authorEmail;
@property(retain) NSDate* date;

@property(assign) BOOL isWorkingDirectory;

@end
