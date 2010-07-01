#import "NSAlert+OAAlertHelpers.h"

@implementation NSAlert (OAAlertHelpers)

+ (NSInteger) error:(NSError*)error
{
  if (!error) return 0;
  NSAlert* alert = [self alertWithMessageText:[error localizedDescription]
                                   defaultButton:NSLocalizedString(@"OK", @"")
                                 alternateButton:nil
                                     otherButton:nil
                       informativeTextWithFormat:@""];
  return [alert runModal];
}

+ (NSInteger) message:(NSString*)message
{
  return [self message:message description:@""];
}

+ (NSInteger) message:(NSString*)message description:(NSString*)description
{
  return [self message:message description:description buttonTitle:NSLocalizedString(@"OK", @"")];
}

+ (NSInteger) message:(NSString*)message description:(NSString*)description buttonTitle:(NSString*)buttonTitle
{
  if (!message) return 0;
  NSAlert* alert = [self alertWithMessageText:message
                                defaultButton:buttonTitle
                              alternateButton:nil
                                  otherButton:nil
                    informativeTextWithFormat:description ? description : @""];
  return [alert runModal];  
}

+ (BOOL) prompt:(NSString*)message description:(NSString*)description ok:(NSString*)okTitle
{
  if (!message) return 0;
  NSAlert* alert = [NSAlert alertWithMessageText:message
                                   defaultButton:okTitle
                                 alternateButton:NSLocalizedString(@"Cancel", @"")
                                     otherButton:nil
                       informativeTextWithFormat:description ? description : @""];
  
  return ([alert runModal] == NSAlertDefaultReturn);  
}

+ (BOOL) prompt:(NSString*)message description:(NSString*)description
{
  return [self prompt:message description:description ok:NSLocalizedString(@"OK", @"")];
}


@end
