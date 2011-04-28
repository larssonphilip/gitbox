
#import "GBAskPassServer.h"

NSString* const GBAskPassServerNameKey = @"GBAskPassServerName";
NSString* const GBAskPassClientIdKey = @"GBAskPassClientId";

@interface GBAskPassServer () <NSConnectionDelegate>
@property(nonatomic, copy, readwrite) NSString* name;
@property(nonatomic, retain) NSMutableSet* clients;
@property(nonatomic, retain) NSMutableDictionary* resultsByClientId;
@property(nonatomic, retain) NSConnection* connection;
@end

@implementation GBAskPassServer

@synthesize name;
@synthesize clients;
@synthesize resultsByClientId;
@synthesize connection;

- (void)dealloc
{
  self.name = nil;
  self.clients = nil;
  self.resultsByClientId = nil;
  [self.connection invalidate];
  self.connection = nil;
  [super dealloc];
}

+ (GBAskPassServer*) sharedServer
{
  static id volatile instance = nil;
	static dispatch_once_t once = 0;
	dispatch_once( &once, ^{ instance = [[self alloc] init]; });
	return instance;
}

+ (NSDistantObject<GBAskPassServer>*) remoteServerWithName:(NSString*)aName
{
  NSDistantObject* distantObject = [NSConnection rootProxyForConnectionWithRegisteredName:aName host:nil];
  [[distantObject retain] autorelease];
  [distantObject setProtocolForProxy:@protocol(GBAskPassServer)];
  return (NSDistantObject<GBAskPassServer>*)distantObject;
}

- (id)init
{
  if ((self = [super init]))
  {
    self.name = [NSString stringWithFormat:@"GBAskPassServer-%d-%p", [[NSProcessInfo processInfo] processIdentifier], self];
    self.clients = [NSMutableSet set];
    self.resultsByClientId = [NSMutableDictionary dictionary];
    // note: creating a retain cycle, call -invalidate to break it.
    self.connection = [NSConnection serviceConnectionWithName:self.name rootObject:self];
    if (!self.connection)
    {
      NSLog(@"GBAskPassServer: cannot create NSConnection with name %@", self.name);
      [self release];
      return nil;
    }
    [self.connection setDelegate:self];
  }
  return self;
}

- (void) invalidate
{
  [self.connection setRootObject:nil];
  [self.connection invalidate];
}

- (void) addClient:(id<GBAskPassServerClient>)aClient
{
  [self.clients addObject:aClient];
}

- (void) removeClient:(id<GBAskPassServerClient>)aClient
{
  [[aClient retain] autorelease];
  [self.clients removeObject:aClient];
}

- (void) setResult:(NSString*)aResult forClientId:(NSString*) aClientId
{
  if (!aClientId) return;
  if (aResult)
  {
    [self.resultsByClientId setObject:aResult forKey:aClientId];
  }
  else
  {
    [self.resultsByClientId removeObjectForKey:aClientId];
  }
}

- (NSString*) resultForClient:(NSString*)clientId prompt:(NSString*)prompt environment:(NSDictionary*)environment
{
  if (!clientId) return nil;
  NSString* preparedResult = [self.resultsByClientId objectForKey:clientId];
  
  // A client already set a result: return it and forget it.
  if (preparedResult)
  {
    //NSLog(@"DEBUG: returning result %@", preparedResult);
    [[preparedResult retain] autorelease];
    [self.resultsByClientId removeObjectForKey:clientId];
    return preparedResult;
  }
  
  // Client has not yet set a result. Find a client object and ask it.
  //NSLog(@"GBAskPassServer: resultForClient:%@ prompt:%@", clientId, prompt);
  for (id<GBAskPassServerClient> aClient in self.clients)
  {
    if ([[aClient askPassClientId] isEqualToString:clientId])
    {
      return [aClient resultForClient:clientId prompt:prompt environment:environment];
    }
  }
  
//  #warning Temp debug code  
//  double delayInSeconds = 2.0;
//  dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
//  dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
//    NSString* r = [NSString stringWithFormat:@"Reply to %@", prompt];
//    NSLog(@"DEBUG: setting result %@", r);
//    [self setResult:r forClientId:clientId];
//  });
  
  return nil;
}

- (NSString*) echo:(NSString*)string
{
  return string;
}

- (NSString*) description
{
  return [NSString stringWithFormat:@"<GBAskPassServer:%p name:%@ clients:%d resultsByClientId:%@>", 
          self, 
          self.name, 
          [self.clients count], 
          self.resultsByClientId];
}

@end
