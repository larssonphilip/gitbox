#import "GBCloneTask.h"
#import "GBTask.h"
#import "GBRemote.h"
#import "NSData+OADataHelpers.h"

@interface GBCloneTask ()
@property(nonatomic, retain) NSDate* lastProgressUpdate;
@end

@implementation GBCloneTask

@synthesize sourceURL;
@synthesize targetURL;
@synthesize progressUpdateBlock;
@synthesize lastProgressUpdate;
@synthesize status;
@synthesize progress;

- (void) dealloc
{
  self.sourceURL = nil;
  self.targetURL = nil;
  self.progressUpdateBlock = nil;
  self.lastProgressUpdate = nil;
  self.status = nil;
  [super dealloc];
}

- (NSString*) launchPath
{
  return [GBTask pathToBundledBinary:@"git"];
}

- (NSString*) currentDirectoryPath
{
  return [[self.targetURL path] stringByDeletingLastPathComponent];
}

- (NSString*) keychainPasswordName
{
  return [GBRemote keychainPasswordNameForURLString:[self.sourceURL absoluteString]];
}

- (BOOL) isRealTime
{
  return YES;
}

- (NSArray*) arguments
{
  NSString* folder = [[self.targetURL path] lastPathComponent];
  NSAssert(folder, ([NSString stringWithFormat:@"Target URL should have last path component (self.targetURL = %@)", self.targetURL]));
  NSAssert(self.sourceURL, @"Source URL should be present");
  return [NSArray arrayWithObjects:@"clone", [self.sourceURL absoluteString], folder, @"--progress", nil];
}

- (void) callProgressBlock
{
  dispatch_async(dispatch_get_main_queue(), self.progressUpdateBlock);
}

- (double) progressWithPrefix:(NSString*)prefix line:(NSString*)line
{
  NSRange range = NSMakeRange(0,0);
  if ((range = [line rangeOfString:prefix]).length > 0)
  {
    @try
    {
      NSRange progressRange = [line rangeOfString:@"%" options:0 range:NSMakeRange(range.location+range.length, 6)];
      if (progressRange.length > 0)
      {
        progressRange = NSMakeRange(range.location+range.length, progressRange.location - (range.location + range.length));
        NSString* portion = [line substringWithRange:progressRange];
        double partialProgress = [portion doubleValue];
        return partialProgress;
      }
    }
    @catch (NSException *exception)
    {
      NSLog(@"GBCloneTask: exception while parsing progress output: %@ [prefix: %@; line: %@]", exception, prefix, line);
    }
  }
  return 0.0;
}

- (void) didReceiveStandardErrorData:(NSData*)dataChunk
{
//  NSDate* now = [NSDate date];
//  if (lastProgressUpdate && [now timeIntervalSinceDate:lastProgressUpdate] < 0.1) return; // skip updates every 0.1 sec for performance.
//  self.lastProgressUpdate = now;
  
  static double compressingRatio = 0.1;
  static double resolvingDeltasRatio = 0.1;
  static double receivingRatio = 0.8;
  
  NSString* string = [[dataChunk UTF8String] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
  NSArray* lines = [string componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\n\r"]];
  if (!lines || [lines count] == 0) return;
  NSString* line = [lines lastObject];
  if (!line) return;
  
  //NSLog(@"LINE: %@", line);
  
  /*
   possible lines:
     warning: templates not found /usr/local/Cellar/git/1.7.3.2/share/git-core/templates
     Cloning into emrpc1...
     remote: Counting objects: 890, done.[K
     remote: Compressing objects:   0% (1/299)   [K
     Receiving objects:   2% (18/890)
     Resolving deltas:  12% (72/578)
   */
  double newProgress = self.progress;

  double partialProgress = 0.0;
  if ([line rangeOfString:@"Counting objects:"].length > 0)
  {
    self.status = NSLocalizedString(@"Preparing...", @"Clone");
  }
  else if ((partialProgress = [self progressWithPrefix:@"Compressing objects:" line:line]) > 0.0)
  {
    self.status = NSLocalizedString(@"Packing...", @"Clone");
    newProgress = compressingRatio*partialProgress;
  }
  else if ((partialProgress = [self progressWithPrefix:@"Receiving objects:" line:line]) > 0.0)
  {
    self.status = NSLocalizedString(@"Downloading...", @"Clone");
    newProgress = compressingRatio*100.0 + receivingRatio*partialProgress;
  }
  else if ((partialProgress = [self progressWithPrefix:@"Resolving deltas:" line:line]) > 0.0)
  {
    self.status = NSLocalizedString(@"Unpacking...", @"Clone");
    newProgress = (compressingRatio + receivingRatio)*100.0 + resolvingDeltasRatio*partialProgress;
  }
  
  if (round(newProgress) == round(self.progress)) return;
  
  self.progress = newProgress;
  [self callProgressBlock];
}

- (void) didFinishInBackground
{
  self.progress = 100.0;
  self.status = @"";
  
  [self callProgressBlock];
  self.progressUpdateBlock = nil; // break retain cycle through the block
}

@end
