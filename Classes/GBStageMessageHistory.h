
@class GBRepository;

@interface GBStageMessageHistory : NSObject

@property(nonatomic, retain) GBRepository* repository;
@property(nonatomic, retain) NSTextView* textView;
@property(nonatomic, copy)   NSString* email;

- (NSString*) nextMessage;
- (NSString*) previousMessage;

@end
