#import "NSAttributedString+OAAttributedStringHelpers.h"

@implementation NSAttributedString (OAAttributedStringHelpers)

+ (id)attributedStringWithString:(NSString *)str
{
  return [[[self alloc] initWithString:str] autorelease];
}

+ (id)attributedStringWithString:(NSString *)str attributes:(NSDictionary *)attrs
{
  return [[[self alloc] initWithString:str attributes:attrs] autorelease];
}

@end


@implementation NSMutableAttributedString (OAAttributedStringHelpers)

- (void) updateAttribute:(NSString*)attributeKey forSubstring:(NSString*)substring withBlock:(id(^)(id))aBlock
{
  if (!substring) return;
  NSRange range = [[self string] rangeOfString:substring];
  [self updateAttribute:attributeKey inRange:range withBlock:aBlock];
}

- (void) updateAttribute:(NSString*)attributeKey inRange:(NSRange)range withBlock:(id(^)(id))aBlock
{
  if (!attributeKey) return;
  if (!aBlock) return;
  
  if (range.length <= 0) return;
  
  id attribute = [self attribute:attributeKey atIndex:range.location effectiveRange:NULL];
  id newAttribute = aBlock(attribute);
  
  if (!attribute) return;
  
  [self addAttribute:attributeKey value:newAttribute range:range];
}

@end
