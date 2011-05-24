// Used in projects (time revisited):
// - oleganza/gitbox (22.05.2010)

@interface NSMenu (OAMenuHelpers)
+ (NSMenu*) menu;
+ (NSMenu*) menuWithTitle:(NSString*)title;
@end


@interface NSMenuItem (OAMenuHelpers)
+ (NSMenuItem*) menuItemWithTitle:(NSString*)title submenu:(NSMenu*)menu;
+ (NSMenuItem*) menuItemWithTitle:(NSString*)title action:(SEL)action;
@end
