#import "GBTask.h"
#import "GBAskPassController.h"
#import "GBAskPassServer.h"
#import "GBAskPassBooleanPromptController.h"
#import "GBAskPassCredentialsController.h"

@interface GBAskPassController ()<GBAskPassServerClient>
@property(nonatomic, copy) NSString* askPassClientId;
@property(nonatomic, copy) NSString* currentPrompt;
@property(nonatomic, assign, readwrite, getter = isCancelled) BOOL cancelled;
@property(nonatomic, copy) void(^originalTaskBlock)();
@property(nonatomic, copy, readwrite) NSString* failureMessage;
@property(nonatomic, copy, readwrite) NSString* previousUsername;
@property(nonatomic, copy, readwrite) NSString* previousPassword;
@end

@implementation GBAskPassController

@synthesize askPassClientId;
@synthesize currentPrompt;
@synthesize task;
@synthesize address;
@synthesize username;
@synthesize password;
@synthesize booleanResponse;
@synthesize bypassFailedAuthentication;
@synthesize cancelled;
@synthesize delegate;
@synthesize originalTaskBlock;
@synthesize failureMessage;
@synthesize previousUsername;
@synthesize previousPassword;

- (void) dealloc
{
  [askPassClientId release]; askPassClientId = nil;
  [currentPrompt release]; currentPrompt = nil;
  [task release]; task = nil;
  [address release]; address = nil;
  [username release]; username = nil;
  [password release]; password = nil;
  [booleanResponse release]; booleanResponse = nil;
  [originalTaskBlock release]; originalTaskBlock = nil;
  [failureMessage release]; failureMessage = nil;
  [previousUsername release]; previousUsername = nil;
  [previousPassword release]; previousPassword = nil;
  [super dealloc];
}

+ (id) controllerWithTask:(GBTask*)aTask address:(NSString*)address
{
  return [self controllerWithTask:aTask address:address delegate:nil];
}

+ (id) controllerWithTask:(GBTask*)aTask address:(NSString*)address delegate:(id<GBAskPassControllerDelegate>)aDelegate
{
  GBAskPassController* ctrl = [[[self alloc] init] autorelease];
  ctrl.address = address;
  ctrl.delegate = aDelegate ? aDelegate : ctrl;
  ctrl.task = aTask;
  return ctrl;
}

- (id) init
{
  if ((self = [super init]))
  {
    self.askPassClientId = [NSString stringWithFormat:@"GBAskPassController:%p", self];
    self.delegate = self;
  }
  return self;
}

