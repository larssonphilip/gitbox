#import <Foundation/Foundation.h>

// Simple API for storing trees (not graphs!) of objects in the user preferences.

@protocol OAPropertyListRepresentation
- (id) OAPropertyListRepresentation;
- (void) OALoadFromPropertyList:(id)plist;
@end

@interface NSObject (OAPropertyListRepresentation) <OAPropertyListRepresentation>

- (id) OAPropertyListRepresentation;
- (void) OALoadFromPropertyList:(id)plist;

@end

@interface NSArray (OAPropertyListRepresentation) <OAPropertyListRepresentation>

- (id) OAPropertyListRepresentation;
- (void) OALoadFromPropertyList:(id)plist;

@end

@interface NSDictionary (OAPropertyListRepresentation) <OAPropertyListRepresentation>

- (id) OAPropertyListRepresentation;
- (void) OALoadFromPropertyList:(id)plist;

@end
