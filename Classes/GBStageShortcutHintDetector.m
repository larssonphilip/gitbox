#import "GBStageShortcutHintDetector.h"

@interface GBStageShortcutHintDetector ()
@property(nonatomic) BOOL addedNewLine;
@property(nonatomic) BOOL removedNewLine;
@property(nonatomic) BOOL finishedPlayingWithTooltip;

- (void) showView;

@end

@implementation GBStageShortcutHintDetector

+ (GBStageShortcutHintDetector*) detectorWithView:(NSView*)aView
{
  GBStageShortcutHintDetector* d = [[self new] autorelease];
  d.view = aView;
  return d;
}

@synthesize view;

@synthesize addedNewLine;
@synthesize removedNewLine;
@synthesize finishedPlayingWithTooltip;

- (void) dealloc
{
  [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(showView) object:nil];
  self.view = nil;
  [super dealloc];
}

- (void) textView:(NSTextView*)aTextView didChangeTextInRange:(NSRange)affectedCharRange replacementString:(NSString*)replacementString
{
  if (self.finishedPlayingWithTooltip) return;
  if (!self.view) return;
  if (![self.view isHidden]) return;
  
  if (!self.addedNewLine)
  {
    if (affectedCharRange.location == [[aTextView string] length] && 
        affectedCharRange.length == 0 && 
        [replacementString isEqualToString:@"\n"])
    {
      // Possibly unintended newline. Should display shortcut tip if no text is entered.
      self.addedNewLine = YES;
      [self performSelector:@selector(showView) withObject:nil afterDelay:0.6];
    }
  }
  else
  {
    if (!self.removedNewLine &&
        affectedCharRange.location == ([[aTextView string] length] - 1) && 
        affectedCharRange.length == 1 && 
        [replacementString isEqualToString:@""])
    {
      // backspace entered. This usually happens when unintended new line is cancelled. Ignore it.
      self.removedNewLine = YES;
    }
    else
    {
      [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(showView) object:nil];
      self.finishedPlayingWithTooltip = YES;
    }
  }
}

- (void) showView
{
  [self.view setHidden:NO];
  self.finishedPlayingWithTooltip = YES;
}

- (void) reset
{
  [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(showView) object:nil];
  [self.view setHidden:YES];
  self.finishedPlayingWithTooltip = NO;
  self.addedNewLine = NO;
  self.removedNewLine = NO;
}

@end
