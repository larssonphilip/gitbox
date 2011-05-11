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
@synthesize rawTimestamp;
@synthesize searchQuery;
@synthesize matchesQuery;

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
  [searchQuery release]; searchQuery = nil;
  [super dealloc];
}

- (NSString*) description
{
  return [NSString stringWithFormat:@"<GBCommit:%p %@ %@: %@>", self, commitId, authorName, ([message length] > 20) ? [message substringToIndex:20] : message];
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
    self.matchesQuery = NO;
    return;
  }
  GBSearchQuery* q = self.searchQuery;
  BOOL matches = NO;
  matches = matches || [q matchesString:self.commitId];
  matches = matches || [q matchesString:self.treeId];
  matches = matches || [q matchesString:self.authorName];
  matches = matches || [q matchesString:self.authorEmail];
  matches = matches || [q matchesString:self.committerName];
  matches = matches || [q matchesString:self.committerEmail];
  matches = matches || [q matchesString:self.message];
  
  // TODO: collect precise ranges for each property
  // TODO: match patch data as well
  
  self.matchesQuery = matches;
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
