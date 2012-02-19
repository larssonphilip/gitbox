#import "OABlockOperations.h"
#import "OABlockTransaction.h"

@interface OABlockTransaction ()
@property(nonatomic, retain) void(^transactionPendingBlock)();
@end

@implementation OABlockTransaction {
	BOOL stageTransactionInProgress;
}

@synthesize transactionPendingBlock;

- (void) dealloc
{
	self.transactionPendingBlock = nil;
	[super dealloc];
}

- (void) begin:(void(^)())block
{
	if (!block) return;
	
	if (!stageTransactionInProgress)
	{
		stageTransactionInProgress = YES;
		block();
	}
	else
	{
		self.transactionPendingBlock = OABlockConcat(self.transactionPendingBlock, block);
	}
}

- (void) end
{
	stageTransactionInProgress = NO;
	void(^block)() = [[self.transactionPendingBlock copy] autorelease];
	self.transactionPendingBlock = nil;
	if (block) 
	{
		[self begin:block];
	}
}

- (void) clean
{
	self.transactionPendingBlock = nil;
}

@end
