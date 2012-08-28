#import "GBAskPassCredentialsController.h"

@implementation GBAskPassCredentialsController

@synthesize callback;
@synthesize address;
@synthesize username;
@synthesize password;

@synthesize addressLabel;
@synthesize usernameField;
@synthesize passwordField;


+ (id) controller
{
  GBAskPassCredentialsController* ctrl = [[self alloc] initWithWindowNibName:@"GBAskPassCredentialsController"];
  return ctrl;
}

+ (id) passwordOnlyController
{
  GBAskPassCredentialsController* ctrl = [[self alloc] initWithWindowNibName:@"GBAskPassCredentialsControllerPasswordOnly"];
  return ctrl;
}



// Init/dealloc


- (void)dealloc
{
   callback = nil;
  
  
}

- (void)windowDidLoad
{
  [super windowDidLoad];
  
  [self.addressLabel  setStringValue:self.address  ? self.address  : @""];
  [self.usernameField setStringValue:self.username ? self.username : @""];
  [self.passwordField setStringValue:self.password ? self.password : @""];
}



// IBActions


- (IBAction) cancel:(id)sender
{
  if (self.callback) self.callback(YES);
  self.callback = nil;
}

- (IBAction) ok:(id)sender
{
  // TODO: check that when "Return" is hit, we have a proper value here.
  if (self.usernameField) self.username = [self.usernameField stringValue];
  if (self.passwordField) self.password = [self.passwordField stringValue];
  
  if (self.callback) self.callback(NO);
  self.callback = nil;
}


@end
