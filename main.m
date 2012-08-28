#import <Cocoa/Cocoa.h>

#import "OALicenseNumberCheck.h"

#import "GBAskPass.h"
#import "GBAskPassServer.h"

int main(int argc, const char *argv[])
{
	@autoreleasepool {
	if ([[[NSProcessInfo processInfo] environment] objectForKey:GBAskPassServerNameKey])
	{
		return GBAskPass(argc, argv);
	}
	
	if (getenv("NSZombieEnabled"))
	{
		NSLog(@"WARNING! NSZombieEnabled is ON!");
	}
	
	if (getenv("NSAutoreleaseFreedObjectCheckEnabled"))
	{
		NSLog(@"WARNING! NSAutoreleaseFreedObjectCheckEnabled is ON!");
	}
	
#if GITBOX_APP_STORE
    // The purpose of this check here is to provide the user with
    // a proper iTunes update (say, when she moves to another computer).
    // Obfuscated check happens elsewhere in the app after some period of time.
    NSString* receiptPath = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"Contents/_MASReceipt/receipt"];
    if (!OAValidateAppStoreReceiptAtPath(receiptPath))
    {
		NSLog(@"Gitbox main: AppStore receipt not found or not valid at path %@", receiptPath);
		
		#if 0
		#warning DEBUG: ignoring missing AppStore receipt!
		#else
			exit(173);
			return 173;
		#endif
    }
    else
    {
		//NSLog(@"Gitbox main: AppStore receipt is valid. [%@]", receiptPath);
    }
#else
	
	//    #if 0
	//      #warning Testing license validation in main.m
	//      if (!OAValidateLicenseNumber(@"")) NSLog(@"OK 1");
	//      if (!OAValidateLicenseNumber(@"1")) NSLog(@"OK 2");
	//      if (!OAValidateLicenseNumber(@"X990f4706a9482a67416629cb036dde1b3f6deac5c2c")) NSLog(@"OK 3");
	//      if (!OAValidateLicenseNumber(@"5990f4706a9482a67416629cb03Xdde1b3f6deac5c2c")) NSLog(@"OK 4");
	//      if (!OAValidateLicenseNumber(@"5990f4706a9482a67416629cb036dde1b3f6deac5c2cX")) NSLog(@"OK 5");
	//
	//      if (OAValidateLicenseNumber(@"5990f4706a9482a67416629cb036dde1b3f6deac5c2c")) NSLog(@"OK 6");
	//      if (OAValidateLicenseNumber(@"1892a8e355c763065a1926a41a675ed55a177e4e069e")) NSLog(@"OK 7");
	//      if (OAValidateLicenseNumber(@"4edb88e33ac74494f983aa13e7eeeee844d6f23e30d8")) NSLog(@"OK 8");
	//
	//      exit(1);
	//      return 1;
	//    #endif
	//  
	//    #if DEBUG
	//      static int64_t delay = 523123123;
	//    #else
	//      static int64_t delay = 200222000555;
	//    #endif
	//    
	//    NSString* key = @"license";
	//    NSString* license = [[NSUserDefaults standardUserDefaults] objectForKey:key];
	//    if (OAValidateLicenseNumber(license))
	//    {
	//      NSString* lowerCase = [license lowercaseString];
	//      dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delay), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), [[(^{
	//        if (![lowerCase isEqualToString:license])
	//        {
	//          dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delay), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), [[(^{
	//            [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
	//            [[NSUserDefaults standardUserDefaults] synchronize];
	//          }) copy] autorelease]);
	//          
	//          dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2*delay), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), [[(^{
	//            
	//            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"GBRepositoriesController_localRepositories"];
	//            [[NSUserDefaults standardUserDefaults] synchronize];
	//
	//            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delay), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), [[(^{
	//              
	//              exit(0);
	//              
	//            }) copy] autorelease]);
	//            
	//          }) copy] autorelease]);
	//        }
	//      }) copy] autorelease]);    
	//    }
	
#endif
	
	return NSApplicationMain(argc, (const char **) argv);
	}
}
