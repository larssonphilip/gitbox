#import "GBFileEditingController.h"

#import "NSString+OAStringHelpers.h"
#import "NSData+OADataHelpers.h"
#import "NSFileManager+OAFileManagerHelpers.h"
#import "NSWindowController+OAWindowControllerHelpers.h"

@implementation GBFileEditingController

@synthesize URL;
@synthesize title;

@synthesize textView;

@synthesize target;
@synthesize finishSelector;
@synthesize cancelSelector;
@synthesize windowHoldingSheet;

+ (GBFileEditingController*) controller
{
  return [[[self alloc] initWithWindowNibName:@"GBFileEditingController"] autorelease];
}

- (void) dealloc
{
  self.URL = nil;
  self.title = nil;
  self.textView = nil;
  [super dealloc];
}

- (IBAction) onOK:(id)sender
{
  NSData* data = [[self.textView string] dataUsingEncoding:NSUTF8StringEncoding];
  [[NSFileManager defaultManager] writeData:data toPath:[self.URL path]];
  
  if (finishSelector) [self.target performSelector:finishSelector withObject:self];
  
  [self.windowHoldingSheet endSheetForController:self];
  self.windowHoldingSheet = nil;
}

- (IBAction) onCancel:(id)sender
{
  if (cancelSelector) [self.target performSelector:cancelSelector withObject:self];
  [self.windowHoldingSheet endSheetForController:self];
  self.windowHoldingSheet = nil;
}

- (void) runSheetInWindow:(NSWindow*)window
{
  self.windowHoldingSheet = window;
  [window beginSheetForController:self];
}



#pragma mark NSWindowDelegate


- (void) windowDidBecomeKey:(NSNotification*)notification
{
  NSData* data = [NSData dataWithContentsOfURL:self.URL];
  [self.textView setString:[data UTF8String]];
}


@end
