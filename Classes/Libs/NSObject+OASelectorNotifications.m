/*
 
 Oleg Andreev <oleganza@gmail.com>
 January 25, 2011
 
 With NSNotificationCenter you post notifications with a name like MyNotification.
 Observer subscribes to this name with some selector like myNotification:
 
 To make things easier and less verbose, we won't declare notification names, but only the selectors.
 You will subscribe directly to the observed object with a given selector.
 Notification name will be calculated from the observable object class and the selector.
 The only argument of the selector will be the sender (not the notification object as usually)
 
 Examples: 
 
 1. Post a notification from repository:
 
 [self notifyWithSelector:@selector(repositoryDidUpdateChanges:)];
 [self notifyWithSelector:@selector(repository:didCheckoutBranch:) withObject:aBranch];
 
 2. Subscribe for notifications from repository:
 
 [repository addObserver:self forSelector:@selector(repositoryDidUpdateChanges:)];
 [repository addObserver:self forSelector:@selector(repository:didCheckoutBranch:)];
 
 3. Unsubscribe from notifications from repository:
 
 [repository removeObserver:self forSelector:@selector(repositoryDidUpdateChanges:)];
 [repository removeObserver:self forSelector:@selector(repository:didCheckoutBranch:)];
 
 4. Receive a notification:
 
 - (void) repositoryDidUpdateChanges:(GBRepository*)aRepository { ... }
 - (void) repository:(GBRepository*)aRepository didCheckoutBranch:(GBRef*)aBranch { ... }
 
 
 If the selector is NULL when subscribing, the name will be nil.
 To unsubscribe from all the objects (usually in dealloc), use [[NSNotificationCenter defaultCenter] removeObserver:self];
 
 This file is distributed under MIT license.
 
 */

#import "NSObject+OASelectorNotifications.h"

@implementation NSObject (OASelectorNotifications)

+ (NSString*) OANotificationNameForSelector:(SEL)selector
{
	return [NSString stringWithFormat:@"OASelectorNotification:%@", NSStringFromSelector(selector)];
}

- (NSString*) OANotificationNameForSelector:(SEL)selector
{
	return [NSObject OANotificationNameForSelector:selector];
}

- (void) OADispatchSelectorNotification:(NSNotification*)notification
{
	NSDictionary* userInfo = [notification userInfo];
	NSString* selectorString = [userInfo objectForKey:@"OANotificationSelector"];
	
	// Note: When listening for all selectors, this method can catch all possible notifications. 
	//       So we should ignore those which do not contain actual selector.
	if (!selectorString)
	{
		return;
	}
	
	SEL selector = NSSelectorFromString(selectorString);
	NSAssert(selector, @"OADispatchSelectorNotification cannot convert OANotificationSelector from NSString to SEL");
	if ([self respondsToSelector:selector])
	{
		id argument = [userInfo objectForKey:@"OANotificationSelectorArgument"];
		if ([userInfo objectForKey:@"OANotificationSelectorWithArgument"])
		{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
			[self performSelector:selector withObject:notification.object withObject:argument];
#pragma clang diagnostic pop
		}
		else
		{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
			[self performSelector:selector withObject:notification.object];
#pragma clang diagnostic pop
		}
	}
}


- (void) notifyWithSelector:(SEL)selector
{
	NSAssert(selector, @"notifySelector: requires non-nil selector");
	
	NSNotification* aNotification = [NSNotification notificationWithName:[self OANotificationNameForSelector:selector] 
																  object:self
																userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
																		  NSStringFromSelector(selector), @"OANotificationSelector", 
																		  nil]];
	if ([self respondsToSelector:@selector(delegate)])
	{
		id delegate = [(id)self delegate];
		if ([delegate respondsToSelector:selector])
		{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
			[delegate performSelector:selector withObject:self];
#pragma clang diagnostic pop
		}
	}
	[[NSNotificationCenter defaultCenter] postNotification:aNotification];
}

- (void) notifyWithSelector:(SEL)selector withObject:(id)argument
{
	NSAssert(selector, @"notifySelector: requires non-nil selector");
	
	NSNotification* aNotification = [NSNotification notificationWithName:[self OANotificationNameForSelector:selector] 
																  object:self
																userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
																		  NSStringFromSelector(selector), @"OANotificationSelector", 
																		  @"YES", @"OANotificationSelectorWithArgument",
																		  argument, @"OANotificationSelectorArgument", 
																		  nil]];
	if ([self respondsToSelector:@selector(delegate)])
	{
		id delegate = [(id)self delegate];
		if ([delegate respondsToSelector:selector])
		{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
			[delegate performSelector:selector withObject:self withObject:argument];
#pragma clang diagnostic pop
		}
	}
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

+ (void) addObserver:(id)observer forSelector:(SEL)selector
{
	NSString* name = nil;
	if (selector)
	{
		name = [self OANotificationNameForSelector:selector];
	}
	[[NSNotificationCenter defaultCenter] addObserver:observer selector:@selector(OADispatchSelectorNotification:) name:name object:nil];
}

+ (void) removeObserver:(id)observer forSelector:(SEL)selector
{
	NSString* name = nil;
	if (selector)
	{
		name = [self OANotificationNameForSelector:selector];
	}
	[[NSNotificationCenter defaultCenter] removeObserver:observer name:name object:nil];
}

- (void) addObserverForAllSelectors:(id)observer
{
	[self addObserver:observer forSelector:NULL];
}

- (void) removeObserverForAllSelectors:(id)observer
{
	[self removeObserver:observer forSelector:NULL];
}



@end
