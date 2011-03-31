#import <Foundation/Foundation.h>
#include <CoreServices/CoreServices.h>

extern NSString* const OAFSEventStreamNotification;

@interface OAFSEventStream : NSObject

@property(nonatomic, assign) dispatch_queue_t dispatchQueue;
@property(nonatomic, assign) NSTimeInterval latency;
@property(nonatomic, assign) BOOL watchRoot;
@property(nonatomic, assign) BOOL ignoreSelf;
@property(nonatomic, assign, getter=isEnabled) BOOL enabled;

@property(nonatomic, readonly) NSArray* paths;

- (void) addPath:(NSString*)aPath;
- (void) removePath:(NSString*)aPath;

- (void) flushEvents;

@end
