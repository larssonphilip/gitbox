#import "GBPreferencesController.h"
#import "GBModels.h"
#import "OATask.h"

@implementation GBPreferencesController

@synthesize tabView;
@synthesize gitPathField;
@synthesize gitPathStatusLabel;


- (void) dealloc
{
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
  self.tabView = nil;
  self.gitPathField = nil;
  self.gitPathStatusLabel = nil;
  [super dealloc];
}

- (NSArray*) diffTools
{
  return [GBChange diffTools];
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

  if ([aPath isEqualToString:@""])
  {
    [self.gitPathStatusLabel setStringValue:@""];
    return NO;
  }
  
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
    [OATask rememberPath:[self.gitPathField stringValue] forExecutable:@"git"];
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
    NSString* path = [OATask rememberedPathForExecutable:@"git"];
    if (!path) path = @"";
    [self.gitPathField setStringValue:path];
  }
  [self checkGitPath];
  
  isOpened = YES;
}

- (void) windowDidResignKey:(NSNotification *)notification
{
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
  [self delayedGitPathUpdate];
}

- (void) windowWillClose:(NSNotification *)notification
{
  isOpened = NO;
}

@end
