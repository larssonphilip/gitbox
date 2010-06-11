// Used in projects (time revisited):
// - oleganza/gitbox (22.05.2010)

@interface NSString (OAStringHelpers)

- (NSString*) uniqueStringForStrings:(id)list appendingFormat:(NSString*)format;
- (NSString*) uniqueStringForStrings:(id)list;

- (BOOL) isEmptyString;

- (NSString*) stringWithFirstLetterCapitalized;

@end


@interface NSMutableString (OAStringHelpers)

- (void) replaceOccurrencesOfString:(NSString*)string1 withString:(NSString*)string2;

@end