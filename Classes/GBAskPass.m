#import "GBAskPass.h"
#import "GBAskPassServer.h"

// The askpass utility is called with prompt as its first argument.
// Whatever it returns on STDOUT is consumed as a result.

int GBAskPass(int argc, const char * argv[])
{
  NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
  [NSRunLoop currentRunLoop];
  
  NSString* promptString = nil;
  if (argc >= 2) // the 0 index is for the program name
  {
    promptString = [NSString stringWithCString:argv[1] encoding:NSUTF8StringEncoding];
  }
  
  //NSLog(@"Gitbox askpass: prompt = '%@'", promptString);
  
  NSDictionary* environment = [[NSProcessInfo processInfo] environment];
  
  NSString* serverName = [environment objectForKey:GBAskPassServerNameKey];
  NSString* clientId = [environment objectForKey:GBAskPassClientIdKey];
  
  if (!promptString || [promptString length] == 0)
  {
    NSLog(@"Gitbox askpass: prompt is nil or empty.");
    [pool drain];
    return -1;
  }
  
  if (!serverName || [serverName length] == 0)
  {
    NSLog(@"Gitbox askpass: %@ is nil or empty.", GBAskPassServerNameKey);
    [pool drain];
    return -2;
  }
  
  if (!clientId || [clientId length] == 0)
  {
    NSLog(@"Gitbox askpass: %@ is nil or empty.", GBAskPassClientIdKey);
    [pool drain];
    return -3;
  }
  
  NSDistantObject<GBAskPassServer>* server = [GBAskPassServer remoteServerWithName:serverName];
  
  if (!server)
  {
    NSLog(@"Gitbox askpass: server is nil. Name: %@; client ID: %@", serverName, clientId);
    [pool drain];
    return -4;
  }
  
  int waittime = 0;
  
  while (1)
  {
    NSString* result = nil;
    @try
    {
      promptString = [promptString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
      result = [server resultForClient:clientId prompt:promptString environment:environment];
    }
    @catch (NSException * e)
    {
      // Exception is usually raised when Gitbox app is closed while askpass is waiting for reply.
      NSLog(@"Gitbox askpass: exception raised when trying to get result from server: %@", e);
      [pool drain];
      return -5;
    }
    
    if (result)
    {
      const char *buffer = [result cStringUsingEncoding:NSUTF8StringEncoding];
      if (buffer == NULL)
      {
        NSLog(@"Gitbox askpass: cannot get char* UTF-8 string for result: %@.", result);
        [pool drain];
        return -6;
      }
      printf("%s\n", buffer);
      [pool drain];
      return 0;
    }
    //NSLog(@"Gitbox askpass: waiting with prompt %@", promptString);
    sleep(1);
    waittime++;
  }
  
  [pool drain];
  return 0;
}