#ifdef __OBJC__
	#if __has_feature(objc_arc)
		#define GB_RETAIN_AUTORELEASE(x)
	#else
		#define GB_RETAIN_AUTORELEASE(x) [[x retain] autorelease]
	#endif
	#import "NSObject+OAResponderChain.h"
	#import "OAAreEqual.h"

	#import <objc/runtime.h>
#endif
