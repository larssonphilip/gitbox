@interface NSAlert (OAAlertHelpers)

+ (NSInteger) error:(NSError*)error;
+ (NSInteger) message:(NSString*)message;
+ (NSInteger) message:(NSString*)message description:(NSString*)description;
+ (NSInteger) unsafePrompt:(NSString*)message description:(NSString*)description;
@end
