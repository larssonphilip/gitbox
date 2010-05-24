#import "GBModels.h"

#import "NSData+OADataHelpers.h"
#import "NSString+OAGitHelpers.h"

@implementation GBCommit

@synthesize revision;
@synthesize message;
@synthesize authorName;
@synthesize authorEmail;
@synthesize date;
@synthesize repository;

@synthesize changes;
- (NSArray*) changes
{
  if (!changes)
  {
    self.changes = [self loadChanges];
  }
  return [[changes retain] autorelease];
}

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
  return [self allChanges];
}

- (BOOL) isStage
{
  return NO;
}

- (void) dealloc
{
  self.revision = nil;
  self.changes = nil;
  
  self.message = nil;
  self.authorName = nil;
  self.authorEmail = nil;
  self.date = nil;
  
  [super dealloc];
}

@end
