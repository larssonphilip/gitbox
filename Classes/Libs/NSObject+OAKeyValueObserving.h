// Created by Oleg Andreev on May 24, 2010.
// Based on MAKVONotification code by Michael Ash (October 15, 2008)

// What's different:
// - thread-safety removed for code clarity
// - API for selectorWithoutArguments
// - API for selectorWithNewValue

@interface NSObject (OAKeyValueObserving)

// Selector signature: 
// - (void) didUpdateSomething;
- (void)addObserver:(id)observer 
         forKeyPath:(NSString*)keyPath
           selectorWithoutArguments:(SEL)selector;

// Selector signature: 
// - (void) didUpdateSomething:(id)aValue;
- (void)addObserver:(id)observer 
         forKeyPath:(NSString*)keyPath
selectorWithNewValue:(SEL)selector;


// Selector signature:
// - (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)target change:(NSDictionary *)change userInfo:(id)userInfo;

- (void)addObserver:(id)observer 
         forKeyPath:(NSString*)keyPath
           selector:(SEL)selector;

- (void)addObserver:(id)observer 
         forKeyPath:(NSString*)keyPath 
           selector:(SEL)selector 
           userInfo:(id)userInfo 
            options:(NSKeyValueObservingOptions)options;

- (void)removeObserver:(id)observer 
               keyPath:(NSString*)keyPath 
              selector:(SEL)selector;

@end
