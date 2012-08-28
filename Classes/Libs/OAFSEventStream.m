#import "OAFSEventStream.h"

NSString* const OAFSEventStreamNotification = @"OAFSEventStreamNotification";

@interface OAFSEventStream ()
@property(nonatomic, strong) NSCountedSet* pathsBag;
@property(nonatomic, assign) BOOL started;
@property(nonatomic, assign) FSEventStreamRef streamRef;
- (void) update;
- (void) start;
- (void) stop;
- (void) didReceiveEvents:(NSArray*)events;
@end


void OAFSEventStreamCallback( ConstFSEventStreamRef streamRef,
							 void* info,
							 size_t numEvents,
							 void* eventPaths, // assuming CFArray/NSArray because of kFSEventStreamCreateFlagUseCFTypes
							 const FSEventStreamEventFlags eventFlags[],
							 const FSEventStreamEventId eventIds[])
{
	OAFSEventStream* owner = (__bridge OAFSEventStream*)info;
	NSMutableArray* events = [NSMutableArray arrayWithCapacity:numEvents];
	
	for (NSUInteger i = 0; i < numEvents; i++)
	{
		NSString* eventPath = [[(__bridge NSArray*)eventPaths objectAtIndex:i] stringByStandardizingPath];
		[events addObject:[OAFSEvent eventWithPath:eventPath flags:eventFlags[i] eventId:eventIds[i]]];
	}
	
	[owner didReceiveEvents:events];
}

@implementation OAFSEventStream

@synthesize streamRef;
@synthesize latency;
@synthesize watchRoot;
@synthesize ignoreSelf;
@synthesize pathsBag;
@synthesize started;
@synthesize enabled;
@dynamic paths;

- (void)dealloc
{
	[self stop];
}

- (id)init
{
	if ((self = [super init]))
	{
		self.pathsBag = [NSCountedSet set];
		self.latency = 0.1;
		self.watchRoot = YES;
	}
	return self;
}

- (NSArray*) paths
{
	return [[self.pathsBag allObjects] sortedArrayUsingSelector:@selector(self)];
}

- (void) addPath:(NSString*)aPath
{
	if (!aPath) return;
	[self.pathsBag addObject:aPath];
	[self update];
}

- (void) removePath:(NSString*)aPath
{
	if (!aPath) return;
	[self.pathsBag removeObject:aPath];
	[self update];
}

- (void) setEnabled:(BOOL)flag
{
	if (enabled == flag) return;
	enabled = flag;
	[self update];
}

- (void) flushEvents
{
	if (streamRef) FSEventStreamFlushSync(streamRef);
}

- (NSString*) description
{
	return [NSString stringWithFormat:@"<OAFSEventStream:%p paths=%@ latency=%f %@%@%@>", self, self.pathsBag, self.latency, 
			(self.enabled ? @"enabled" : @"disabled"),
			(self.watchRoot ? @", watchRoot" : @""),
			(self.ignoreSelf ? @", ignoreSelf" : @"")
			];
}




#pragma mark Private


- (void) update
{
	[self stop];
	if ([self isEnabled])
	{
		[self start];
	}
}

- (void) start
{
	if (!self.pathsBag) self.pathsBag = [NSCountedSet set];
	CFArrayRef pathsToWatch = (__bridge CFArrayRef)[self.pathsBag allObjects];
	
	if (!pathsToWatch || CFArrayGetCount(pathsToWatch) <= 0) return;
	
	FSEventStreamContext streamContext;
	
	streamContext.version = 0;
	streamContext.info = (__bridge void*)self; // passing self is the only reason to create this struct here
	streamContext.retain = NULL;
	streamContext.release = NULL;
	streamContext.copyDescription = NULL;
	
	CFAbsoluteTime aLatency = MAX(0.01, self.latency);
	
	self.streamRef = FSEventStreamCreate(NULL,
										 OAFSEventStreamCallback,
										 &streamContext,
										 pathsToWatch,
										 kFSEventStreamEventIdSinceNow, /* Or a previous event ID */
										 aLatency,
										 kFSEventStreamCreateFlagUseCFTypes|
										 //kFSEventStreamCreateFlagNoDefer|  // do not set: we want to defer and group all events within latency interval
										 (self.ignoreSelf ? kFSEventStreamCreateFlagIgnoreSelf : 0) |
										 (self.watchRoot ? kFSEventStreamCreateFlagWatchRoot : 0)
										 );
	
	FSEventStreamSetDispatchQueue(streamRef, dispatch_get_main_queue());
	FSEventStreamStart(streamRef);
}

