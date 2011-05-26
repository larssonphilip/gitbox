#import "GBPromptController.h"
#import "NSString+OAStringHelpers.h"

@implementation GBPromptController

@synthesize textField;

@synthesize title;
@synthesize promptText;
@synthesize buttonText;
@synthesize value;

@synthesize requireNonNilValue;
@synthesize requireNonEmptyString;
@synthesize requireSingleLine;
@synthesize requireStripWhitespace;

+ (GBPromptController*) controller
{
  return [[[self alloc] initWithWindowNibName:@"GBPromptController"] autorelease];
}

- (id) initWithWindow:(NSWindow*)window
{
  if ((self = [super initWithWindow:window]))
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
  [super dealloc];
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
  
  [[self retain] autorelease];
  [self performCompletionHandler:NO];
  self.value = @"";
}

- (IBAction) onCancel:(id)sender
{
  [self performCompletionHandler:YES];
}

- (void)windowDidBecomeKey:(NSNotification *)notification
{
  if (self.requireSingleLine)
  {
    NSWindow* win = [self window];
    NSSize minSize = [win contentMinSize];
    NSSize maxSize = [win contentMaxSize];
    maxSize.height = minSize.height;
    [win setContentMaxSize:maxSize];
    
    // Note: when the field is wrapping in NIB, these options do not help. 
    // So we set NIB to have single-line scrolling textfield and override it in multiline mode.
//    [[self.textField cell] setLineBreakMode:NSLineBreakByClipping];
//    [[self.textField cell] setUsesSingleLineMode:NO];
//    [[self.textField cell] setWraps:NO];
//    [[self.textField cell] setScrollable:YES];
  }
  else
  {
    [[self.textField cell] setLineBreakMode:NSLineBreakByWordWrapping];
    [[self.textField cell] setWraps:YES];
  }

  [self.textField setStringValue:self.value ? self.value : @""];
}

@end
