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
 
 2. Subscribe for notifications from repository:
 
    [repository addObserver:self forSelector:@selector(repositoryDidUpdateChanges:)];
 
 3. Unsubscribe from notifications from repository:
 
    [repository removeObserver:self forSelector:@selector(repositoryDidUpdateChanges:)];
 
 4. Receive a notification:
    
    - (void) repositoryDidUpdateChanges:(GBRepository*)aRepository { ... }
    

 If the selector is NULL when subscribing, the name will be nil.
 To unsubscribe from all the objects (usually in dealloc), use [[[NSNotificationCenter] defaultCenter] removeObserver:self];

 This file is distributed under MIT license.
 
*/

@interface NSObject (OASelectorNotifications)
- (void) notifyWithSelector:(SEL)selector;
- (void) addObserver:(id)observer forSelector:(SEL)selector;
- (void) removeObserver:(id)observer forSelector:(SEL)selector;
- (void) addSelectorObserver:(id)observer;
- (void) removeSelectorObserver:(id)observer;
@end
