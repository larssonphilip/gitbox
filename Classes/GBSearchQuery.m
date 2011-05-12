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

- (BOOL) matchTokens:(BOOL(^)(id token))block
{
  if (!self.tokens || [self.tokens count] <= 0) return NO;
  
  for (id token in self.tokens)
  {
    if (!block(token)) return NO;
  }
  return YES; // all tokens matched.
}

// Returns YES if string contains all of the tokens of the receiver.
- (BOOL) matchesString:(NSString*)string
{
  if (!string) return NO;
  return [self matchTokens:^(id token){
    NSRange range = GBSearchQueryRangeForTokenInString(token, string);
    return (BOOL)(range.length > 0);
  }];
}

// Returns a range of otken occurence in string.
- (NSRange) rangeOfToken:(id)token inString:(NSString*)string
{
  return GBSearchQueryRangeForTokenInString(token, string);
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
