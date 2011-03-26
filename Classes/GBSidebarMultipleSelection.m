#import "GBSidebarMultipleSelection.h"
#import "NSObject+OADispatchItemValidation.h"

// we will pass self as a dummy UI item when validating actions
@interface GBSidebarMultipleSelection () <NSValidatedUserInterfaceItem, NSUserInterfaceValidations>
@property(nonatomic, retain) NSArray* objects;
@property(nonatomic, assign) SEL action; // temporary property for NSValidatedUserInterfaceItem
- (BOOL) canPerformAction:(SEL)selector;
- (id) targetForAction:(SEL)selector inObject:(id)object;
@end

@implementation GBSidebarMultipleSelection

@synthesize objects;
@synthesize action;


- (void) dealloc
{
  self.objects = nil;
  [super dealloc];
}

+ (GBSidebarMultipleSelection*) selectionWithObjects:(NSArray*)objects
{
  GBSidebarMultipleSelection* obj = [[[GBSidebarMultipleSelection alloc] init] autorelease];
  obj.objects = objects;
  return obj;
}



// Dummy API for NSValidatedUserInterfaceItem

- (NSInteger)tag
{
  return 0;
}



// We support both styles of action handling: tryToPerform:with: and performSelector:withObject: (latter is used by NSApplication sendAction:...)

- (BOOL) tryToPerform:(SEL)selector with:(id)argument
{
  if ([super respondsToSelector:selector])
  {
    return [super tryToPerform:selector with:argument];
  }
  if ([self canPerformAction:selector])
  {
    [self performSelector:selector withObject:argument];
    return YES;
  }
  return [super tryToPerform:selector with:argument];
}

// If multiple selection responds to selector, then it gets opportunity to validate it.
// If any contained object (or its responder chain) implements selector, we handle it here.
- (BOOL) respondsToSelector:(SEL)selector
{
  if ([super respondsToSelector:selector]) return YES;

  BOOL atLeastOneItemResponds = NO;
  for (id obj in self.objects)
  {
    id target = [self targetForAction:selector inObject:obj];
    if (target) atLeastOneItemResponds = YES;
  }

  //NSLog(@"GBSidebarMultipleSelection: respondsToSelector:%@ = %d", NSStringFromSelector(selector), (int)atLeastOneItemResponds);
  return atLeastOneItemResponds;
}

- (id) performSelector:(SEL)selector withObject:(id)argument
{
  //NSLog(@"GBSidebarMultipleSelection: selector = %@", NSStringFromSelector(selector));
  if ([super respondsToSelector:selector]) return [super performSelector:selector withObject:argument];
  
  self.action = selector;
  
  for (id obj in self.objects)
  {
    NSLog(@"GBSidebarMultipleSelection: self: %@ obj: %@ selector: %@", self, obj, NSStringFromSelector(selector));
    id target = [self targetForAction:selector inObject:obj];
    NSLog(@"GBSidebarMultipleSelection: target %@ for selector %@", target, NSStringFromSelector(selector));
    if (target)
    {
      if (![target respondsToSelector:@selector(validateUserInterfaceItem:)] || 
          [(id<NSUserInterfaceValidations>)target validateUserInterfaceItem:self])
      {
        [target performSelector:selector withObject:argument];
      }
    }
  }
  return nil;
}

// returns NO if any object disables action within a multiple selection
// returns YES if any object (or responder down the chain) responds and validates the action
// returns NO in other cases
- (BOOL)validateUserInterfaceItem:(id < NSValidatedUserInterfaceItem >)item
{
  SEL selector = [item action];
  BOOL validatedAtLeastOneItem = NO;
  for (id obj in self.objects)
  {
    id target = [self targetForAction:selector inObject:obj];
    if (target)
    {
      if ([target respondsToSelector:@selector(validateActionForMultipleSelection:)])
      {
        if (![(id<GBSidebarMultipleSelectionItem>)target validateActionForMultipleSelection:selector]) return NO;
      }
      if ([target respondsToSelector:@selector(validateUserInterfaceItem:)])
      {
        if ([(id<NSUserInterfaceValidations>)target validateUserInterfaceItem:item]) validatedAtLeastOneItem = YES;
      }
      else // target implements the action, but does not implement validation -> always valid
      {
        validatedAtLeastOneItem = YES;
      }
    }
  }
  return validatedAtLeastOneItem;
}

- (BOOL) canPerformAction:(SEL)selector
{
  self.action = selector;
  return [self validateUserInterfaceItem:self];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
  return [self validateUserInterfaceItem:menuItem];
}


// This mimics the way NSApplication finds a target for action in a responder chain
- (id) targetForAction:(SEL)selector inObject:(id)object
{
  if (!object) return nil;
  if ([object respondsToSelector:selector]) return object;
  
  if ([object respondsToSelector:@selector(nextResponder)])
  {
    return [self targetForAction:selector inObject:[(NSResponder*)object nextResponder]];
  }
  
  return nil;
}

@end
