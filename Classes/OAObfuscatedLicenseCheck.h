/*
 Usage: in some .m file include this file.
 For a couple of actions, invoke a macro function OACheckLicenseObfuscated;
 
 
*/

#if GITBOX_APP_STORE
  #import "OAAppStoreReceipt.h"
  #define OACheckLicenseObfuscated { \
    if ((mach_absolute_time() % 5) == 0 || (arc4random() % 5) == 0 ) { \
      dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)arc4random()),dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{ \
        NSString* relPath = @"Contents/_MASReceipt/receipt"; \
        if ((mach_absolute_time() % 5) == 0 || (arc4random() % 5) == 0 ) { \
          dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)arc4random()), dispatch_get_main_queue(), ^{ \
            NSString* receiptPath = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:relPath]; \
			(BOOL)(*func)(NSString*) = OAValidateAppStoreReceiptAtPath; \
			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)arc4random()), dispatch_get_main_queue(), ^{ \
			  if (!func(receiptPath)) { \
			    NSLog(@"OAObfuscatedLicenseCheck: receipt not found or not valid at path %@", receiptPath); \
			  } \
			}); \
          }); \
        } \
      }); \
    } \
  }

#else

  // TODO: should also check that the number of opened repos is > 1

  #import "OALicenseNumberCheck.h"
  #define OACheckLicenseObfuscated { \
	NSString* licenseWord = [NSString stringWithFormat:@"l%@", \
							 [NSString stringWithFormat:@"i%@", \
							  [NSString stringWithFormat:@"ce%@", \
							   [NSString stringWithFormat:@"ns%@", @"e"]]]];\
	NSString* license = [[NSUserDefaults standardUserDefaults] objectForKey:licenseWord]; \
	\
  }

#endif
