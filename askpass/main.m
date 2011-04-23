#import <Foundation/Foundation.h>
#import "GBAskPassServer.h"

// The askpass utility is called with prompt as its first argument.
// Whatever it returns on STDOUT is consumed as a result.

int main (int argc, const char * argv[])
{
  NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
  [NSRunLoop currentRunLoop];
  
  NSString* promptString = nil;
  if (argc > 0)
  {
    promptString = [NSString stringWithCString:argv[0] encoding:NSUTF8StringEncoding];
  }
  
  NSDictionary* environment = [[NSProcessInfo processInfo] environment];
  
  NSString* clientId = [environment objectForKey:GBAskPassClientIdKey];
  
  if (!promptString || [promptString length] == 0)
  {
    NSLog(@"Gitbox askpass: prompt is nil or empty.");
    [pool drain];
    return -1;
  }

  if (!clientId || [clientId length] == 0)
  {
    NSLog(@"Gitbox askpass: clientId is nil or empty.");
    [pool drain];
    return -2;
  }
  
  NSDistantObject<GBAskPassServer>* server = [GBAskPassServer sharedRemoteServer];
  
  if (!server)
  {
    NSLog(@"Gitbox askpass: server is nil.");
    [pool drain];
    return -3;
  }
  
  int waittime = 0;
  
  while (1)
  {
    NSString* result = [server resultForClient:clientId prompt:promptString environment:environment];
    
    if (result)
    {
      const char *buffer = [result cStringUsingEncoding:NSUTF8StringEncoding];
      if (buffer == NULL)
      {
        NSLog(@"Gitbox askpass: cannot get char* UTF-8 string for result: %@.", result);
        [pool drain];
        return -4;
      }
      printf("%s\n", buffer);
      [pool drain];
      return 0;
    }
    
    sleep(1);
    waittime++;
  }
  
  [pool drain];
  return 0;
}

