#import "NSObject+OAKeyValueObserving.h"
#import <objc/message.h>


#pragma mark Private headers


@interface OAKeyValueObservingListener : NSObject
{
	id	  		__weak observer;
	id	  		__weak target;
	NSString*	keyPath;
	SEL		  	selector;
	SEL       selectorWithNewValue;
	SEL		  	selectorWithoutArguments;
	id		  	userInfo;
	NSKeyValueObservingOptions options;
	
}

@property(nonatomic,weak) id observer;
@property(nonatomic,weak) id target;
@property(nonatomic,strong) NSString* keyPath;
@property(nonatomic,assign) SEL selector;
@property(nonatomic,assign) SEL selectorWithNewValue;
@property(nonatomic,assign) SEL selectorWithoutArguments;
@property(nonatomic,strong) id userInfo;
@property(nonatomic,assign) NSKeyValueObservingOptions options;

- (SEL) anySelector;

- (void) subscribe;
- (void) unsubscribe;

@end


@interface OAKVONotificationCenter : NSObject
{
	NSMutableDictionary* listeners;
}

@property(nonatomic,strong) NSMutableDictionary* listeners;

+ (id)defaultCenter;

- (void)addListener:(OAKeyValueObservingListener*)listener;
- (void)removeObserver:(id)observer target:(id)target keyPath:(NSString*)keyPath selector:(SEL)selector;

@end






#pragma mark Implementation



@implementation OAKeyValueObservingListener

static char OAKeyValueObservingListenerMagicContext;

@synthesize observer;
@synthesize target;
@synthesize keyPath;
@synthesize selector;
@synthesize selectorWithNewValue;
@synthesize selectorWithoutArguments;
@synthesize userInfo;
@synthesize options;


- (SEL) anySelector
{
	if (selectorWithoutArguments)
	{
		return selectorWithoutArguments;
	}
	else if (selectorWithNewValue)
	{
		return selectorWithNewValue;
	}
	else if (selector)
	{
		return selector;
	}
	return NULL;
}

- (void) subscribe
{
	if (selectorWithNewValue)
	{
		options = options | NSKeyValueObservingOptionNew;
	}
	[self.target addObserver:self
				  forKeyPath:self.keyPath
					 options:self.options
					 context:&OAKeyValueObservingListenerMagicContext];
}

- (void) unsubscribe
{
	[self.target removeObserver:self forKeyPath:self.keyPath];
}


- (void) observeValueForKeyPath:(NSString*)aKeyPath
                       ofObject:(id)anObject
                         change:(NSDictionary*)aChange
                        context:(void*)aContext
{
	if (aContext == &OAKeyValueObservingListenerMagicContext)
	{
		// Mike: we only ever sign up for one notification per object, so if we got here
		// then we *know* that the key path and object are what we want
		
		if (selectorWithoutArguments)
		{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
			[observer performSelector:selectorWithoutArguments];
#pragma clang diagnostic pop
		}
		else if (selectorWithNewValue)
		{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
			[observer performSelector:selectorWithNewValue withObject:[aChange objectForKey:NSKeyValueChangeNewKey]];
#pragma clang diagnostic pop
		}
		else if (selector)
		{
			((void (*)(id, SEL, NSString *, id, NSDictionary *, id))objc_msgSend)(observer, selector, aKeyPath, anObject, aChange, self.userInfo);
		}
	}
	else // Oleg: this should probably never happen, but anyway
	{
		[super observeValueForKeyPath:aKeyPath ofObject:anObject change:aChange context:aContext];
	}
}

@end







@implementation OAKVONotificationCenter

@synthesize listeners;

+ (id)defaultCenter
{
	static OAKVONotificationCenter* center = nil;
	if (!center)
	{
		center = [[self alloc] init];
	}
	return center;
}

- (NSMutableDictionary*) listeners
{
	if (!listeners)
	{
		self.listeners = [NSMutableDictionary dictionary];
	}
	return listeners;
}




- (id) listenerKeyForObserver:(id)observer
                       target:(id)target
                      keyPath:(NSString*)keyPath
                     selector:(SEL)selector
{
	return [NSString stringWithFormat:@"%p:%p:%@:%p", observer, target, keyPath, selector];
}

- (void)addListener:(OAKeyValueObservingListener*)listener
{
	id key = [self listenerKeyForObserver:listener.observer
								   target:listener.target
								  keyPath:listener.keyPath
								 selector:[listener anySelector]];
	[self.listeners setObject:listener forKey:key];
	[listener subscribe];
}

- (void)removeObserver:(id)observer target:(id)target keyPath:(NSString*)keyPath selector:(SEL)selector
{
	id key = [self listenerKeyForObserver:observer target:target keyPath:keyPath selector:selector];
	OAKeyValueObservingListener* listener = [self.listeners objectForKey:key];
	[listener unsubscribe];
	[self.listeners removeObjectForKey:key];
}

@end



@implementation NSObject (OAKeyValueObserving)

- (void)addObserver:(id)observer
         forKeyPath:(NSString*)keyPath
selectorWithoutArguments:(SEL)selector
{
	OAKeyValueObservingListener* listener = [OAKeyValueObservingListener new];
	listener.target = self;
	listener.observer = observer;
	listener.keyPath = keyPath;
	listener.selectorWithoutArguments = selector;
	[[OAKVONotificationCenter defaultCenter] addListener:listener];
}

- (void)addObserver:(id)observer
         forKeyPath:(NSString*)keyPath
selectorWithNewValue:(SEL)selector
{
	OAKeyValueObservingListener* listener = [OAKeyValueObservingListener new];
	listener.target = self;
	listener.observer = observer;
	listener.keyPath = keyPath;
	listener.selectorWithNewValue = selector;
	[[OAKVONotificationCenter defaultCenter] addListener:listener];
}

- (void)addObserver:(id)observer
         forKeyPath:(NSString*)keyPath
           selector:(SEL)selector
{
	[self addObserver:observer
		   forKeyPath:keyPath
			 selector:selector
			 userInfo:nil
			  options:NSKeyValueObservingOptionNew];
}

- (void)addObserver:(id)observer
         forKeyPath:(NSString*)keyPath
           selector:(SEL)selector
           userInfo:(id)userInfo
            options:(NSKeyValueObservingOptions)options
{
	OAKeyValueObservingListener* listener = [OAKeyValueObservingListener new];
	listener.target = self;
	listener.observer = observer;
	listener.keyPath = keyPath;
	listener.selector = selector;
	listener.userInfo = userInfo;
	listener.options = options;
	[[OAKVONotificationCenter defaultCenter] addListener:listener];
}

- (void)removeObserver:(id)observer keyPath:(NSString*)keyPath selector:(SEL)selector
{
	[[OAKVONotificationCenter defaultCenter] removeObserver:observer
													 target:self
													keyPath:keyPath
												   selector:selector];
}

@end
