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
  if (!message) return 0;
  NSAlert* alert = [self alertWithMessageText:message
                                defaultButton:NSLocalizedString(@"OK", @"")
                              alternateButton:nil
                                  otherButton:nil
                    informativeTextWithFormat:description ? description : @""];
  return [alert runModal];
}

+ (NSInteger) unsafePrompt:(NSString*)message description:(NSString*)description
{
  if (!message) return 0;
  NSAlert* alert = [NSAlert alertWithMessageText:message
                                   defaultButton:NSLocalizedString(@"Cancel", @"")
                                 alternateButton:NSLocalizedString(@"OK", @"")
                                     otherButton:nil
                       informativeTextWithFormat:description ? description : @""];
  return [alert runModal];
}

@end
