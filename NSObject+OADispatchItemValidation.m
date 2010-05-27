#import "NSObject+OADispatchItemValidation.h"

@implementation NSObject (OADispatchItemValidation)

- (BOOL) dispatchUserInterfaceItemValidation:(id<NSValidatedUserInterfaceItem>)anItem
{
  SEL anAction = anItem.action;
  
  if (!anAction) return NO;
  
  NSString* validationActionName = [NSString stringWithFormat:@"validate%@", 
                                    [[NSString stringWithCString:sel_getName(anAction) 
                                                        encoding:NSASCIIStringEncoding] stringWithFirstLetterCapitalized]];
  
  SEL validationAction = sel_getUid([validationActionName cStringUsingEncoding:NSASCIIStringEncoding]);
  
  if ([self respondsToSelector:validationAction])
  {
    return !![self performSelector:validationAction withObject:anItem];
  }
  return YES;
}


@end
