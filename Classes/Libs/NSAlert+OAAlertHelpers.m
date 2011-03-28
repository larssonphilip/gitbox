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

+ (BOOL) prompt:(NSString*)message description:(NSString*)description ok:(NSString*)okTitle window:(NSWindow*)aWindow
{
  if (!message) return NO;

  NSAlert* alert = [NSAlert alertWithMessageText:message
                                   defaultButton:okTitle
                                 alternateButton:NSLocalizedString(@"Cancel", @"")
                                     otherButton:nil
                       informativeTextWithFormat:description ? description : @""];
  
  if (!aWindow)
  {
    return ([alert runModal] == NSAlertDefaultReturn);
  }
  
  NSInteger result = NSAlertErrorReturn;
  [alert beginSheetModalForWindow:aWindow modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:&result];
  return (result == NSAlertDefaultReturn);
}

+ (void) alertDidEnd:(NSAlert*)alert returnCode:(NSInteger)returnCode contextInfo:(NSInteger*)resultRef
{
  *resultRef = returnCode;
}

+ (BOOL) prompt:(NSString*)message description:(NSString*)description ok:(NSString*)okTitle
{
  return [self prompt:message description:description ok:okTitle window:nil];
}

+ (BOOL) prompt:(NSString*)message description:(NSString*)description window:(NSWindow*)aWindow
{
  return [self prompt:message description:description ok:NSLocalizedString(@"OK", @"") window:aWindow];
}

+ (BOOL) prompt:(NSString*)message description:(NSString*)description
{
  return [self prompt:message description:description window:nil];
}



@end
