#import "GBPromptController.h"
#import "NSString+OAStringHelpers.h"
#import "NSWindowController+OAWindowControllerHelpers.h"

@implementation GBPromptController

@synthesize textField;

@synthesize title;
@synthesize promptText;
@synthesize buttonText;
@synthesize value;
@synthesize finishBlock;
@synthesize cancelBlock;

@synthesize requireNonNilValue;
@synthesize requireNonEmptyString;
@synthesize requireSingleLine;
@synthesize requireStripWhitespace;
@synthesize callbackDelay;

@synthesize windowHoldingSheet;

+ (GBPromptController*) controller
{
  return [[[self alloc] initWithWindowNibName:@"GBPromptController"] autorelease];
}

- (id) initWithWindow:(NSWindow*)window
{
  if (self = [super initWithWindow:window])
  {
    self.value = @"";
    self.title = NSLocalizedString(@"Prompt",@"");
    self.promptText = NSLocalizedString(@"Prompt:",@"");
    self.buttonText = NSLocalizedString(@"OK",@"");
    self.requireNonNilValue = YES;
    self.requireNonEmptyString = YES;
  }
  return self;
}

- (void) dealloc
{
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
  self.textField = nil;
  self.title = nil;
  self.promptText = nil;
  self.buttonText = nil;
  self.value = nil;
  self.finishBlock = nil;
  self.cancelBlock = nil;
  [super dealloc];
}

- (void) performCallbackAndRelease:(void(^)())block
{
  block();
  [self autorelease];
}

- (void) performCallbackNowOrLater:(void(^)())block
{
  if (!block) return;
  if (self.callbackDelay <= 0.0)
  {
    block();
    return;
  }
  [self retain];
  [self performSelector:@selector(performCallbackAndRelease:) withObject:block afterDelay:self.callbackDelay];
}

- (IBAction) onOK:(id)sender
{
  self.value = [self.textField stringValue];
  if (requireSingleLine || requireStripWhitespace)
  {
    self.value = [self.value stringByReplacingOccurrencesOfString:@"\n" withString:@""];
  }
  if (requireStripWhitespace)
  {
    self.value = [self.value stringByReplacingOccurrencesOfString:@"\t" withString:@""];
    self.value = [self.value stringByReplacingOccurrencesOfString:@" " withString:@""];
  }
  if (requireNonNilValue && !self.value) self.value = @"";
  if (requireNonEmptyString && (!self.value || [self.value isEmptyString])) return;
  
  [self performCallbackNowOrLater:self.finishBlock];
  self.value = @"";
  [self endSheet];
}

- (IBAction) onCancel:(id)sender
{
  [self performCallbackNowOrLater:self.cancelBlock];
  [self endSheet];
}

- (void) runSheetInWindow:(NSWindow*)window
{
  self.windowHoldingSheet = window;
  if (self.requireSingleLine)
  {
    NSWindow* win = [self window];
    NSSize minSize = [win contentMinSize];
    NSSize maxSize = [win contentMaxSize];
    maxSize.height = minSize.height;
    [win setContentMaxSize:maxSize];
    [[self.textField cell] setUsesSingleLineMode:YES];
  }
  [window beginSheetForController:self];
  [self.textField setStringValue:self.value];
}

- (void) endSheet
{
  self.finishBlock = nil;
  self.cancelBlock = nil;
  [self.windowHoldingSheet endSheetForController:self];
  self.windowHoldingSheet = nil;
}

@end
