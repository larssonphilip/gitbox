#import "OABlockTable.h"
#import "OABlockOperations.h"

@interface OABlockTable ()
@property(nonatomic, retain) NSMutableDictionary* table;
@property(nonatomic, retain) NSMutableDictionary* tableCounters;
@end

@implementation OABlockTable

@synthesize table;
@synthesize tableCounters;

- (id)init
{
	if ((self = [super init]))
	{
		self.table = [NSMutableDictionary dictionary];
		self.tableCounters = [NSMutableDictionary dictionary];
	}
	return self;
}

- (void)dealloc
{
	self.table = nil;
	self.tableCounters = nil;
	[super dealloc];
}

- (BOOL) containsBlockForName:(NSString*)aName
{
	return !![self.table objectForKey:aName];
}

- (void) addBlock:(void(^)())aBlock forName:(NSString*)aName
{
	if (!aBlock) aBlock = ^{}; // put an empty block to mark associated task as running
	[self.table setObject:OABlockConcat([self.table objectForKey:aName], aBlock) forKey:aName];
	int c = [[self.tableCounters objectForKey:aName] intValue];
	c++;
	[self.tableCounters setObject:[NSNumber numberWithInt:c] forKey:aName];
}

- (void) callBlockForName:(NSString*)aName
{
	void(^aBlock)() = [[self.table objectForKey:aName] retain];
	[self.table removeObjectForKey:aName]; // it is important to remove the block before it is called
	[self.tableCounters removeObjectForKey:aName];
	if (aBlock) aBlock();
	[aBlock release];
}

- (void) addBlock:(void(^)())aBlock forName:(NSString*)aName proceedIfClear:(void(^)())continuation
{
	if ([self containsBlockForName:aName])
	{
		[self addBlock:aBlock forName:aName];
	}
	else
	{
		[self addBlock:aBlock forName:aName];
		if (continuation) continuation();
	}  
}

- (NSString*) description
{
	return [NSString stringWithFormat:@"<OABlockTable:%p blocks: %@>", self, self.tableCounters];
}




// Returns a global shared blocktable.
+ (OABlockTable*) sharedTable
{
	static OABlockTable* volatile OABlockTableSharedInstance = nil;
	static dispatch_once_t OABlockTableSharedInstanceOnce = 0;
	
	dispatch_once( &OABlockTableSharedInstanceOnce, ^{ OABlockTableSharedInstance = [[self alloc] init]; });
	return OABlockTableSharedInstance;
}

+ (BOOL) containsBlockForName:(NSString*)aName
{
	return [[self sharedTable] containsBlockForName:aName];
}

+ (void) addBlock:(void(^)())aBlock forName:(NSString*)aName
{
	return [[self sharedTable] addBlock:aBlock forName:aName];
}

+ (void) callBlockForName:(NSString*)aName
{
	return [[self sharedTable] callBlockForName:aName];
}

+ (void) addBlock:(void(^)())aBlock forName:(NSString*)aName proceedIfClear:(void(^)())continuation
{
	return [[self sharedTable] addBlock:aBlock forName:aName proceedIfClear:continuation];  
}

+ (NSString*) description
{
	return [NSString stringWithFormat:@"<OABlockTable:%p (shared) names: %@>", [[self sharedTable].table allKeys]];
}

@end
