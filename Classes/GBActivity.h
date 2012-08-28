// Presenter for OATask in a GBActivityController

@class OATask;
@interface GBActivity : NSObject

@property(nonatomic,weak) OATask* task;
@property(nonatomic,assign) BOOL isRunning;

@property(nonatomic,strong) NSDate* date;
@property(nonatomic,copy) NSString* path;
@property(nonatomic,copy) NSString* command;
@property(nonatomic,copy) NSString* status;
@property(nonatomic,copy) NSString* textOutput;
@property(nonatomic,copy) NSString* dataLength;

- (NSString*) line;
- (void) appendData:(NSData*)chunk;
- (void) trimIfNeeded;

@end
