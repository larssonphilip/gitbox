#import <Cocoa/Cocoa.h>

#if GITBOX_APP_STORE
  #define OA_APPSTORE_SAMPLE_RECEIPT 1
#endif

#import "OAAppStoreReceipt.h"

int main(int argc, char *argv[])
{
  NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
  
  #if GITBOX_APP_STORE
    // The purpose of this check here is to provide the user with
    // a proper iTunes update (say, when she moves to another computer).
    // Obfuscated check happens elsewhere in the app after some period of time.
    NSString* receiptPath = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"Contents/_MASReceipt/receipt"];
    // put the example receipt on the desktop (or change that path)
    #if OA_APPSTORE_SAMPLE_RECEIPT
      receiptPath = @"/Users/oleganza/Work/gitbox/app/appstore_receipt_tests/SampleReceipt";
    #endif
    if (!OAValidateAppStoreReceiptAtPath(receiptPath))
    {
      NSLog(@"Gitbox main: receipt not found or not valid at path %@", receiptPath);
      exit(173);
      return 173;
    }
  #endif
  
  int code = NSApplicationMain(argc, (const char **) argv);
  [pool drain];
  return code;
}
