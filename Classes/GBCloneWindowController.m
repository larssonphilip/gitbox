#import "GBCloneWindowController.h"
#import "NSWindowController+OAWindowControllerHelpers.h"
#import "NSFileManager+OAFileManagerHelpers.h"

@implementation GBCloneWindowController

@synthesize urlField;
@synthesize nextButton;
@synthesize finishBlock;
@synthesize sourceURL;
@synthesize targetDirectoryURL;
@synthesize targetURL;

@synthesize windowHoldingSheet;

- (void) dealloc
{
  self.urlField = nil;
  self.nextButton = nil;
  self.targetDirectoryURL = nil;
  self.targetURL = nil;
  [super dealloc];
}

- (NSURL*) urlFromTextField
{
  NSString* urlString = [self.urlField stringValue];
  if ([urlString isEqual:@""]) return nil;
  urlString = [urlString stringByReplacingOccurrencesOfString:@"git clone" withString:@""];
  urlString = [urlString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
  
  if ([urlString rangeOfString:@"~/"].location == 0)
  {
    urlString = [urlString stringByReplacingOccurrencesOfString:@"~" withString:NSHomeDirectory()];
  }
  
  if ([urlString rangeOfString:@"://"].location == NSNotFound)
  {
    if ([[NSFileManager defaultManager] fileExistsAtPath:urlString])
    {
      return [NSURL fileURLWithPath:urlString];
    }
    urlString = [urlString stringByReplacingOccurrencesOfString:@":" withString:@"/"]; // git@github.com:oleganza/path => git@github.com/oleganza/path
    urlString = [NSString stringWithFormat:@"ssh://%@", urlString];
  }
  NSURL* url = [NSURL URLWithString:urlString];
  return url;
}

- (void) update
{
  [self.nextButton setEnabled:!![self urlFromTextField]];
}

- (IBAction) cancel:_
{
  if (self.windowHoldingSheet) [self.windowHoldingSheet endSheetForController:self];
}

- (IBAction) ok:_
{
  self.sourceURL = [self urlFromTextField];
  
  if (self.sourceURL)
  {
    if (self.windowHoldingSheet) [self.windowHoldingSheet endSheetForController:self];
    
    NSString* suggestedName = [[self.sourceURL absoluteString] lastPathComponent];
    if (!suggestedName) suggestedName = @"";
    NSInteger dotgitlocation = 0;
    if (suggestedName && 
        [suggestedName length] > 4 && 
        (dotgitlocation = [suggestedName rangeOfString:@".git"].location) == ([suggestedName length] - 4))
    {
      suggestedName = [suggestedName substringToIndex:dotgitlocation];
    }
    
    NSSavePanel* panel = [NSSavePanel savePanel];
    [panel setMessage:[self.sourceURL absoluteString]];
    [panel setNameFieldLabel:NSLocalizedString(@"Clone To:", @"Clone")];
    [panel setNameFieldStringValue:[[suggestedName copy] autorelease]];
    [panel setPrompt:NSLocalizedString(@"Clone", @"Clone")];
    [panel setDelegate:self];
    [panel beginSheetModalForWindow:self.windowHoldingSheet completionHandler:^(NSInteger result){
      if (result == NSFileHandlingPanelOKButton)
      {
        self.targetDirectoryURL = [panel directoryURL];
        self.targetURL = [panel URL];
        
        if (self.targetDirectoryURL && self.targetURL)
        {
          if (self.finishBlock) self.finishBlock();
          
          // Clean up for next use.
          [self.urlField setStringValue:@""];
          self.sourceURL = nil;
          self.targetDirectoryURL = nil;
          self.targetURL = nil;
        }
      }
      else
      {
        [self.windowHoldingSheet performSelector:@selector(beginSheetForController:) withObject:self afterDelay:0.0];
      }
    }];
  }
}

- (void) windowDidLoad
{
  [super windowDidLoad];
  [self update];
}

- (void) runSheetInWindow:(NSWindow*)aWindow
{
  self.windowHoldingSheet = aWindow;
  [aWindow beginSheetForController:self];
  [self update];
}


#pragma mark NSTextFieldDelegate


- (void)controlTextDidChange:(NSNotification *)aNotification
{
  [self update];
}



#pragma mark NSOpenSavePanelDelegate


- (BOOL)panel:(NSSavePanel*)aPanel validateURL:(NSURL*)url error:(NSError **)outError
{
  return ![[NSFileManager defaultManager] fileExistsAtPath:[url path]];
}


- (NSString*)panel:(NSSavePanel*)aPanel userEnteredFilename:(NSString*)filename confirmed:(BOOL)okFlag
{
  if (okFlag) // on 10.6 we are still not receiving okFlag == NO, so I don't want to have this feature untested.
  {
    if ([[NSFileManager defaultManager] fileExistsAtPath:[[aPanel URL] path]]) return nil;
  }
  return filename;
}

@end
