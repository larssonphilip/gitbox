#import <Cocoa/Cocoa.h>

#if GITBOX_APP_STORE
  #import "OAAppStoreReceipt.h"
#else
  #import "OALicenseNumberCheck.h"
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
  #else

    #if 0
	#warning Testing license validation in main.m
	if (!OAValidateLicenseNumber(@"")) NSLog(@"OK 1");
	if (!OAValidateLicenseNumber(@"1")) NSLog(@"OK 2");
	if (!OAValidateLicenseNumber(@"4a522efb6f17fc5-8378ba790890b1a3442ef0414f1d")) NSLog(@"OK 3");
	if (!OAValidateLicenseNumber(@"4a522efb6f17fc558378ba790890b1a3442ef0414f1d6347509458934598347")) NSLog(@"OK 4");
	
	if (OAValidateLicenseNumber(@"51e58c29d98c0c92f06862198edf07d4945923ec8bcd")) NSLog(@"OK 5");
	if (OAValidateLicenseNumber(@"4a522efb6f17fc558378ba790890b1a3442ef0414f1d")) NSLog(@"OK 6");
	if (OAValidateLicenseNumber(@"3fe7b7c0e4119d2d9b6a26e7876acc0e84e2a9bbb969")) NSLog(@"OK 7");
    #endif
	
  #endif
  
  int code = NSApplicationMain(argc, (const char **) argv);
  [pool drain];
  return code;
}
