// Used in projects (time revisited):
// - oleganza/gitbox (22.05.2010)

@interface NSAlert (OAAlertHelpers)

+ (NSInteger) error:(NSError*)error;
+ (NSInteger) message:(NSString*)message;
+ (NSInteger) message:(NSString*)message description:(NSString*)description;
+ (NSInteger) message:(NSString*)message description:(NSString*)description buttonTitle:(NSString*)buttonTitle;

+ (BOOL) prompt:(NSString*)message description:(NSString*)description;
+ (BOOL) prompt:(NSString*)message description:(NSString*)description ok:(NSString*)okTitle;
+ (BOOL) prompt:(NSString*)message description:(NSString*)description window:(NSWindow*)aWindow;
+ (BOOL) prompt:(NSString*)message description:(NSString*)description ok:(NSString*)okTitle window:(NSWindow*)aWindow;
@end
