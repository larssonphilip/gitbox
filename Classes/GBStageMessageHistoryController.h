
@class GBRepository;

@interface GBStageMessageHistoryController : NSObject

@property(nonatomic, strong) GBRepository* repository;
@property(nonatomic, strong) NSTextView* textView;

// Return messages from commits including this email
@property(nonatomic, copy)   NSString* email;

- (NSString*) nextMessage;
- (NSString*) previousMessage;

@end
