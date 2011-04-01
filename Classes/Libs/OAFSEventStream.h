#import <Foundation/Foundation.h>
#include <CoreServices/CoreServices.h>

extern NSString* const OAFSEventStreamNotification;

@interface OAFSEvent : NSObject
@property(nonatomic, copy) NSString* path;
@property(nonatomic, assign) FSEventStreamEventFlags flags;
@property(nonatomic, assign) FSEventStreamEventId eventId;
+ (OAFSEvent*) eventWithPath:(NSString*)aPath flags:(FSEventStreamEventFlags)flags eventId:(FSEventStreamEventId)eventId;
- (NSString*) flagsDescription;
- (BOOL) containedInFolder:(NSString*)aPath;
@end


@interface OAFSEventStream : NSObject

@property(nonatomic, assign) NSTimeInterval latency;
@property(nonatomic, assign) BOOL watchRoot;
@property(nonatomic, assign) BOOL ignoreSelf;
@property(nonatomic, assign, getter=isEnabled) BOOL enabled;

@property(nonatomic, readonly) NSArray* paths;

// You can add a path multiple times, but should always balance additions with removals.
- (void) addPath:(NSString*)aPath;
- (void) removePath:(NSString*)aPath;

- (void) flushEvents;

@end
