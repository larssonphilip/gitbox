#import "GBCommit.h"
#import "GBRepository.h"
#import "GBCommittedChangesTask.h"
#import "GBGitConfig.h"
#import "GBSearchQuery.h"

#import "NSData+OADataHelpers.h"
#import "NSString+OAGitHelpers.h"
#import "NSAttributedString+OAAttributedStringHelpers.h"
#import "NSObject+OASelectorNotifications.h"
#import "OABlockTable.h"

@interface GBCommit ()
@property(nonatomic, assign) BOOL matchesQuery;
- (void) updateSearchAttributes;
@end


@implementation GBCommit

@synthesize commitId;
@synthesize treeId;
@synthesize authorName;
@synthesize authorEmail;
@synthesize committerName;
@synthesize committerEmail;
@synthesize date;
@synthesize message;
@synthesize parentIds;
@synthesize changes;
@synthesize diffPaths;
@synthesize diffLines;
@synthesize rawTimestamp;
@synthesize searchQuery;
@synthesize matchesQuery;
@synthesize foundRangesByProperties;

@synthesize syncStatus;
@synthesize repository;

- (void) dealloc
{
  [commitId release]; commitId = nil;
  [treeId release]; treeId = nil;
  [authorName release]; authorName = nil;
  [authorEmail release]; authorEmail = nil;
  [committerName release]; committerName = nil;
  [committerEmail release]; committerEmail = nil;
  [date release]; date = nil;
  [message release]; message = nil;
  [parentIds release]; parentIds = nil;
  [changes release]; changes = nil;
  [diffPaths release]; diffPaths = nil;
  [diffLines release]; diffLines = nil;
  [searchQuery release]; searchQuery = nil;
  [foundRangesByProperties release]; foundRangesByProperties = nil;
  [super dealloc];
}

- (NSString*) description
{
  return [NSString stringWithFormat:@"<GBCommit:%p %@ %@: %@>", self, commitId, authorName, ([message length] > 20) ? [message substringToIndex:20] : message];
}

+ (NSColor*) searchHighlightColor
{
  static NSColor* c = nil;
  if (!c) c = [[NSColor colorWithCalibratedRed:1.0 green:1.0 blue:0.33 alpha:0.6] retain];
  return c;
}



#pragma mark Interrogation


- (BOOL) isStage
{
  return NO;
}

- (GBStage*) asStage
{
  return nil;
}

- (BOOL) isMerge
{
  return self.parentIds && [self.parentIds count] > 1;
}

- (NSString*) longAuthorLine
{
  // TODO: display committer in parentheses if != author
  return [NSString stringWithFormat:@"%@ <%@>", self.authorName, self.authorEmail];
}

- (id) valueForUndefinedKey:(NSString*)key
{
  NSLog(@"ERROR: GBCommit valueForUndefinedKey: %@", key);
  return nil;
}

- (BOOL) isEqual:(id)object
{
  if (self == object) return YES;
  
  if ([[object class] isEqual:[self class]])
  {
    return [[object commitId] isEqualToString:self.commitId];
  }
  return NO;
}

- (NSString*) fullDateString
{
  static NSDateFormatter* fullDateFormatter = nil;
  if (!fullDateFormatter)
  {
    fullDateFormatter = [[NSDateFormatter alloc] init];
    [fullDateFormatter setDateStyle:NSDateFormatterLongStyle];
    [fullDateFormatter setTimeStyle:NSDateFormatterLongStyle];
  }
  return [fullDateFormatter stringFromDate:self.date];
}

- (NSString*) tooltipMessage
{
  return [NSString stringWithFormat:@"%@: %@", [self.commitId substringToIndex:6], self.message];
}

- (NSString*) subject
{
  if (!self.message) return nil;
  NSRange range = [self.message rangeOfString:@"\n"];
  if (range.length < 1) return self.message;
  return [self.message substringToIndex:range.location];
}

- (NSString*) subjectForReply
{
  return [NSString stringWithFormat:@"%@ [commit %@]", [self subject], [self.commitId substringToIndex:8]];
}



