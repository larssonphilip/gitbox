#import "GBModels.h"
#import "GBCommittedChangesTask.h"

#import "NSData+OADataHelpers.h"
#import "NSString+OAGitHelpers.h"

#import "GBCommitCell.h"
#import "GBMergeCommitCell.h"
#import "GBStageCell.h"

#import "NSAttributedString+OAAttributedStringHelpers.h"

@implementation GBCommit

@synthesize commitId;
@synthesize treeId;
@synthesize parentIds;
@synthesize authorName;
@synthesize authorEmail;
@synthesize committerName;
@synthesize committerEmail;

@synthesize date;
@synthesize message;

@synthesize changes;

@synthesize syncStatus;

@synthesize repository;




#pragma mark Init


- (NSArray*) parentIds
{
  if (!parentIds)
  {
    self.parentIds = [NSArray array];
  }
  return [[parentIds retain] autorelease];
}

- (NSArray*) changes
{
  if (!changes)
  {
    self.changes = [self loadChanges];
  }
  return [[changes retain] autorelease];
}

- (void) dealloc
{
  self.commitId = nil;
  self.treeId = nil;
  self.parentIds = nil;
  self.message = nil;
  self.authorName = nil;
  self.authorEmail = nil;
  self.committerName = nil;
  self.committerEmail = nil;

  self.date = nil;
  self.changes = nil;
  
  [super dealloc];
}




#pragma mark Interrogation


- (BOOL) isStage
{
  return NO;
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
  if ([self isMerge])
  {
    return [GBMergeCommitCell class];
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
  NSLog(@"ERROR: valueForUndefinedKey: %@", key);
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

- (NSAttributedString*) attributedHeader
{
  return [self attributedHeaderForAttributedString:[[[NSMutableAttributedString alloc] initWithString:@""] autorelease]];
}

- (NSAttributedString*) attributedHeaderForAttributedString:(NSMutableAttributedString*)attributedString
{
  if ([self isStage]) return nil;
    
  /* Layout:
      commit -> parent1, parent2
      date
      <b>Author Name</b> &lt;<a href="mailto:">mail@example.com</a>&gt;
      Committed by Committer Name &lt;<a href="mailto:">mail@example.com</a>&gt;
      
      Multiline message
  */
    
  [attributedString appendAttributedString:[NSAttributedString 
      attributedStringWithString:[self.commitId stringByAppendingString:@" → "]
      attributes:[NSDictionary dictionaryWithObjectsAndKeys:
                  [NSColor colorWithCalibratedWhite:0.3 alpha:1.0], NSForegroundColorAttributeName,
                  nil]]];
  
  BOOL firstParent = YES;
  for (NSString* parentId in self.parentIds)
  {
    if (!firstParent) 
    {
      [attributedString appendAttributedString:[NSAttributedString attributedStringWithString:@", "]];
    }
    firstParent = NO;
    
    [attributedString appendAttributedString:[NSAttributedString 
                                              attributedStringWithString:[parentId substringToIndex:8]
                                              attributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                          [NSColor colorWithCalibratedRed:20.0/255.0 green:70.0/255.0 blue:252.0/255.0 alpha:1.0], NSForegroundColorAttributeName,
                                                          @"#url", NSLinkAttributeName,
                                                          nil]]];
  }
  [attributedString appendAttributedString:[NSAttributedString attributedStringWithString:@"\n"]];
  
  NSDateFormatter* fullDateFormatter = [[[NSDateFormatter alloc] init] autorelease];
  [fullDateFormatter setDateStyle:NSDateFormatterLongStyle];
  [fullDateFormatter setTimeStyle:NSDateFormatterLongStyle];
  
  NSString* dateString = [fullDateFormatter stringFromDate:self.date];
  [attributedString appendAttributedString:[NSAttributedString 
                                            attributedStringWithString:dateString
                                            attributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                        [NSColor colorWithCalibratedWhite:0.3 alpha:1.0], NSForegroundColorAttributeName,
                                                        nil]]];
  [attributedString appendAttributedString:[NSAttributedString attributedStringWithString:@"\n"]];
  
  [attributedString addAttribute:NSFontAttributeName
                           value:[NSFont systemFontOfSize:11.0]
                           range:NSMakeRange(0, [attributedString length])];
  
  [attributedString appendAttributedString:[NSAttributedString 
                                            attributedStringWithString:self.authorName
                                            attributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                        [NSFont boldSystemFontOfSize:12.0], NSFontAttributeName,
                                                        nil]]];
  
  [attributedString appendAttributedString:[NSAttributedString attributedStringWithString:@" <"]];
  
  [attributedString appendAttributedString:[NSAttributedString 
                                            attributedStringWithString:self.authorEmail
                                            attributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                        [NSFont systemFontOfSize:12.0], NSFontAttributeName,
                                                        [NSString stringWithFormat:@"mailto:%@", self.authorEmail], NSLinkAttributeName,
                                                        nil]]];
  
  [attributedString appendAttributedString:[NSAttributedString attributedStringWithString:@">\n"]];
  
  [attributedString appendAttributedString:[NSAttributedString 
                                            attributedStringWithString:self.message
                                            attributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                        [NSFont systemFontOfSize:12.0], NSFontAttributeName,
                                                        nil]]];
  
  
  NSMutableParagraphStyle* paragraphStyle = [[[NSMutableParagraphStyle alloc] init] autorelease];
  [paragraphStyle setLineSpacing:3.0];
  
  [attributedString addAttribute:NSParagraphStyleAttributeName 
                           value:paragraphStyle
                           range:NSMakeRange(0, [attributedString length])];
  
  return attributedString;
}




