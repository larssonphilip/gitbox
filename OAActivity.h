// Presenter for OATask in a GBActivityController

@class OATask;
@interface OAActivity : NSObject
{
}

@property(assign) OATask* task; 

- (NSString*) textOutput;

@end
