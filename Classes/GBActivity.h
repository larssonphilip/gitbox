// Presenter for OATask in a GBActivityController

@class OATask;
@interface GBActivity : NSObject

@property(nonatomic,assign) OATask* task;
@property(nonatomic,assign) BOOL isRunning;
@property(nonatomic,assign) BOOL isRetained; // YES if task is finished, but still retained.

@property(nonatomic,retain) NSDate* date;
@property(nonatomic,copy) NSString* path;
@property(nonatomic,copy) NSString* command;
@property(nonatomic,copy) NSString* status;
@property(nonatomic,copy) NSString* textOutput;
@property(nonatomic,copy) NSString* dataLength;

- (NSString*) line;
- (void) appendData:(NSData*)chunk;
@end