- (void) setTask:(GBTask *)newTask
{
  if (task == newTask) return;
  
  if (task)
  {
    task.didTerminateBlock = self.originalTaskBlock;
    [task release];
    task = nil;
  }
  
  if (newTask)
  {
    task = [newTask retain];
    
    NSString* pathToAskpass = [[NSBundle mainBundle] pathForResource:@"askpass" ofType:nil];
    
    [task mergeEnvironment:[NSDictionary dictionaryWithObjectsAndKeys:
                            pathToAskpass, @"GIT_ASKPASS",
                            pathToAskpass, @"SSH_ASKPASS",
                            [GBAskPassServer sharedServer].name, GBAskPassServerNameKey,
                            self.askPassClientId, GBAskPassClientIdKey,
                            nil]];
    
    self.originalTaskBlock = task.didTerminateBlock;
    task.didTerminateBlock = ^{
      if (![task isError] || self.bypassFailedAuthentication) // if no error occured or we should bypass it, simply call original block
      {
        if (self.originalTaskBlock) self.originalTaskBlock();
        self.originalTaskBlock = nil;
        return;
      }
      
      // Sample output values:
      //   ERROR: Permission to rails/rails.git denied to oleganza.
      //   Permission denied (publickey)
      //   fatal: Authentication failed
      
      NSString* output = [[task UTF8Output] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
      if ([[output lowercaseString] rangeOfString:@"permission"].length > 0 || 
          [[output lowercaseString] rangeOfString:@"authentication"].length > 0)
      {
        self.failureMessage = output;
        self.previousUsername = self.username;
        self.previousPassword = self.password;
        
        // Auth failed, try to launch the task again, but this time without using keychain.

        GBTask* anotherTask = [[task copy] autorelease];
        anotherTask.didTerminateBlock = self.originalTaskBlock; // restore original block to make task look exactly like the original one
        self.task = anotherTask;
        [self.task launch];
      }
      else // unknown error, bypass
      {
        if (self.originalTaskBlock) self.originalTaskBlock();
        self.originalTaskBlock = nil;
        return;
      }
    };
  }
}





#pragma mark GBAskPassServerClient


- (NSString*) resultForClient:(NSString*)clientId prompt:(NSString*)prompt environment:(NSDictionary*)environment
{
  if (![self.askPassClientId isEqualToString:clientId]) return nil;
    
  BOOL repeatedPrompt = (self.currentPrompt && [self.currentPrompt isEqualToString:prompt]);
  self.currentPrompt = prompt;
  
  if ([[prompt lowercaseString] rangeOfString:@"yes/no"].length > 0)
  {
    if ([self isCancelled])
    {
      return @"no";
    }
    
    if (self.booleanResponse)
    {
      return ([self.booleanResponse boolValue] ? @"yes" : @"no");
    }
    
    if (!repeatedPrompt)
    {
      [self.delegate askPass:self presentBooleanPrompt:prompt];
    }
  }
  
  if ([self isCancelled])
  {
    return @"";
  }
  
  if ([[prompt lowercaseString] rangeOfString:@"username:"].length > 0)
  {
    if (self.username)
    {
      return self.username;
    }
    
    if (!self.failureMessage)
    {
      // TODO: support keychain after the whole UI with dialog is completed.
    }
    
    if (!repeatedPrompt)
    {
      [self.delegate askPassPresentUsernamePrompt:self];
    }
  }
  else
  {
    if (self.password)
    {
      return self.password;
    }
    
    if (!self.failureMessage)
    {
      // TODO: support keychain after the whole UI with dialog is completed.
    }
    
    if (!repeatedPrompt)
    {
      [self.delegate askPassPresentPasswordPrompt:self];
    }
  }
  
  return nil;
}

- (void) cancel
{
  self.cancelled = YES;
  self.bypassFailedAuthentication = YES;
}

- (void) storeCredentialsInKeychain
{
  // TODO: store a proper record based on address, username and password.
}






#pragma GBAskPassControllerDelegate - controller is a delegate for itself by default



- (void) askPass:(GBAskPassController*)askPassController presentBooleanPrompt:(NSString*)prompt
{
  prompt = [prompt stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
  prompt = [prompt stringByReplacingOccurrencesOfString:@" (yes/no)?" withString:@"?"];
  
  GBAskPassBooleanPromptController* ctrl = [GBAskPassBooleanPromptController 
                                            controllerWithAddress:self.address
                                            question:prompt 
                                            callback:^(BOOL result) {
                                              self.booleanResponse = [NSNumber numberWithBool:result];
                                              [ctrl close];
                                            }];
  [ctrl showWindow:self];
}

- (void) askPassPresentUsernamePrompt:(GBAskPassController*)askPassController
{
  GBAskPassCredentialsController* ctrl = [GBAskPassCredentialsController 
                                            controllerWithAddress:self.address
                                            callback:^(BOOL promptCancelled) {
                                              if (promptCancelled)
                                              {
                                                [self cancel];
                                              }
                                              else
                                              {
                                                self.username = ctrl.username;
                                                self.password = ctrl.password;
                                              }
                                              [ctrl close];
                                            }];
  [ctrl showWindow:self];
}

- (void) askPassPresentPasswordPrompt:(GBAskPassController*)askPassController
{
  GBAskPassCredentialsController* ctrl = [GBAskPassCredentialsController 
                                          passwordOnlyControllerWithAddress:self.address
                                          callback:^(BOOL promptCancelled) {
                                            if (promptCancelled)
                                            {
                                              [self cancel];
                                            }
                                            else
                                            {
                                              self.password = ctrl.password;
                                            }
                                            [ctrl close];
                                          }];
  [ctrl showWindow:self];
}


@end
