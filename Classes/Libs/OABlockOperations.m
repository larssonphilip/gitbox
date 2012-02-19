#import "OABlockOperations.h"

void(^OABlockConcat(void(^block1)(), void(^block2)()))()
{
	block1 = [[block1 copy] autorelease];
	block2 = [[block2 copy] autorelease];
	
	if (!block1) return block2;
	if (!block2) return block1;
	
	void(^block3)() = ^{
		block1();
		block2();
	};
	
	return [[block3 copy] autorelease];
}

void OADispatchDelayed(NSTimeInterval delayInSeconds, dispatch_block_t block)
{
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
	dispatch_after(popTime, dispatch_get_current_queue(), block);
}
