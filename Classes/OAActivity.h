// Presenter for OATask in a GBActivityController

@class OATask;
@interface OAActivity : NSObject
{
  OATask* task;
  BOOL isRunning;
  
  NSString* path;
  NSString* command;
  NSString* status;
  NSString* textOutput;
}

@property(nonatomic,assign) OATask* task;
@property(nonatomic,assign) BOOL isRunning;

@property(nonatomic,retain) NSDate* date;
@property(nonatomic,retain) NSString* path;
@property(nonatomic,retain) NSString* command;
@property(nonatomic,retain) NSString* status;
@property(nonatomic,retain) NSString* textOutput;

- (NSString*) line;

@end
