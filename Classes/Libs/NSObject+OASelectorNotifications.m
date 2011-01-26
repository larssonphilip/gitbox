/*
 
 Oleg Andreev <oleganza@gmail.com>
 January 25, 2011
 
 With NSNotificationCenter you post notifications with a name like MyNotification.
 Observer subscribes to this name with some selector like myNotification:
 
 To make things easier and less verbose, we won't declare notification names, but only the selectors.
 You will subscribe directly to the observed object with a given selector.
 Notification name will be calculated from the observable object class and the selector.
 The only argument of the selector will be an instance of NSNotification with its "object" returning the sender, as usual.
 
 Examples: 
 
 1. Post a notification from repository:
 
    [self notifyWithSelector:@selector(repositoryDidUpdateChanges:)];
 
 2. Subscribe for notifications from repository:
 
    [repository addObserver:self forSelector:@selector(repositoryDidUpdateChanges:)];
 
 3. Unsubscribe from notifications from repository:
 
    [repository removeObserver:self forSelector:@selector(repositoryDidUpdateChanges:)];
 
 4. Receive a notification:
 
    - (void) repositoryDidUpdateChanges:(NSNotification*)aNotification { ... }
 
 
 If the selector is NULL when subscribing, the name will be nil.
 To unsubscribe from all the objects (usually in dealloc), use [[[NSNotificationCenter] defaultCenter] removeObserver:self];
 
 This file is distributed under MIT license.
 
*/

#import "NSObject+OASelectorNotifications.h"

@implementation NSObject (OASelectorNotifications)

- (NSString*) OANotificationNameForSelector:(SEL)selector
{
  return [NSString stringWithFormat:@"[%@ %@]", [self class], NSStringFromSelector(selector)];
}

- (void) OADispatchSelectorNotification:(NSNotification*)notification
{
  NSDictionary* userInfo = [notification userInfo];
  NSString* selectorString = [userInfo objectForKey:@"OANotificationSelector"];
  NSAssert(selectorString, @"OADispatchSelectorNotification expects a userInfo to contain a selector for key OANotificationSelector");
  SEL selector = NSSelectorFromString(selectorString);
  NSAssert(selector, @"OADispatchSelectorNotification cannot convert OANotificationSelector from NSString to SEL");
  if ([self respondsToSelector:selector])
  {
    [self performSelector:selector withObject:self];
  }
}


- (void) notifyWithSelector:(SEL)selector
{
  NSAssert(selector, @"notifySelector: requires non-nil selector");
  NSNotification* aNotification = [NSNotification notificationWithName:[self OANotificationNameForSelector:selector] 
                                                                object:self
                                                              userInfo:[NSDictionary dictionaryWithObject:NSStringFromSelector(selector) forKey:@"OANotificationSelector"]];
  [[NSNotificationCenter defaultCenter] postNotification:aNotification];
}

- (void) addObserver:(id)observer forSelector:(SEL)selector
{
  NSString* name = nil;
  if (selector)
  {
    name = [self OANotificationNameForSelector:selector];
  }
  [[NSNotificationCenter defaultCenter] addObserver:observer selector:@selector(OADispatchSelectorNotification:) name:name object:self];
}

- (void) removeObserver:(id)observer forSelector:(SEL)selector
{
  NSString* name = nil;
  if (selector)
  {
    name = [self OANotificationNameForSelector:selector];
  }
  [[NSNotificationCenter defaultCenter] removeObserver:observer name:name object:self];
}

- (void) addSelectorObserver:(id)observer
{
  [self addObserver:observer forSelector:NULL];
}

- (void) removeSelectorObserver:(id)observer
{
  [self removeObserver:observer forSelector:NULL];
}


@end
