#import "NSObject+OAResponderChain.h"

@implementation NSObject (OAResponderChain)

// Returns array of next responders
- (NSArray*) OAResponderChain
{
	if (![self respondsToSelector:@selector(nextResponder)])
	{
		return [NSArray array];
	}
	NSResponder* nr = [(id)self nextResponder];
	if (!nr)
	{
		return [NSArray array];
	}
	NSArray* rest = [nr OAResponderChain];
	return [[NSArray arrayWithObject:nr] arrayByAddingObjectsFromArray:rest];
}


@end
