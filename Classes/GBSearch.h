// Object which incapsulates a process of searching in the history
@class GBSearchQuery;
@class GBRepository;

@interface GBSearch : NSObject
@property(nonatomic, retain) GBSearchQuery* query;
@property(nonatomic, retain) GBRepository* repository;
@property(nonatomic, retain, readonly) NSMutableArray* commits;
@property(nonatomic, retain) id searchCache; // this is opaque object which can be passed from the previous search instance to a new one.
@property(nonatomic, assign) id target;
@property(nonatomic, assign) SEL action;
+ (GBSearch*) searchWithQuery:(GBSearchQuery*)query repository:(GBRepository*)repo target:(id)target action:(SEL)action;
- (void) start;
- (void) cancel; // stops searching and immediately stops any notifications
- (BOOL) isRunning;
@end
