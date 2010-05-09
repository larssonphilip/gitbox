#import "GBRepository.h"
#import "GBRef.h"

#import "NSFileManager+OAFileManagerHelpers.h"
#import "NSObject+OALogging.h"
#import "NSAlert+OAAlertHelpers.h"
#import "NSData+OADataHelpers.h"

@implementation GBRepository

+ (BOOL) isValidRepositoryAtPath:(NSString*) aPath
{
  return aPath && [NSFileManager isWritableDirectoryAtPath:[aPath stringByAppendingPathComponent:@".git"]];
}


@synthesize url;
@dynamic path;
- (NSString*) path
{
  return [url path];
}

@synthesize dotGitURL;
- (NSURL*) dotGitURL
{
  if (!dotGitURL)
  {
    self.dotGitURL = [self.url URLByAppendingPathComponent:@".git"];
  }
  return [[dotGitURL retain]  autorelease];
}

- (NSURL*) gitURLWithSuffix:(NSString*)suffix
{
  return [self.dotGitURL URLByAppendingPathComponent:suffix];
}


@synthesize localBranches;
- (NSArray*) localBranches
{
  if (!localBranches)
  {
    NSError* outError = nil;
    NSURL* aurl = [self gitURLWithSuffix:@"refs/heads"];
    NSAssert(aurl, @"url must be .git/refs/heads");
    NSArray* URLs = [[NSFileManager defaultManager] 
                     contentsOfDirectoryAtURL:aurl
                      includingPropertiesForKeys:[NSArray array] 
                      options:0 
                      error:&outError];
    NSMutableArray* refs = [NSMutableArray array];
    if (URLs)
    {
      for (NSURL* aURL in URLs)
      {
        NSString* name = [[aURL pathComponents] lastObject];
        GBRef* ref = [[GBRef new] autorelease];
        ref.name = name;
        [refs addObject:ref];
      }
    }
    else
    {
      [NSAlert error:outError];
    }
    self.localBranches = refs;
  }
  return [[localBranches retain] autorelease];
}

@synthesize remoteBranches;
- (NSArray*) remoteBranches
{
  if (!remoteBranches)
  {
    [self TODO:@"Find real remote branches"];
    self.remoteBranches = [NSArray array];
  }
  return [[remoteBranches retain] autorelease];  
}

@synthesize tags;
- (NSArray*) tags
{
  if (!tags)
  {
    NSError* outError = nil;
    NSURL* aurl = [self gitURLWithSuffix:@"refs/tags"];
    NSAssert(aurl, @"url must be .git/refs/tags");
    NSArray* URLs = [[NSFileManager defaultManager] 
                     contentsOfDirectoryAtURL:aurl
                     includingPropertiesForKeys:[NSArray array] 
                     options:0 
                     error:&outError];
    NSMutableArray* refs = [NSMutableArray array];
    if (URLs)
    {
      for (NSURL* aURL in URLs)
      {
        NSString* name = [[aURL pathComponents] lastObject];
        GBRef* ref = [[GBRef new] autorelease];
        ref.name = name;
        ref.isTag = YES;
        [refs addObject:ref];
      }
    }
    else
    {
      [NSAlert error:outError];
    }
    self.tags = refs;
  }
  return [[tags retain] autorelease];
}

@synthesize currentRef;
- (GBRef*) currentRef
{
  if (!currentRef)
  {
    NSError* outError = nil;
    NSString* HEAD = [NSString stringWithContentsOfURL:[self gitURLWithSuffix:@"HEAD"]
                                              encoding:NSUTF8StringEncoding 
                                                 error:&outError];
    if (!HEAD)
    {
      [NSAlert error:outError];
      return nil;
    }
    HEAD = [HEAD stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString* refprefix = @"ref: refs/heads/";
    GBRef* ref = [[GBRef new] autorelease];
    if ([HEAD hasPrefix:refprefix])
    {
      ref.name = [HEAD substringFromIndex:[refprefix length]];
    }
    else // assuming SHA1 ref
    {
      [self TODO:@"Test for tag"];
      ref.commitId = HEAD;
    }
    self.currentRef = ref;
  }
  return [[currentRef retain] autorelease];
}




#pragma mark Mutation methods


- (void) checkoutRef:(GBRef*)ref
{
  NSTask* task = [[NSTask alloc] init];
  [task setCurrentDirectoryPath:self.path];
  [task setLaunchPath: @"/usr/bin/env"];
  NSString* rev = (ref.name ? ref.name : ref.commitId);
  [task setArguments: [NSArray arrayWithObjects:@"git", @"checkout", rev, nil]];
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
  NSLog(@"git-checkout finished with status: %d", status);
  NSData* data = [[[task standardOutput] fileHandleForReading] readDataToEndOfFile];
  NSLog(@"git-checkout: %@", [data UTF8String]);
}




- (void) dealloc
{
  self.url = nil;
  self.localBranches = nil;
  self.remoteBranches = nil;
  self.tags = nil;
  self.currentRef = nil;
  [super dealloc];
}

@end
