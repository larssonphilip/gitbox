// Used in projects (time revisited):
// - oleganza/gitbox (22.05.2010)

@interface NSString (OAStringHelpers)

- (NSString*) uniqueStringForStrings:(id)list appendingFormat:(NSString*)format;
- (NSString*) uniqueStringForStrings:(id)list;

- (BOOL) isEmptyString;

@end
