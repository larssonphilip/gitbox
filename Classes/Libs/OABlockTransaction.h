#import <Foundation/Foundation.h>

@interface OABlockTransaction : NSObject

- (void) begin:(void(^)())block;
- (void) end;
- (void) clean;

@end
