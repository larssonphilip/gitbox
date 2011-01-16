// Used in projects (time revisited):
// - oleganza/gitbox (22.05.2010)

@interface NSData (OADataHelpers)

- (NSString*) UTF8String;

// Replaces all broken sequences by � character and returns NSData with valid UTF-8 bytes.
- (NSData*) dataByHealingUTF8Stream;

@end
