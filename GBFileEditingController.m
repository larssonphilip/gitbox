#import "GBFileEditingController.h"

#import "NSString+OAStringHelpers.h"
#import "NSData+OADataHelpers.h"
#import "NSFileManager+OAFileManagerHelpers.h"
#import "NSWindowController+OAWindowControllerHelpers.h"

@implementation GBFileEditingController

@synthesize URL;
@synthesize title;
@synthesize linesToAppend;

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
  self.linesToAppend = nil;
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

- (void) prepareContent
{
  NSData* data = [NSData dataWithContentsOfURL:self.URL];
  NSString* content = [data UTF8String];
  if (!content) content = @"";
  if (self.linesToAppend && [self.linesToAppend count] > 0)
  {
    content = [content stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSUInteger length = [content length];
    NSString* additionalSpace = (length > 0 ? @"\n\n" : @"");
    NSString* appendix = [self.linesToAppend componentsJoinedByString:@"\n"];
    content = [content stringByAppendingFormat:@"%@%@\n", additionalSpace, appendix];
    [self.textView setString:content];
    NSRange selectionRange = NSMakeRange(length + [additionalSpace length], [appendix length]);
    [self.textView setSelectedRange:selectionRange];
    [self.textView scrollRangeToVisible:selectionRange];
  }
  else
  {
    [self.textView setString:content];
  }  
}

- (void) runSheetInWindow:(NSWindow*)window
{
  self.windowHoldingSheet = window;
  [window beginSheetForController:self];
}



#pragma mark NSWindowDelegate


- (void) windowDidLoad
{
  // This method before sheet appears renders text with awful glitches.
  //[self prepareContent];
}

- (void) windowDidBecomeKey:(NSNotification*)notification
{
  [self prepareContent];
}


@end
