#import "GBSearchQuery.h"

NSRange GBSearchQueryRangeForTokenInString(id token, NSString* string);

@interface GBSearchQuery ()
@property(nonatomic, copy, readwrite) NSString* sourceString;
@property(nonatomic, retain) NSArray* tokens;
- (NSArray*) tokensForString:(NSString*)str;
@end

@implementation GBSearchQuery

@synthesize sourceString;
@synthesize tokens;

- (void) dealloc
{
  [sourceString release]; sourceString = nil;
  [tokens release]; tokens = nil;
  [super dealloc];
}

+ (GBSearchQuery*) queryWithString:(NSString*)str
{
  GBSearchQuery* q = [[[self alloc] init] autorelease];
  q.sourceString = str;
  return q;
}

- (NSString*) description
{
  return [NSString stringWithFormat:@"<GBSearchQuery:%p %@>", self, self.sourceString];
}

// Returns YES if string contains one of the tokens of the receiver.
- (BOOL) matchesString:(NSString*)string
{
  if (!string) return NO;
  if (!self.tokens) return NO;
  
  // FIXME: this code needs refactoring: we should not try to find all of the tokens in the string.
  
  for (id token in self.tokens)
  {
    NSRange range = GBSearchQueryRangeForTokenInString(token, string);
    if (range.length <= 0) return NO;
  }
  
  return YES;
}


// Returns an array of ranges (wrapped in NSValue objects) of the occurences of the query in a given string.
- (NSArray*) rangesInString:(NSString*)string
{
  if (!string) return [NSArray array];
  NSMutableArray* ranges = [NSMutableArray array];
  for (id token in self.tokens)
  {
    NSRange range = GBSearchQueryRangeForTokenInString(token, string);
    if (range.length > 0)
    {
      [ranges addObject:[NSValue valueWithRange:range]];
    }
  }
  return ranges;
}



#pragma mark Private


- (void) setSourceString:(NSString *)str
{
  if (sourceString == str) return;
  
  [sourceString release];
  sourceString = [str retain];
  
  self.tokens = [self tokensForString:sourceString];
}

- (NSArray*) tokensForString:(NSString*)str
{
  // TODO: parse quoted sequences as a single token
  // TODO: use GBSearchQueryToken object to wrap tokens and case sensitivity (quoted sequences should be case-sensitive, others - not)
  return [str componentsSeparatedByString:@" "];
}


@end

NSRange GBSearchQueryRangeForTokenInString(id token, NSString* string)
{
  // TODO: change string token to GBSearchQueryToken object
  if (!token || !string) return NSMakeRange(NSNotFound, 0);
  return [string rangeOfString:token options:NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch];
}
