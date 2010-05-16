@interface GBTask : NSObject
{
  NSString* path;
}

@property(retain) NSString* path;

- (int) launchWithArguments:(NSArray*)args outputRef:(NSData**)outputRef;
- (int) launchWithArguments:(NSArray*)args;

- (int) launchCommand:(NSString*)command outputRef:(NSData**)outputRef;
- (int) launchCommand:(NSString*)command;

@end
