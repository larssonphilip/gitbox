// Used in projects (time revisited):
// - oleganza/gitbox (22.05.2010)

@interface NSAlert (OAAlertHelpers)

+ (NSInteger) error:(NSError*)error;
+ (NSInteger) message:(NSString*)message;
+ (NSInteger) message:(NSString*)message description:(NSString*)description;
+ (NSInteger) unsafePrompt:(NSString*)message description:(NSString*)description;
@end
