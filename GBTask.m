#import "GBTask.h"
#import "NSAlert+OAAlertHelpers.h"
#import "NSData+OADataHelpers.h"

@implementation GBTask
@synthesize path;

- (int) launchWithArguments:(NSArray*)args outputRef:(NSData**)outputRef
{
  NSTask* task = [[NSTask new] autorelease];
  [task setCurrentDirectoryPath:self.path];
  [task setLaunchPath: @"/usr/bin/env"];
  [task setArguments: args];
  [task setStandardOutput:[NSPipe pipe]];
  [task setStandardError:[task standardOutput]]; // stderr > stdout
  
  //  This code with notifications is for async operations (networking or simply slow)
  //  To keep code simple we just block on certain usually fast operations like git-checkout
  
  //  // Here we register as an observer of the NSFileHandleReadCompletionNotification, which lets
  //  // us know when there is data waiting for us to grab it in the task's file handle (the pipe
  //  // to which we connected stdout and stderr above).  -getData: will be called when there
  //  // is data waiting.  The reason we need to do this is because if the file handle gets
  //  // filled up, the task will block waiting to send data and we'll never get anywhere.
  //  // So we have to keep reading data from the file handle as we go.
  //  [[NSNotificationCenter defaultCenter] addObserver:self 
  //                                           selector:@selector(getData:) 
  //                                               name: NSFileHandleReadCompletionNotification 
  //                                             object: [[task standardOutput] fileHandleForReading]];
  //  // We tell the file handle to go ahead and read in the background asynchronously, and notify
  //  // us via the callback registered above when we signed up as an observer.  The file handle will
  //  // send a NSFileHandleReadCompletionNotification when it has data that is available.
  //  [[[task standardOutput] fileHandleForReading] readInBackgroundAndNotify];
  
  [task launch];
  [task waitUntilExit];
  int status = [task terminationStatus];
  if (outputRef)
  {
    *outputRef = [[[task standardOutput] fileHandleForReading] readDataToEndOfFile];
  }
  else if (status != 0)
  {
    NSData* output = [[[task standardOutput] fileHandleForReading] readDataToEndOfFile];
    [NSAlert message:[NSString stringWithFormat:@"Failed %@ [%d]", [args componentsJoinedByString:@" "], status]
         description:[output UTF8String]];
  }
  
  return status;
}

- (int) launchWithArguments:(NSArray*)args
{
  return [self launchWithArguments:args outputRef:NULL];
}

- (int) launchCommand:(NSString*)command outputRef:(NSData**)outputRef
{
  return [self launchWithArguments:[command componentsSeparatedByString:@" "]
                     outputRef:outputRef];
}

- (int) launchCommand:(NSString*)command
{
  return [self launchCommand:command outputRef:NULL];
}


- (void) dealloc
{
  self.path = nil;
  [super dealloc];
}

@end
