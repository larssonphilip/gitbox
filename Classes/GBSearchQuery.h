@interface GBSearchQuery : NSObject

@property(nonatomic, copy, readonly) NSString* sourceString;

+ (GBSearchQuery*) queryWithString:(NSString*)str;

// Returns YES if string contains one of the tokens of the receiver.
- (BOOL) matchesString:(NSString*)string;

// Returns array of ranges (wrapped in NSValue objects) of the occurences of the query in a given string.
- (NSArray*) rangesInString:(NSString*)string;

@end
