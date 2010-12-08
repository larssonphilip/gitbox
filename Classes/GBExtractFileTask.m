#import "GBExtractFileTask.h"
#import "NSFileManager+OAFileManagerHelpers.h"
#import "NSString+OAStringHelpers.h"

@implementation GBExtractFileTask

@synthesize objectId;
@synthesize commitId;
@synthesize originalURL;
@synthesize targetURL;

- (void) dealloc
{
  self.objectId = nil;
  self.commitId = nil;
  self.originalURL = nil;
  self.targetURL = nil;
  [super dealloc];
}



#pragma mark Interrogation


- (NSString*) prettyFileName
{
  NSAssert(self.objectId, @"GBExtractFileTask: self.objectId is nil");
  
  if (self.originalURL)
  {
    NSString* fileName = [[self.originalURL path] lastPathComponent];
    NSString* suffix = self.commitId;
    if (!suffix)
    {
      suffix = self.objectId;
    }
    return [fileName pathWithSuffix:[NSString stringWithFormat:@"-%@", [suffix substringToIndex:8]]];
  }
  
  return self.objectId;
}

- (NSURL*) targetURL
{
  if (!targetURL)
  {
    NSString* path = [[NSTemporaryDirectory() stringByAppendingPathComponent:@"gitbox-blobs"] 
                      stringByAppendingPathComponent:[self prettyFileName]];
    self.targetURL = [NSURL fileURLWithPath:path];
  }
  return [[targetURL retain] autorelease];
}




#pragma mark OATask


- (void) prepareTask
{
  if (!self.standardOutput)
  {
    if (self.targetURL)
    {
      NSError* outError;
      
      // creates and intermediate folder and writes 0 bytes to the file
      [[NSFileManager defaultManager] writeData:[NSData data] toPath:[self.targetURL path]];

      NSFileHandle* handle = [NSFileHandle fileHandleForWritingToURL:self.targetURL error:&outError];
      if (handle)
      {
        self.standardOutput = handle;
      }
      else
      {
        NSLog(@"ERROR: GBExtractFileTask: NSFileHandle couldn't open %@ for writing: %@", self.targetURL, [outError localizedDescription]);
        // invalidate temp URL
        self.targetURL = nil;
      }
    }
  }
  [super prepareTask];
}

- (NSArray*) arguments
{
  return [NSArray arrayWithObjects:@"cat-file", @"blob", self.objectId, nil];
}



@end
