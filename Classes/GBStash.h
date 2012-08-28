#import <Foundation/Foundation.h>

@interface GBStash : NSObject

@property(nonatomic, copy) NSString* ref;
@property(nonatomic, strong) NSDate* date;
@property(nonatomic, copy) NSString* rawMessage;
@property(unsafe_unretained, nonatomic, readonly) NSString* message;
@property(unsafe_unretained, nonatomic, readonly) NSString* menuTitle;

+ (NSTimeInterval) oldStashesTreshold;
- (BOOL) isOldStash;

@end
