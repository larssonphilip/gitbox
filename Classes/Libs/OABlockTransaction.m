#import "OABlockOperations.h"
#import "OABlockTransaction.h"

@interface OABlockTransaction ()
@property(nonatomic, strong) void(^transactionPendingBlock)();
@end

@implementation OABlockTransaction {
	BOOL stageTransactionInProgress;
}

@synthesize transactionPendingBlock;


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
	void(^block)() = [self.transactionPendingBlock copy];
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
