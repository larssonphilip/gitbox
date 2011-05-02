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
  contentPrepared = NO;
  [self performCompletionHandler:NO];
}

- (IBAction) onCancel:(id)sender
{
  contentPrepared = NO;
  [self performCompletionHandler:YES];
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
    NSString* additionalSpace = (length > 0 ? @"\n" : @"");
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




#pragma mark NSWindowDelegate


- (void) windowDidLoad
{
  // This method before sheet appears renders text with awful glitches.
  //[self prepareContent];
}

- (void) windowDidBecomeKey:(NSNotification*)notification
{
  if (!contentPrepared)
  {
    contentPrepared = YES;
    [self prepareContent];
  }
}


@end
