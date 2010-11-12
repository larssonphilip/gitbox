#import <Cocoa/Cocoa.h>

#if GITBOX_APP_STORE
  #import "OAAppStoreReceipt.h"
#endif

int main(int argc, char *argv[])
{
  NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
  
  #if GITBOX_APP_STORE
    // The purpose of this check here is to provide the user with
    // a proper iTunes update (say, when she moves to another computer).
    // Obfuscated check happens elsewhere in the app after some period of time.
    NSString* receiptPath = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"Contents/_MASReceipt/receipt"];
    if (!OAValidateAppStoreReceiptAtPath(receiptPath))
    {
      NSLog(@"Gitbox main: AppStore receipt not found or not valid at path %@", receiptPath);
      exit(173);
      return 173;
    }
    else
    {
      //NSLog(@"Gitbox main: AppStore receipt is valid. [%@]", receiptPath);
    }
  #endif
  
  int code = NSApplicationMain(argc, (const char **) argv);
  [pool drain];
  return code;
}
