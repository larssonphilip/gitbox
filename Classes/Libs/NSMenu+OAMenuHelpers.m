#import "NSMenu+OAMenuHelpers.h"

@implementation NSMenu (OAMenuHelpers)

+ (NSMenu*) menu
{
  return [self menuWithTitle:nil];
}

+ (NSMenu*) menuWithTitle:(NSString*)title
{
  NSMenu* menu = [[[self alloc] init] autorelease];
  if (title) [menu setTitle:title];
  [menu setAutoenablesItems:YES];
  return menu;  
}

@end


@implementation NSMenuItem(OAMenuHelpers)

+ (NSMenuItem*) menuItemWithTitle:(NSString*)title submenu:(NSMenu*)menu
{
  NSMenuItem* item = [[[self alloc] init] autorelease];
  if (title) [item setTitle:title];
  if (menu) [item setSubmenu:menu];
  return item;
}

+ (NSMenuItem*) menuItemWithTitle:(NSString*)title action:(SEL)action
{
  NSMenuItem* item = [[[self alloc] init] autorelease];
  if (title) [item setTitle:title];
  if (action) [item setAction:action];
  return item;
}

+ (NSMenuItem*) menuItemWithTitle:(NSString*)title action:(SEL)action object:(NSObject*)object
{
  NSMenuItem* item = [[[self alloc] init] autorelease];
  if (title) [item setTitle:title];
  if (action) [item setAction:action];
  [item setRepresentedObject:object];
  return item;
}

@end
