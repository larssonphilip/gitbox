#import "GBTask.h"
#import "GBAskPassController.h"
#import "GBAskPassServer.h"

@interface GBAskPassController ()<GBAskPassServerClient>
@property(nonatomic, copy) NSString* askPassClientId;
@property(nonatomic, copy) NSString* currentPrompt;
@end

@implementation GBAskPassController

@synthesize askPassClientId;
@synthesize currentPrompt;
@synthesize task;
@synthesize URLString;
@synthesize username;
@synthesize password;
@synthesize booleanResponse;
@synthesize bypassFailedAuthentication;
@synthesize delegate;

- (void) dealloc
{
  [askPassClientId release]; askPassClientId = nil;
  [currentPrompt release]; currentPrompt = nil;
  [task release]; task = nil;
  [URLString release]; URLString = nil;
  [username release]; username = nil;
  [password release]; password = nil;
  [booleanResponse release]; booleanResponse = nil;
  [super dealloc];
}

- (id) init
{
  if ((self = [super init]))
  {
    self.askPassClientId = [NSString stringWithFormat:@"GBAskPassController:%p", self];
  }
  return self;
}







#pragma mark GBAskPassServerClient


- (NSString*) resultForClient:(NSString*)clientId prompt:(NSString*)prompt environment:(NSDictionary*)environment
{
  if (![self.askPassClientId isEqualToString:clientId]) return nil;
  
  prompt = [prompt lowercaseString];
  
  BOOL repeatedPrompt = (self.currentPrompt && [self.currentPrompt isEqualToString:prompt]);
  self.currentPrompt = prompt;
  
  if ([prompt rangeOfString:@"yes/no"].length > 0)
  {
    if (self.booleanResponse)
    {
      return ([self.booleanResponse boolValue] ? @"yes" : @"no");
    }
    else
    {
      return nil;
    }
    
    if (!repeatedPrompt)
    {
      // TODO: take care of yes/no questions: present an async prompt sheet.
    }
  }
  
  
  // First prompt:
  // Try to find a keychain value
  // 1. If asks for username, request UI with username and password.
  // 2. If asks for the password, request UI with password only. If username is nil, try to extract it from the URLString.
  
  
  // Second prompt: 
  // 1. If asks for the username return username or nil
  // 2. If asks for the password return password or nil
  
  if ([prompt rangeOfString:@"username:"].length > 0)
  {
//    if (self.username)
  
  }
  
  else
  {
    
  }
  
  return nil;
}



@end
