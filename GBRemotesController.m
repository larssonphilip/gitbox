#import "GBRemotesController.h"
#import "GBModels.h"

@interface GBRemotesController ()
- (NSMutableArray*) remotesDictionariesForRepository:(GBRepository*)repo;
@end

@implementation GBRemotesController
@synthesize repository;
@synthesize remotesDictionaries;
@synthesize target;
@synthesize finishSelector;
@synthesize cancelSelector;

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
  NSLog(@"TODO: Sync the dictionary with the current remotes and perform updates");
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
  return list;
}

@end
