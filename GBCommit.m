#import "GBModels.h"
#import "GBCommittedChangesTask.h"

#import "NSData+OADataHelpers.h"
#import "NSString+OAGitHelpers.h"

#import "GBCommitCell.h"
#import "GBStageCell.h"

#import "NSAttributedString+OAAttributedStringHelpers.h"

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

@synthesize syncStatus;
@synthesize repository;

- (void) dealloc
{
  self.commitId = nil;
  self.treeId = nil;
  self.authorName = nil;
  self.authorEmail = nil;
  self.committerName = nil;
  self.committerEmail = nil;
  self.date = nil;
  self.message = nil;
  self.parentIds = nil;
  self.changes = nil;
  
  [super dealloc];
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

- (Class) cellClass
{
  if ([self isStage])
  {
    return [GBStageCell class];
  }
  return [GBCommitCell class];
}

- (GBCommitCell*) cell
{
  GBCommitCell* cell = [[[self cellClass] new] autorelease];
  [cell setRepresentedObject:self];
  return cell;
}

- (id) valueForUndefinedKey:(NSString*)key
{
  NSLog(@"ERROR: GBCommit valueForUndefinedKey: %@", key);
  return nil;
}

- (BOOL) isEqual:(id)object
{
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
  return [NSString stringWithFormat:@"%@: %@", [[self commitId] substringToIndex:6], self.message];
}





#pragma mark Mutation


- (void) loadChangesWithBlock:(void(^)())block
{
  GBCommittedChangesTask* task = [GBCommittedChangesTask task];
  task.commit = self;
  task.repository = self.repository;
  [task launchWithBlock:^{
    self.changes = task.changes;
    block();
  }];
}


@end
