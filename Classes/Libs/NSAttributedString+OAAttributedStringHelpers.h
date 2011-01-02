@interface NSAttributedString (OAAttributedStringHelpers)

+ (id)attributedStringWithString:(NSString *)str;
+ (id)attributedStringWithString:(NSString *)str attributes:(NSDictionary *)attrs;

@end


@interface NSMutableAttributedString (OAAttributedStringHelpers)

- (void) updateAttribute:(NSString*)attributeKey forSubstring:(NSString*)substring withBlock:(id(^)(id))aBlock;
- (void) updateAttribute:(NSString*)attributeKey inRange:(NSRange)range withBlock:(id(^)(id))aBlock;
- (void) addAttributes:(NSDictionary*)attributesDict toSubstring:(NSString*)substring;
- (void) removeAttribute:(NSString*)attributeKey fromSubstring:(NSString*)substring;

@end
