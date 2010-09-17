#include <CoreServices/CoreServices.h>

@interface OAFSEventStream : NSObject
{
}

@property(retain) NSArray* paths;

- (void) start;
- (void) stop;

- (void) addPath:(NSString*)aPath withBlock:(void(^)())block;
- (void) removePath:(NSString*)aPath;

@end
