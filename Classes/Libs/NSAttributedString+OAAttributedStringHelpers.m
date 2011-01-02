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
  
  if (!newAttribute)
  {
    [self removeAttribute:attributeKey range:range];
  }
  else
  {
    [self addAttribute:attributeKey value:newAttribute range:range];
  }
}

- (void) addAttributes:(NSDictionary*)attributesDict toSubstring:(NSString*)substring
{
  if (!substring) return;
  if (!attributesDict) return;
  
  NSRange range = [[self string] rangeOfString:substring];
  if (range.length <= 0) return;
  
  [self addAttributes:attributesDict range:range];
}

- (void) removeAttribute:(NSString*)attributeKey fromSubstring:(NSString*)substring
{
  if (!substring) return;
  if (!attributeKey) return;
  
  NSRange range = [[self string] rangeOfString:substring];
  if (range.length <= 0) return;
  
  [self removeAttribute:attributeKey range:range];
}

@end
