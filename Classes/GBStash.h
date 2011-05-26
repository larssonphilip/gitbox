#import <Foundation/Foundation.h>

@interface GBStash : NSObject

@property(nonatomic, copy) NSString* ref;
@property(nonatomic, retain) NSDate* date;
@property(nonatomic, copy) NSString* rawMessage;
@property(nonatomic, readonly) NSString* message;
@property(nonatomic, readonly) NSString* menuTitle;

+ (NSTimeInterval) oldStashesTreshold;
- (BOOL) isOldStash;

@end
