#import "GBAskPassBooleanPromptController.h"

@implementation GBAskPassBooleanPromptController

@synthesize callback;
@synthesize address;
@synthesize question;

@synthesize addressLabel;
@synthesize questionLabel;

+ (id) controller
{
  GBAskPassBooleanPromptController* ctrl = [[[self alloc] initWithWindowNibName:@"GBAskPassBooleanPromptController"] autorelease];
  return ctrl;
}



#pragma mark Init and dealloc


- (void)dealloc
{
  [callback release]; callback = nil;
  [address release]; address = nil;
  [question release]; question = nil;
  
  [addressLabel release]; addressLabel = nil;
  [questionLabel release]; questionLabel = nil;

  [super dealloc];
}

- (void)windowDidLoad
{
  [super windowDidLoad];
    
  [self.addressLabel setStringValue:self.address ? self.address : @""];
  [self.questionLabel setStringValue:self.question ? self.question : @""];
}




#pragma mark IBActions


- (IBAction) no:(id)sender
{
  if (self.callback) self.callback(NO);
  self.callback = nil;
}

- (IBAction) yes:(id)sender
{
  if (self.callback) self.callback(YES);
  self.callback = nil;
}


@end