- (void) stop
{
	if (streamRef)
	{
		FSEventStreamStop(streamRef);
		FSEventStreamInvalidate(streamRef);
		FSEventStreamRelease(streamRef);
		streamRef = NULL;
	}
}

- (void) didReceiveEvents:(NSArray*)events
{
	//NSLog(@"OAFSEventStream didReceiveEvents: %@", events);
	
	if (!events) return;
	
	NSNotification* aNotification = [NSNotification notificationWithName:OAFSEventStreamNotification
																  object:self
																userInfo:[NSDictionary dictionaryWithObject:events forKey:@"events"]];
	[[NSNotificationCenter defaultCenter] postNotification:aNotification];
}

@end





@implementation OAFSEvent
@synthesize path;
@synthesize flags;
@synthesize eventId;


+ (OAFSEvent*) eventWithPath:(NSString*)aPath flags:(FSEventStreamEventFlags)flags eventId:(FSEventStreamEventId)eventId
{
	OAFSEvent* event = [[self alloc] init];
	event.path = aPath;
	event.flags = flags;
	event.eventId = eventId;
	return event;
}

- (NSString*) flagsDescription
{
	NSMutableArray* flagNames = [NSMutableArray array];
	FSEventStreamEventFlags eventFlags = self.flags;
	if (eventFlags == kFSEventStreamEventFlagNone)
	{
		[flagNames addObject: @"None"];
	}
	else
	{
		if (eventFlags & kFSEventStreamEventFlagMustScanSubDirs) [flagNames addObject: @"MustScanSubDirs"];
		if (eventFlags & kFSEventStreamEventFlagUserDropped)     [flagNames addObject: @"UserDropped"];
		if (eventFlags & kFSEventStreamEventFlagKernelDropped)   [flagNames addObject: @"KernelDropped"];
		if (eventFlags & kFSEventStreamEventFlagEventIdsWrapped) [flagNames addObject: @"EventIdsWrapped"];
		if (eventFlags & kFSEventStreamEventFlagHistoryDone)     [flagNames addObject: @"HistoryDone"];
		if (eventFlags & kFSEventStreamEventFlagRootChanged)     [flagNames addObject: @"RootChanged"];
		if (eventFlags & kFSEventStreamEventFlagMount)           [flagNames addObject: @"Mount"];
		if (eventFlags & kFSEventStreamEventFlagUnmount)         [flagNames addObject: @"Unmount"];
	}
	return [flagNames componentsJoinedByString:@", "];
}

- (BOOL) containedInFolder:(NSString*)aPath
{
	// 3 cases:
	// /a/b/c/d  vs. /a/b/e => NO
	// /a/bar/c/d  vs. /a/b => NO
	// /a/b/c/d  vs. /a/b/c => YES
	
	if (!self.path) return NO;
	if (!aPath) return NO;
	if ([aPath isEqualToString:@""]) return NO;
	
	if ([aPath isEqualToString:self.path]) return YES;
	
	NSString* commonPrefix = [self.path commonPrefixWithString:aPath options:0];
	if (![commonPrefix isEqualToString:aPath]) return NO;
	
	// Verify this case: /a/bar/c/d vs. /a/b => NO
	
	NSUInteger prefixLength = [commonPrefix length];
	if ([self.path length] > prefixLength)
	{
		return ([[self.path substringWithRange:NSMakeRange(prefixLength, 1)] isEqualToString:@"/"]);
	}
	return ([[self.path substringWithRange:NSMakeRange(prefixLength-1, 1)] isEqualToString:@"/"]);
}

- (NSString*) description
{
	return [NSString stringWithFormat:@"<OAFSEvent %llu %@ flags: %@>", self.eventId, self.path, [self flagsDescription]];
}
@end

