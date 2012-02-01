#import <Foundation/Foundation.h>

// Returns a new block which calls first and second blocks
void(^OABlockConcat(void(^block1)(), void(^block2)()))();

void OADispatchDelayed(NSTimeInterval delayInSeconds, dispatch_block_t block);
