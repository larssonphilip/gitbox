#import <Foundation/Foundation.h>

// Returns a new block which calls first and second blocks
void(^OABlockConcat(void(^block1)(), void(^block2)()))();