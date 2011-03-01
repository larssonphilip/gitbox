#import "OAPropertyListRepresentation.h"

@implementation NSObject (OAPropertyListRepresentation)

- (id) OAContentsPropertyList
{
  return [NSArray array];
}

- (void) OALoadContentsFromPropertyList:(id)plist
{
}

@end
