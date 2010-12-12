#import "GBRemotesController.h"
#import "GBModels.h"
#import "GBTask.h"


@interface GBRemotesController ()
- (NSMutableArray*) remotesDictionariesForRepository:(GBRepository*)repo;
- (void) syncRemotesDictionariesWithRepository;
@end

@implementation GBRemotesController
@synthesize repository;
@synthesize remotesDictionaries;
@synthesize target;
@synthesize finishSelector;
@synthesize cancelSelector;

+ (id) controller
{
  return [[[GBRemotesController alloc] initWithWindowNibName:@"GBRemotesController"] autorelease];
}

- (void) dealloc
{
  self.repository = nil;
  self.remotesDictionaries = nil;
  [super dealloc];
}

- (NSMutableArray*) remotesDictionaries
{
  if (!remotesDictionaries)
  {
    self.remotesDictionaries = [self remotesDictionariesForRepository:self.repository];
  }
  return [[remotesDictionaries retain] autorelease];
}

- (IBAction) onOK:(id)sender
{
  [self syncRemotesDictionariesWithRepository];
  if (self.finishSelector) [self.target performSelector:self.finishSelector withObject:self];
}

- (IBAction) onCancel:(id)sender
{
  self.remotesDictionaries = nil;
  if (self.cancelSelector) [self.target performSelector:self.cancelSelector withObject:self];
}




#pragma mark Private
  

- (NSMutableArray*) remotesDictionariesForRepository:(GBRepository*)repo
{
  NSMutableArray* list = [NSMutableArray array];
  for (GBRemote* remote in self.repository.remotes)
  {
    [list addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
                     remote.alias, @"alias",
                     remote.URLString, @"URLString",
                     nil]];
  }
  
  if ([list count] == 0) // new repo, add a default "origin" entry
  {
    [list addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
                     @"origin", @"alias",
                     @"", @"URLString",
                     nil]];    
  }
  
  return list;
}


- (void) syncRemotesDictionariesWithRepository
{
  NSArray* oldAliases = [self.repository.remotes valueForKey:@"alias"];
  NSArray* newAliases = [self.remotesDictionaries valueForKey:@"alias"];
  
  NSMutableArray* removedAliases = [[oldAliases mutableCopy] autorelease];
  [removedAliases removeObjectsInArray:newAliases];

  NSMutableArray* addedAliases = [[newAliases mutableCopy] autorelease];
  [addedAliases removeObjectsInArray:oldAliases];
  
  BOOL dirtyFlag = NO;
  
  for (NSString* alias in removedAliases)
  {
    dirtyFlag = YES;
    GBTask* task = [self.repository task];
    task.arguments = [NSArray arrayWithObjects:@"config", 
                      @"--remove-section", 
                      [NSString stringWithFormat:@"remote.%@", alias], 
                      nil];
    [self.repository launchTaskAndWait:task];
  }

  for (NSString* alias in addedAliases)
  {
    NSString* URLString = nil;
    for (NSDictionary* dict in self.remotesDictionaries)
    {
      if ([[dict objectForKey:@"alias"] isEqualToString:alias])
      {
        URLString = [dict objectForKey:@"URLString"];
      }
    }
    
    if (URLString && [URLString length] > 0)
    {
      dirtyFlag = YES;
      GBTask* task = [self.repository task];
      task.arguments = [NSArray arrayWithObjects:@"config", 
                        [NSString stringWithFormat:@"remote.%@.fetch", alias], 
                        [NSString stringWithFormat:@"+refs/heads/*:refs/remotes/%@/*", alias],
                        nil];
      
      [self.repository launchTaskAndWait:task];
      
      task = [self.repository task];
      task.arguments = [NSArray arrayWithObjects:@"config", 
                        [NSString stringWithFormat:@"remote.%@.url", alias], 
                        URLString,
                        nil];
      
      [self.repository launchTaskAndWait:task];
    }
  }
  
  // Since we listen to FSEvent, changes done here should automatically apply
  //if (dirtyFlag) [self.repository loadRemotesWithBlock:^{}];
  //dirtyFlag = NO;
  
  for (GBRemote* remote in self.repository.remotes)
  {
    NSDictionary* updatedDict = nil;
    for (NSDictionary* dict in self.remotesDictionaries)
    {
      if ([[dict objectForKey:@"alias"] isEqualToString:remote.alias])
      {
        updatedDict = dict;
      }
    }
    
    NSString* newURLString = [updatedDict objectForKey:@"URLString"];
    if (newURLString && [newURLString length] > 0 && ![newURLString isEqualToString:remote.URLString])
    {
      dirtyFlag = YES;
      GBTask* task = [self.repository task];
      task.arguments = [NSArray arrayWithObjects:@"config", 
                        [NSString stringWithFormat:@"remote.%@.url", remote.alias], 
                        newURLString,
                        nil];
      [self.repository launchTaskAndWait:task];
    }
  }
  
  //if (dirtyFlag) [self.repository loadRemotesWithBlock:^{}];
}

@end
