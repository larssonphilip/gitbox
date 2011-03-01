#import <Foundation/Foundation.h>

// Simple API for storing trees (not graphs!) of objects in the user preferences.
// Focus is on the contents (subitems) rather than on object's properties because it fits well
// how the object initializes its subitems.

@protocol OAPropertyListRepresentation
- (id) OAContentsPropertyList;
- (void) OALoadContentsFromPropertyList:(id)plist;
@end

@interface NSObject (OAPropertyListRepresentation) <OAPropertyListRepresentation>

- (id) OAContentsPropertyList;
- (void) OALoadContentsFromPropertyList:(id)plist;

@end