#pragma mark Mutation


- (void) updateChanges
{
  NSArray* newChanges = [self allChanges];
  NSArray* existingChanges = self.changes;
  
  // Do no smart tricks if there are too many changes
  if (!existingChanges || [existingChanges count] <= 0 || [existingChanges count] > 100 || [newChanges count] > 100)
  {
    //NSLog(@"GBCommit updateChanges: list of changes is too big, just replacing existing ones.");
    self.changes = newChanges;
  }
  else if ([newChanges isEqualToArray:existingChanges])
  {
    // do nothing
    //NSLog(@"GBCommit updateChanges: new changes are equal to old changes!");
  }
  else 
  {
    // Check existing changes and replace only those which are not isEqual: to new ones
    // This will make UI more stable and even partially solve segfault issue
    
    NSMutableArray* newChangesPreservingExistingObjects = [[newChanges mutableCopy] autorelease];
    NSUInteger length = [newChangesPreservingExistingObjects count];
    for (NSUInteger index = 0; index < length; index++)
    {
      NSUInteger indexOfExistingObject = [existingChanges indexOfObject:[newChangesPreservingExistingObjects objectAtIndex:index]];
      
      if (indexOfExistingObject != NSNotFound)
      {
        //NSLog(@"GBCommit updateChanges: change exists, keeping");
        [newChangesPreservingExistingObjects 
                            replaceObjectAtIndex:index 
                                      withObject:[existingChanges objectAtIndex:indexOfExistingObject]];
      }
    }
    self.changes = newChangesPreservingExistingObjects;
  }
}

- (void) reloadChanges
{
  self.changes = [self loadChanges];
}

- (NSArray*) allChanges
{
  return [NSArray array];
}

- (NSArray*) loadChanges
{
  GBCommittedChangesTask* task = [GBCommittedChangesTask task];
  task.commit = self;
  [self.repository launchTask:task];
  return [self allChanges];
}

- (void) resetChanges
{
  self.changes = nil;
}

- (void) asyncTaskGotChanges:(NSArray*)theChanges
{
  self.changes = theChanges;
}

@end
