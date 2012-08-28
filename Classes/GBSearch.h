// Object which incapsulates a process of searching in the history
@class GBSearchQuery;
@class GBRepository;

@interface GBSearch : NSObject
@property(nonatomic, strong) GBSearchQuery* query;
@property(nonatomic, strong) GBRepository* repository;
@property(nonatomic, strong, readonly) NSMutableArray* commits;
@property(nonatomic, strong) id searchCache; // this is opaque object which can be passed from the previous search instance to a new one.
@property(nonatomic, unsafe_unretained) id target;
@property(nonatomic, assign) SEL action;
+ (GBSearch*) searchWithQuery:(GBSearchQuery*)query repository:(GBRepository*)repo target:(id)target action:(SEL)action;
- (void) start;
- (void) cancel; // stops searching and immediately stops any notifications
- (BOOL) isRunning;
@end