#pragma mark Search


- (void) setSearchQuery:(GBSearchQuery *)aQuery
{
  if (searchQuery == aQuery) return;
  
  [searchQuery release];
  searchQuery = [aQuery retain];
  
  [self updateSearchAttributes];
}

- (void) updateSearchAttributes
{
  if (!self.searchQuery)
  {
    self.foundRangesByProperties = nil;
    self.matchesQuery = NO;
    return;
  }
  GBSearchQuery* q = self.searchQuery;
  
  NSMutableDictionary* rangesByProps = [NSMutableDictionary dictionary];
  
  BOOL(^addTokenRangeForStringWithName)(id, NSString*, NSString*) = ^(id token, NSString* string, NSString* name) {
    NSRange range = [q rangeOfToken:token inString:string];
    if (range.length > 0)
    {
      NSMutableArray* ranges = [rangesByProps objectForKey:name];
      if (!ranges)
      {
        ranges = [NSMutableArray array];
        [rangesByProps setObject:ranges forKey:name];
      }
      
      // Note: here we find only a single occurence for speed. 
      // When highlighting particular commit, we'll find all occurences.
      
      [ranges addObject:[NSValue valueWithRange:range]];
      return YES;
    }
    else
    {
      return NO;
    }
  };
  
  BOOL allTokensMatched = [q matchTokens:^(id token) {
    
    BOOL tokenMatched = NO;
    NSRange range = NSMakeRange(NSNotFound, 0);
    
    range = [q rangeOfToken:token inString:self.commitId];
    if (range.length > 0 && range.location == 0)
    {
      tokenMatched = YES;
      [rangesByProps setObject:[NSValue valueWithRange:range] forKey:@"commitId"];
    }
        
    tokenMatched = tokenMatched || addTokenRangeForStringWithName(token, self.authorName, @"authorName");
    tokenMatched = tokenMatched || addTokenRangeForStringWithName(token, self.authorEmail, @"authorEmail");
    tokenMatched = tokenMatched || addTokenRangeForStringWithName(token, self.committerName, @"committerName");
    tokenMatched = tokenMatched || addTokenRangeForStringWithName(token, self.committerEmail, @"committerEmail");
    tokenMatched = tokenMatched || addTokenRangeForStringWithName(token, self.message, @"message");
    
    tokenMatched = tokenMatched || addTokenRangeForStringWithName(token, self.diffPaths, @"diffPaths");
    tokenMatched = tokenMatched || addTokenRangeForStringWithName(token, self.diffLines, @"diffLines");
    
    return tokenMatched;
  }];
  
  self.foundRangesByProperties = rangesByProps;
  self.matchesQuery = allTokensMatched;
}




#pragma mark Mutation




- (void) loadChangesIfNeededWithBlock:(void(^)())block
{
  if (self.changes && [self.changes count] > 0)
  {
    if (block) block();
    return;
  }
  
  [self loadChangesWithBlock:block];
}

- (void) loadChangesWithBlock:(void(^)())block
{
  block = [[block copy] autorelease];
  
  if (!self.commitId)
  {
    if (block) block();
    return;
  }
  NSString* name = [NSString stringWithFormat:@"GBCommit loadChangesWithBlock: %@", self.commitId];
  [OABlockTable addBlock:block forName:name proceedIfClear:^{
    [[GBGitConfig userConfig] ensureDisabledPathQuoting:^{
      GBCommittedChangesTask* task = [GBCommittedChangesTask task];
      task.commit = self;
      task.repository = self.repository;
      [task launchWithBlock:^{
        NSArray* theChanges = [task.changes sortedArrayUsingComparator:^(GBChange* a,GBChange* b){
          return [[[a fileURL] path] localizedCaseInsensitiveCompare:[[b fileURL] path]];
        }];
        self.changes = theChanges;
        [self notifyWithSelector:@selector(commitDidUpdateChanges:)];
        [OABlockTable callBlockForName:name];
      }];
    }];
  }];
}


@end
