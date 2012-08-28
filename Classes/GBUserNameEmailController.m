#import "GBRepository.h"
#import "GBUserNameEmailController.h"

#import <AddressBook/AddressBook.h>

@implementation GBUserNameEmailController

@synthesize userName;
@synthesize userEmail;
@synthesize nameField;
@synthesize emailField;


- (IBAction) onOK:(id)sender
{
  self.userName = [self.nameField stringValue];
  self.userEmail = [self.emailField stringValue];

  if (!([self.userName length] > 0 && [self.userEmail length] > 3)) 
  {
    return;
  }

  [super onOK:sender];
}


- (void) fillWithAddressBookData
{
  ABPerson* person = [[ABAddressBook sharedAddressBook] me];
  NSString* firstName = [person valueForProperty:kABFirstNameProperty];
  NSString* lastName = [person valueForProperty:kABLastNameProperty];
  
  if (!firstName) firstName = @"";
  if (!lastName) lastName = @"";
  
  self.userName = [NSString stringWithFormat:@"%@ %@", firstName, lastName];
  
  ABMultiValue* emailMultiValue = [person valueForProperty:kABEmailProperty];
  if ([emailMultiValue count] > 0)
  {
    self.userEmail = [emailMultiValue valueAtIndex:0];
  }
}

- (void) updateWindow
{
  if (self.userName) [self.nameField setStringValue:self.userName];
  if (self.userEmail) [self.emailField setStringValue:self.userEmail];
}

- (void) windowDidResignKey:(NSNotification *)notification
{
  self.userName = [self.nameField stringValue];
  self.userEmail = [self.emailField stringValue];
}


@end
