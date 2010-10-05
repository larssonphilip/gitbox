#import "NSObject+OADispatchItemValidation.h"
#import "NSString+OAStringHelpers.h"
#import <objc/runtime.h>

@implementation NSObject (OADispatchItemValidation)

- (BOOL) dispatchUserInterfaceItemValidation:(id<NSValidatedUserInterfaceItem>)anItem
{
  SEL anAction = anItem.action;
  
  if (!anAction) return NO;
  if (![self respondsToSelector:anAction]) return NO;
  
  NSString* validationActionName = [NSString stringWithFormat:@"validate%@", 
                                    [[NSString stringWithCString:sel_getName(anAction) 
                                                        encoding:NSASCIIStringEncoding] stringWithFirstLetterCapitalized]];
  
  SEL validationAction = (SEL)sel_getUid([validationActionName cStringUsingEncoding:NSASCIIStringEncoding]);
  
  if ([self respondsToSelector:validationAction])
  {
    return !![self performSelector:validationAction withObject:anItem];
  }
  return YES;
}


@end
