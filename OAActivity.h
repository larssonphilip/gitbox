// Presenter for OATask in a GBActivityController

@class OATask;
@interface OAActivity : NSObject
{
}

@property(assign) OATask* task;

@property(retain) NSString* path;
@property(retain) NSString* command;
@property(retain) NSString* status;
@property(retain) NSString* textOutput;

- (NSString*) recentTextOutput;

@end
