@interface GBSearchQuery : NSObject

@property(nonatomic, copy, readonly) NSString* sourceString;

+ (GBSearchQuery*) queryWithString:(NSString*)str;

// Calls the block with each token. If all block calls return YES, the method returns YES. Otherwise NO.
- (BOOL) matchTokens:(BOOL(^)(id token))block;

// Returns YES if string contains all of the tokens of the receiver.
- (BOOL) matchesString:(NSString*)string;

// Returns a range of otken occurence in string.
- (NSRange) rangeOfToken:(id)token inString:(NSString*)string;

@end
