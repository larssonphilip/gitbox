@interface NSAttributedString (OAAttributedStringHelpers)

+ (id)attributedStringWithString:(NSString *)str;
+ (id)attributedStringWithString:(NSString *)str attributes:(NSDictionary *)attrs;

@end


@interface NSMutableAttributedString (OAAttributedStringHelpers)

- (void) updateAttribute:(NSString*)key forSubstring:(NSString*)substring withBlock:(id(^)(id))aBlock;

@end
