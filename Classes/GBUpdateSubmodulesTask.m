#import "GBRepository.h"
#import "GBSubmodule.h"
#import "GBUpdateSubmodulesTask.h"

#import "NSData+OADataHelpers.h"


@implementation GBUpdateSubmodulesTask

@synthesize submodules;



- (NSArray*) submodulesFromStatusOutput:(NSData*) data
{
  /* Example (from Express.js repository):
   
   688b96c28e485da80211218ed5fd8c9f70a26be4 support/connect (0.5.2-7-g688b96c)
   ccefcd28dbb30d9a38a6fd12a50e77e8c461b4d3 support/connect-form (0.2.0)
   b1d822e99ccfb49f729f69d38dd66b2ce1fc501e support/ejs (0.2.1)
   da39f132bc2880a7eec013217b8f2f496ed5d2b1 support/expresso (0.7.0)
   +42b8e0e19b226bc2fabfa06fe013340e3d5677a0 support/haml (0.4.4-3-g42b8e0e)
   c6ecf33acbaac8ecf63deb557e116a0ef719884c support/jade (0.6.1)
   607f8734e80774a098f084a6ef66934787b7f33f support/should (0.0.3-6-g607f873)
   
   when none of the submodules was initialized, git adds minus in front of the SHA (example from Jade repository):
   
   -b1d822e99ccfb49f729f69d38dd66b2ce1fc501e benchmarks/ejs
   -382bc11ce4fd03403bcf2c0ed5545a4c891b60c2 benchmarks/haml
   -34fb092db3fff6d3b95a361dea4c21b63b8553c9 benchmarks/haml-js
   -502d444ebd6c0589a14cc20e951d5b34a30d46c7 support/coffee-script
   -2ea263d1b64d318edeed4abe45a0f4ebae80bbff support/expresso
   -805b0a69e1b357dcf2c4d54486dbcd7d6ac3d427 support/markdown
   -738177239c6b55521a1b0cb12aadccb794eb1609 support/sass     
   
   
   that is, the output looks like this:
   
   [space][optional + or -][SHA1 of commit submodule is pinned to][space or newline?][submodule path][the rest]
   */
  NSScanner* scanner = [NSScanner scannerWithString:[data UTF8String]];
  NSCharacterSet* whitespaceCharacterSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
  NSCharacterSet* plusOrMinusCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@"+-"];
  [scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@""]];
  
  NSMutableArray *ary = [NSMutableArray array];
  
  while ([scanner isAtEnd] == NO)
  {
    [scanner scanCharactersFromSet:whitespaceCharacterSet intoString:NULL];
    
    // optional plus or minus
    NSString* leadingChar = nil;
    
    [scanner scanCharactersFromSet:plusOrMinusCharacterSet intoString:&leadingChar];
    
    // commit submodule is pinned down to
    NSString* submoduleRef = nil;
    if (![scanner scanUpToString:@" " intoString:&submoduleRef]) {
      // TOOD: log an error
    }
    
    // space
    if (![scanner scanString:@" " intoString:NULL]) {
      // TODO: log an error
    }
    
    // submodule path
    NSString* submodulePath = nil;
    if (![scanner scanUpToCharactersFromSet:whitespaceCharacterSet intoString:&submodulePath]) {
      // TOOD: log an error
    }
    
    /* from there on there may or may not be any other content in the line.
     * In any case, it is irrelevant to us: we know submodule ref and we don't care
     * what branch/tag that commit belongs to. MK.
     */
    [scanner scanUpToString:@"\n" intoString:NULL];
    [scanner scanString:@"\n" intoString:NULL];
    
    //NSLog(@"submodulePath = %@, self.repository = %@", submodulePath, self.repository);
    NSURL* submoduleURL = [self.repository URLForSubmoduleAtPath:submodulePath];
    
    GBSubmodule *submodule = [[GBSubmodule new] autorelease];
    submodule.path         = submodulePath;
    submodule.remoteURL    = submoduleURL;
    submodule.repository   = self.repository;

    #if DEBUG
      NSLog(@"Instantiated submodule %@ (%@) at %@", submodule.path, submoduleURL, [self.repository path]);
    #endif

    [ary addObject:submodule];
  }

  self.submodules = ary;
  return ary;
}


- (void) didFinish
{
  [super didFinish];

  if (self.terminationStatus == 0 || self.terminationStatus == 1)
  {
    self.submodules = [self submodulesFromStatusOutput:self.output];
  }
}



# pragma mark implementation

- (void) prepareTask
{
  self.arguments = [NSArray arrayWithObjects:@"submodule", @"status", nil];
  
  [super prepareTask];
}

@end
