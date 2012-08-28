#import "NSAttributedString+OAAttributedStringHelpers.h"

@implementation NSAttributedString (OAAttributedStringHelpers)

+ (id)attributedStringWithString:(NSString *)str
{
  return [[self alloc] initWithString:str];
}

+ (id)attributedStringWithString:(NSString *)str attributes:(NSDictionary *)attributes
{
  return [[self alloc] initWithString:str attributes:attributes];
}

+ (NSMutableAttributedString*)attributedStringWithString:(NSString *)str attributes:(NSDictionary *)attributes highlightedRanges:(NSArray*)ranges highlightColor:(NSColor*)highlightColor
{
  NSMutableAttributedString* s = [[NSMutableAttributedString alloc] initWithString:str];
  
  [s beginEditing];
  [s addAttributes:attributes range:NSMakeRange(0, [str length])];
  [s endEditing];
  
  if (!highlightColor) return s;
  
  if (ranges && [ranges isKindOfClass:[NSValue class]]) // a single range instead of array, wrap it with an array
  {
    ranges = [NSArray arrayWithObject:ranges];
  }
  
  [s beginEditing];
  for (NSValue* rangeValue in ranges)
  {
    NSRange range = [rangeValue rangeValue];
    if (range.location != NSNotFound)
    {
      [s addAttribute:NSBackgroundColorAttributeName value:highlightColor range:range];
    }
  }
  [s endEditing];
  
  return s;
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

- (void) addAttribute:(NSString*)attributeKey value:(id)value substring:(NSString*)substring
{
  if (!substring) return;
  if (!attributeKey) return;
  
  NSRange range = [[self string] rangeOfString:substring];
  if (range.length <= 0) return;
  
  [self addAttribute:attributeKey value:value range:range];  
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
