#import <Foundation/Foundation.h>

@interface GBVersionComparator : NSObject
+ (GBVersionComparator *)defaultComparator;
- (NSComparisonResult)compareVersion:(NSString *)versionA toVersion:(NSString *)versionB;
@end
