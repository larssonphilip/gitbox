
@class GBRepository;

@interface GBStageMessageHistoryController : NSObject

@property(nonatomic, retain) GBRepository* repository;
@property(nonatomic, retain) NSTextView* textView;

// Return messages from commits including this email
@property(nonatomic, copy)   NSString* email;

- (NSString*) nextMessage;
- (NSString*) previousMessage;

@end
