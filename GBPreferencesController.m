#import "GBPreferencesController.h"
#import "GBRepository.h"

@implementation GBPreferencesController

NSString* GBGitPathKey = @"OATask_pathForExecutable_git";

@synthesize gitPathField;
@synthesize gitPathStatusLabel;

- (void) dealloc
{
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
  self.gitPathField = nil;
  self.gitPathStatusLabel = nil;
  [super dealloc];
}



#pragma mark Storage


- (NSString*) stringForKey:(NSString*)key
{
  return [[NSUserDefaults standardUserDefaults] objectForKey:key];
}

- (void) setString:(NSString*) string forKey:(NSString*)key
{
  [[NSUserDefaults standardUserDefaults] setObject:string forKey:key];
}



#pragma mark Update routines


- (BOOL) checkGitPath
{
  NSString* aPath = [self.gitPathField stringValue];

  BOOL isDirectory = NO;
  if (![[NSFileManager defaultManager] fileExistsAtPath:aPath isDirectory:&isDirectory])
  {
    NSLog(@"not a file at path %@", aPath);
    [self.gitPathStatusLabel setStringValue:@"Error: file not found"];
    return NO;
  }

  if (isDirectory)
  {
    [self.gitPathStatusLabel setStringValue:@"Error: file is not an executable"];
    return NO;
  }
  
  if (![[NSFileManager defaultManager] isExecutableFileAtPath:aPath])
  {
    [self.gitPathStatusLabel setStringValue:@"Error: file is not an executable"];
    return NO;
  }
  
  NSString* version = [GBRepository gitVersionForLaunchPath:aPath];
  
  if (![GBRepository isSupportedGitVersion:version])
  {
    [self.gitPathStatusLabel setStringValue:[NSString stringWithFormat:@"Error: not supported version %@", version]];
    return NO;
  }
  [self.gitPathStatusLabel setStringValue:[NSString stringWithFormat:@"Version %@", version]];
  return YES;
}

- (void) delayedGitPathUpdate
{
  if ([self checkGitPath])
  {
    [self setString:[self.gitPathField stringValue] forKey:GBGitPathKey];
  }
}




#pragma mark NSTextFieldDelegate


- (void)controlTextDidChange:(NSNotification *)aNotification
{
  [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(delayedGitPathUpdate) object:nil];
  [self performSelector:@selector(delayedGitPathUpdate) withObject:nil afterDelay:0.4];
}




#pragma mark NSWindowDelegate


- (void) windowDidBecomeKey:(NSNotification *)notification
{
  if (!isOpened)
  {
    [self.gitPathField setStringValue:[self stringForKey:GBGitPathKey]];
  }
  [self checkGitPath];
  
  isOpened = YES;
}

- (void) windowDidResignKey:(NSNotification *)notification
{
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void) windowWillClose:(NSNotification *)notification
{
  isOpened = NO;
}

@end
