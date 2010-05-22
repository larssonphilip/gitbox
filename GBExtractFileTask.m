#import "GBExtractFileTask.h"
#import "NSFileManager+OAFileManagerHelpers.h"

@implementation GBExtractFileTask

@synthesize objectId;
@synthesize originalURL;
@synthesize temporaryURL;

- (void) dealloc
{
  self.objectId = nil;
  self.originalURL = nil;
  self.temporaryURL = nil;
  [super dealloc];
}



#pragma mark Interrogation


- (NSString*) prettyFileName
{
  if (!self.objectId)
  {
    NSLog(@"ERROR: self.objectId is nil");
    return nil;
  }
  
  if (self.originalURL)
  {
    NSString* fileName = [[self.originalURL path] lastPathComponent];
    NSString* ext = [fileName pathExtension];
    return [[[fileName stringByDeletingPathExtension] 
                       stringByAppendingFormat:@"-%@", [self.objectId substringToIndex:8]] 
                      stringByAppendingPathExtension:ext];
  }
  
  return self.objectId;
}

- (NSURL*) temporaryURL
{
  if (!temporaryURL)
  {
    NSString* path = [[NSTemporaryDirectory() stringByAppendingPathComponent:@"gitbox-blobs"] 
                      stringByAppendingPathComponent:[self prettyFileName]];
    
    // creates and intermediate folder and writes 0 bytes to the file
    [[NSFileManager defaultManager] writeData:[NSData data] toPath:path];
    
    self.temporaryURL = [[[NSURL alloc] initFileURLWithPath:path] autorelease];
  }
  return [[temporaryURL retain] autorelease];
}




#pragma mark OATask


- (id) standardOutput
{
  if (!standardOutput)
  {
    if (self.temporaryURL)
    {
      NSError* outError;
      NSFileHandle* handle = [NSFileHandle fileHandleForWritingToURL:self.temporaryURL error:&outError];
      if (!handle)
      {
        NSLog(@"ERROR: NSFileHandle couldn't open %@ for writing: %@", self.temporaryURL, [outError localizedDescription]);
        // invalidate temp URL
        self.temporaryURL = nil;
        return nil;
      }
      self.standardOutput = handle;
    }
  }
  return [[standardOutput retain] autorelease];
}

- (NSArray*) arguments
{
  return [NSArray arrayWithObjects:@"cat-file", @"blob", self.objectId, nil];
}



@end
