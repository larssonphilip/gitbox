#import "GBAskPassCredentialsController.h"

@implementation GBAskPassCredentialsController

@synthesize callback;
@synthesize address;
@synthesize username;
@synthesize password;

@synthesize addressLabel;
@synthesize usernameField;
@synthesize passwordField;


+ (id) controllerWithAddress:(NSString*)addr callback:(void(^)(BOOL))callback
{
  GBAskPassCredentialsController* ctrl = [[[self alloc] initWithWindowNibName:@"GBAskPassCredentialsController"] autorelease];
  ctrl.address = addr;
  ctrl.callback = callback;
  return ctrl;
}

+ (id) passwordOnlyControllerWithAddress:(NSString*)addr callback:(void(^)(BOOL))callback
{
  GBAskPassCredentialsController* ctrl = [[[self alloc] initWithWindowNibName:@"GBAskPassCredentialsControllerPasswordOnly"] autorelease];
  ctrl.address = addr;
  ctrl.callback = callback;
  return ctrl;
}



// Init/dealloc


- (void)dealloc
{
  [callback release]; callback = nil;
  [address release]; address = nil;
  [username release]; username = nil;
  [password release]; password = nil;
  
  [addressLabel release]; addressLabel = nil;
  [usernameField release]; usernameField = nil;
  [passwordField release]; passwordField = nil;
  
  [super dealloc];
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
