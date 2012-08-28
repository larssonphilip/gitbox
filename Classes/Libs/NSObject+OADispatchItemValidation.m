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
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    return !![self performSelector:validationAction withObject:anItem];
#pragma clang diagnostic pop
  }
  return YES;
}


@end
