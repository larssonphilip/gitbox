
@interface NSMenu (OAMenuHelpers)
+ (NSMenu*) menu;
+ (NSMenu*) menuWithTitle:(NSString*)title;
@end


@interface NSMenuItem (OAMenuHelpers)
+ (NSMenuItem*) menuItemWithTitle:(NSString*)title submenu:(NSMenu*)menu;
@end
