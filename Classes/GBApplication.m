#import "GBApplication.h"

@implementation GBApplication {
	int ignoreUserAttentionRequests;
}

@synthesize didTerminateSafely;

- (void) beginIgnoreUserAttentionRequests
{
	ignoreUserAttentionRequests++;
}

- (void) endIgnoreUserAttentionRequests
{
	ignoreUserAttentionRequests--;
}

- (NSInteger)requestUserAttention:(NSRequestUserAttentionType)requestType
{
	if (ignoreUserAttentionRequests)
	{
		return 0;
	}
	return [super requestUserAttention:requestType];
}


@end
