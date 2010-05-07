#import "AppDelegate.h"
#import "MyDocument.h"

@implementation AppDelegate

- (BOOL) applicationShouldOpenUntitledFile:(NSApplication*) app
{
  return NO;
}

- (void) applicationDidFinishLaunching:(NSNotification*) aNotification
{
}

- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename
{
  NSURL* url = [[[NSURL alloc] initFileURLWithPath:filename isDirectory:YES] autorelease];
  NSLog(@"opening %@", url);
  NSError* outError;
  MyDocument* document = [[[MyDocument alloc] initWithContentsOfURL:url 
                                                            ofType:@"fold" 
                                                             error:&outError] autorelease];
  
  if (!document)
  {
    NSLog(@"application:openFile:%@ ERROR: %@", filename, [outError localizedDescription]);
    return NO;
  }
  [self addDocument:document];
  return YES;
}

@end
