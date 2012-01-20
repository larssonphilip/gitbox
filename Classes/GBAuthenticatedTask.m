#import "GBAuthenticatedTask.h"
#import "GBAskPassServer.h"
#import "GBMainWindowController.h"
#import "GBAskPassBooleanPromptController.h"
#import "GBAskPassCredentialsController.h"

@interface GBAuthenticatedTask ()<GBAskPassServerClient>
@property(nonatomic, copy) NSString* askPassClientId;
@property(nonatomic, readwrite) BOOL authenticationFailed;
@property(nonatomic, readwrite) BOOL authenticationCancelledByUser;
@property(nonatomic, retain) NSNumber* booleanResponse;

// user-provided or loaded from keychain
@property(nonatomic, copy) NSString* password;

- (void) presentBooleanPrompt:(NSString*)prompt;
- (void) presentUsernamePrompt:(NSString*)prompt;
- (void) presentPasswordPrompt:(NSString*)prompt;

- (NSString*) keychainServiceName;
- (void) deleteKeychainItem;
- (BOOL) loadCredentialsFromKeychain;
- (BOOL) storeCredentialsInKeychain;

@end

@implementation GBAuthenticatedTask {
	SecKeychainItemRef keychainItem;
	BOOL displayingPrompt;
}

@synthesize remoteAddress=_remoteAddress;
@synthesize silent=_silent;
@synthesize authenticationFailed=_authenticationFailed;
@synthesize authenticationCancelledByUser=_authenticationCancelledByUser;

@synthesize askPassClientId=_askPassClientId;
@synthesize username=_username;
@synthesize password=_password;
@synthesize booleanResponse = _booleanResponse;


- (void)dealloc
{
	if (keychainItem) CFRelease(keychainItem);
	
	[_remoteAddress release];
	
    [_askPassClientId release];
	[_username release];
	[_password release];

    [_booleanResponse release];
    [super dealloc];
}

- (id)init
{
	if (self = [super init])
	{
	}
	return self;
}




#pragma mark - OATask start and finish

- (void) willLaunchTask
{
	self.askPassClientId = [NSString stringWithFormat:@"GBAuthenticatedTask:%p:%f", self, drand48()];
	
	NSString* pathToAskpass = [[NSBundle mainBundle] executablePath]; // launching the same executable which will act as askpass with GBAskPassServerNameKey
	
	[self mergeEnvironment:[NSDictionary dictionaryWithObjectsAndKeys:
							pathToAskpass, @"GIT_ASKPASS",
							pathToAskpass, @"SSH_ASKPASS",
							[GBAskPassServer sharedServer].name, GBAskPassServerNameKey,
							self.askPassClientId, GBAskPassClientIdKey,
							nil]];

	// Subscribe to AskPass server to receive requests for user input (username, passwords, yes/no answer).
	[[GBAskPassServer sharedServer] addClient:self];

	[super willLaunchTask];
}

- (void) didFinish
{
	// First of all, unsubscribe from AskPass server as we don't want to be forever hooked to it.
	[[GBAskPassServer sharedServer] removeClient:self];
	
	if ([self isError])
	{	
		// Sample output values:
		//   ERROR: Permission to rails/rails.git denied to oleganza.
		//   Permission denied (publickey)
		//   fatal: Authentication failed
		
		NSString* output = [[self UTF8ErrorAndOutput] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		if ([[output lowercaseString] rangeOfString:@"permission"].length > 0 || 
			[[output lowercaseString] rangeOfString:@"authentication"].length > 0)
		{
			// Set the failure flag for the client.
			self.authenticationFailed = YES;
			
			// Delete keychain item (if present).
			[self deleteKeychainItem];
		}
		else // unknown error, bypass
		{
			NSLog(@"GBAskPassController: unknown error: %@ (giving up and calling task's block)", output);
			return;
		}
	}
	
	[super didFinish];
}






#pragma mark - GBAskPassServerClient callback




// This is a callback from GBAskPassServer to respond to the running task.
- (NSString*) resultForClient:(NSString*)clientId prompt:(NSString*)prompt environment:(NSDictionary*)environment
{
	// Check if we are correctly addressed (just for good measure)
	if (![self.askPassClientId isEqualToString:clientId]) return nil;
	
	//NSLog(@"GBAuthenticatedTask: prompt: %@ [%@]", prompt, clientId);
	NSString* stringNO = @"no";
	NSString* stringYES = @"yes";
	
	// Special case: when gitosis server is rebooting, SSH issues some strange ask pass invocations with no prompt.
	if (!prompt || prompt.length < 1)
	{
		return @"";
	}
	
	// Example: "Add this host to the list of known hosts? yes/no"
	if ([prompt.lowercaseString rangeOfString:@"yes/no"].length > 0)
	{
		// Was cancelled by user, return NO.
		if (self.isAuthenticationCancelledByUser)
		{
			return stringNO;
		}
		
		// For silent tasks return NO without presenting UI.
		if (self.isSilent)
		{
			return stringNO;
		}
		
		// Was answered by user, return the answer.
		if (self.booleanResponse)
		{
			return ([self.booleanResponse boolValue] ? stringYES : stringYES);
		}
		
		// Has not been answered yet: present a prompt.
		[self presentBooleanPrompt:prompt];
		return nil;
	}
	
	// User cancelled the prompt, return the empty string.
	if (self.isAuthenticationCancelledByUser)
	{
		return @"";
	}
	
	if ([prompt.lowercaseString rangeOfString:@"username:"].length > 0)
	{
		// Username was provided using the prompt.
		if (self.username)
		{
			return self.username;
		}
		
		// Do we have something in Keychain? 
		if ([self loadCredentialsFromKeychain])
		{
			if (self.username) return self.username;
		}
		
		// If Keychain did not help and we should be silent, return empty string.
		if (self.isSilent)
		{
			return @"";
		}
		
		// Nothing in Keychain, ask the user.
		[self presentUsernamePrompt:prompt];
		return nil;
	}
	else // not a username: prompt
	{
		// Password was provided using the prompt
		if (self.password)
		{
			return self.password;
		}
		
		// Do we have something in Keychain? 
		if ([self loadCredentialsFromKeychain])
		{
			if (self.password) return self.password;
		}
		
		// If Keychain did not help and we should be silent, return empty string.
		if (self.isSilent)
		{
			return @"";
		}

		// Nothing in Keychain, ask the user.
		[self presentPasswordPrompt:prompt];
		return nil;
	}
	
	// By default we return nil which means a delayed answer. We'll be asked again later.
	return nil;
}





#pragma mark - User Prompts




- (void) presentBooleanPrompt:(NSString*)prompt
{
	if (displayingPrompt) return;
	displayingPrompt = YES;
	
	prompt = [prompt stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
	prompt = [prompt stringByReplacingOccurrencesOfString:@" (yes/no)?" withString:@"?"];
	
	GBAskPassBooleanPromptController* ctrl = [GBAskPassBooleanPromptController controller];
	ctrl.address = self.remoteAddress;
	ctrl.question = prompt;
	ctrl.callback = ^(BOOL result) {
		self.booleanResponse = [NSNumber numberWithBool:result];
		displayingPrompt = NO;
		[[GBMainWindowController instance] dismissSheet:ctrl];
	};
	[[GBMainWindowController instance] presentSheet:ctrl];
	[NSApp requestUserAttention:NSCriticalRequest];
}


- (void) presentUsernamePrompt:(NSString*)prompt
{
	if (displayingPrompt) return;
	displayingPrompt = YES;

	GBAskPassCredentialsController* ctrl = [GBAskPassCredentialsController controller];
	ctrl.address = self.remoteAddress;
	ctrl.username = self.username;
	ctrl.callback = ^(BOOL promptCancelled) {
		if (promptCancelled)
		{
			self.authenticationCancelledByUser = YES;
		}
		else
		{
			self.username = ctrl.username;
			self.password = ctrl.password;
			[self storeCredentialsInKeychain];
		}
		displayingPrompt = NO;
		[[GBMainWindowController instance] dismissSheet:ctrl];
	};
	[[GBMainWindowController instance] presentSheet:ctrl];
	[NSApp requestUserAttention:NSCriticalRequest];

}

- (void) presentPasswordPrompt:(NSString*)prompt
{
	if (displayingPrompt) return;
	displayingPrompt = YES;

	GBAskPassCredentialsController* ctrl = [GBAskPassCredentialsController passwordOnlyController];
	ctrl.address = self.remoteAddress;
	ctrl.callback = ^(BOOL promptCancelled) {
		if (promptCancelled)
		{
			self.authenticationCancelledByUser = YES;
		}
		else
		{
			self.password = ctrl.password;
			[self storeCredentialsInKeychain];
		}
		displayingPrompt = NO;
		[[GBMainWindowController instance] dismissSheet:ctrl];
	};
	[[GBMainWindowController instance] presentSheet:ctrl];
	[NSApp requestUserAttention:NSCriticalRequest];
}





#pragma mark - Keychain Routines



- (NSString*) keychainServiceName
{
	return [NSString stringWithFormat:@"Gitbox: %@", self.remoteAddress];
}

- (void) deleteKeychainItem
{
	if (keychainItem)
	{
		SecKeychainItemDelete(keychainItem);
		CFRelease(keychainItem);
		keychainItem = NULL;
	}
}

- (BOOL) loadCredentialsFromKeychain
{
	const char* serviceCString = [self.keychainServiceName cStringUsingEncoding:NSUTF8StringEncoding];
	const char* usernameCString = [self.username cStringUsingEncoding:NSUTF8StringEncoding];
	
	if (serviceCString == NULL)
	{
		NSLog(@"GBAskPassController: serviceCString is NULL, cannot store credentials in Keychain.");
		return NO;
	}
	
	SecKeychainSearchRef search = NULL;
	SecKeychainItemRef itemRef = NULL;
	SecKeychainAttributeList list;
	SecKeychainAttribute attributes[2];
	
	attributes[0].tag = kSecServiceItemAttr;
	attributes[0].data = (void*)serviceCString;
	attributes[0].length = strlen(serviceCString);
	
	list.count = 1;
	list.attr = attributes;
	
	// Add username to the list of attributes
	if (usernameCString)
	{
		attributes[1].tag = kSecAccountItemAttr;
		attributes[1].data = (void*)usernameCString;
		attributes[1].length = strlen(usernameCString);
		
		list.count = 2;
	}
	
	// We cannot use a simple call like FindGenericPassword because it does not return attributes like account (username).
	// If we don't know the username, we should use more general API to find an entry for a given service and fetch its attributes (with username) and content (a password).
	
	OSStatus status = SecKeychainSearchCreateFromAttributes(NULL, kSecGenericPasswordItemClass, &list, &search);
	
	BOOL succeed = YES;
	if (status == errSecSuccess)
	{
		status = SecKeychainSearchCopyNext(search, &itemRef);
		
		if (status == errSecSuccess)
		{
			// To fetch the attributes, we need to prepare a list of available attributes.
			// Apparently, itemID is the same as item class. http://lists.apple.com/archives/apple-cdsa/2008/Nov/msg00049.html
			
			SecKeychainAttributeInfo* attrInfoRef = NULL;
			
			status = SecKeychainAttributeInfoForItemID(NULL, CSSM_DL_DB_RECORD_GENERIC_PASSWORD, &attrInfoRef);
			if (status == errSecSuccess)
			{
				SecKeychainAttributeList* attrListRef = NULL;
				UInt32 itemDataLength = 0;
				void* itemData = NULL;
				status = SecKeychainItemCopyAttributesAndData(
															  itemRef, 
															  attrInfoRef, 
															  NULL, // returned itemClass; not interested
															  &attrListRef, 
															  &itemDataLength, 
															  &itemData);
				
				if (status == errSecSuccess)
				{
					if (itemData)
					{
						self.password = [[[NSString alloc] initWithBytes:itemData length:itemDataLength encoding:NSUTF8StringEncoding] autorelease];
					}
					
					// Iterate over all attributes and collect username
					for (int i = 0; i < attrListRef->count; i++)
					{
						SecKeychainAttribute attr = attrListRef->attr[i];
						if (attr.tag == kSecAccountItemAttr)
						{
							NSString* aUsername = [[[NSString alloc] initWithBytes:attr.data length:attr.length encoding:NSUTF8StringEncoding] autorelease];
							if (self.username && aUsername && ![aUsername isEqualToString:self.username])
							{
								NSLog(@"ERROR: [GBAskPass loadCredentialsFromKeychain]: inconsistent username is retrieved from Keychain (already had %@, got %@)", self.username, aUsername);
							}
							
							self.username = aUsername;
							break;
						}
					}
					if (keychainItem) CFRelease(keychainItem);
					if (itemRef) CFRetain(itemRef);
					keychainItem = itemRef;
				}
				else
				{
					CFStringRef statusStr = SecCopyErrorMessageString(status, NULL);
					NSLog(@"ERROR: [GBAskPass loadCredentialsFromKeychain]: SecKeychainItemCopyAttributesAndData failed: %@", (NSString*)statusStr);
					CFRelease(statusStr);
					succeed = NO;
				}
				SecKeychainItemFreeAttributesAndData(attrListRef, itemData); // TODO: handle error code here
			}
			else
			{
				CFStringRef statusStr = SecCopyErrorMessageString(status, NULL);
				NSLog(@"ERROR: [GBAskPass loadCredentialsFromKeychain]: SecKeychainAttributeInfoForItemID failed: %@", (NSString*)statusStr);
				CFRelease(statusStr);
				succeed = NO;
			}
			// TODO: handle error code here
			if (attrInfoRef) SecKeychainFreeAttributeInfo(attrInfoRef);
		}
		else if (status == errSecItemNotFound)
		{
			// Silently return NO if no item exists in Keychain yet.
			succeed = NO;
		}
		else
		{
			CFStringRef statusStr = SecCopyErrorMessageString(status, NULL);
			NSLog(@"ERROR: [GBAskPass loadCredentialsFromKeychain]: SecKeychainSearchCopyNext failed: %@", (NSString*)statusStr);
			CFRelease(statusStr);
			succeed = NO;
		}
		
		if (itemRef) CFRelease(itemRef);
	}
	else
	{
		CFStringRef statusStr = SecCopyErrorMessageString(status, NULL);
		NSLog(@"ERROR: [GBAskPass loadCredentialsFromKeychain]: SecKeychainSearchCreateFromAttributes failed: %@", (NSString*)statusStr);
		CFRelease(statusStr);
		succeed = NO;
	}
	
	if (search) CFRelease(search);
	
	return succeed;
}

- (BOOL) storeCredentialsInKeychain
{
	// Store username and password.
	
	NSString* account = self.username;
	if (!account || [account length] < 1)
	{
		// Try to get username from NSURL
		NSURL* url = [NSURL URLWithString:self.remoteAddress];
		account = [url user];
	}
	if (!account || [account length] < 1)
	{
		account = @"default";
	}
	
	const char* serviceCString = [self.keychainServiceName cStringUsingEncoding:NSUTF8StringEncoding];
	const char* usernameCString = [account cStringUsingEncoding:NSUTF8StringEncoding];
	const char* passwordCString = [self.password cStringUsingEncoding:NSUTF8StringEncoding];

	
	// Now we have local copy of username it's safe to load and remove the exiting keychain item.
	if (!keychainItem)
	{
		[self loadCredentialsFromKeychain];
	}
	[self deleteKeychainItem];
	
	
	
	if (serviceCString == NULL)
	{
		NSLog(@"GBAskPassController: serviceCString is NULL, cannot store credentials in Keychain.");
		return NO;
	}
	
	if (usernameCString == NULL)
	{
		NSLog(@"GBAskPassController: usernameCString is NULL, cannot store credentials in Keychain.");
		return NO;
	}
	
	if (passwordCString == NULL)
	{
		NSLog(@"GBAskPassController: passwordCString is NULL, cannot store credentials in Keychain.");
		return NO;
	}
	
	SecKeychainAttribute attributes[2];
	SecKeychainAttributeList list;
	
	attributes[0].tag = kSecServiceItemAttr;
	attributes[0].data = (void*)serviceCString;
	attributes[0].length = strlen(serviceCString);
	
	attributes[1].tag = kSecAccountItemAttr;
	attributes[1].data = (void*)usernameCString;
	attributes[1].length = strlen(usernameCString);
    
	list.count = 2;
	list.attr = attributes;
	
	OSStatus status = SecKeychainItemCreateFromContent(
													   kSecGenericPasswordItemClass, 
													   &list,
													   (UInt32) strlen(passwordCString),
													   passwordCString,
													   NULL,
													   NULL,
													   NULL);
	
	BOOL succeed = YES;
	if (status != errSecSuccess)
	{
		if (status == errSecDuplicateItem)
		{
			// The item already exists, lets update it.
			
			// First we need to find an existing item.
			
			SecKeychainItemRef itemRef = NULL;
			
			status = SecKeychainFindGenericPassword(
													NULL,
													strlen(serviceCString),
													serviceCString,
													strlen(usernameCString),
													usernameCString,
													0,
													NULL,
													&itemRef
													);
			
			if (status == errSecSuccess)
			{
				status = SecKeychainItemModifyAttributesAndData (
																 itemRef,
																 &list,
																 (UInt32)strlen(passwordCString),
																 passwordCString
																 );
				if (status != errSecSuccess)
				{
					CFStringRef statusStr = SecCopyErrorMessageString(status, NULL);
					NSLog(@"ERROR: [GBAskPass storeCredentialsInKeychain]: SecKeychainItemModifyAttributesAndData failed: %@", (NSString*)statusStr);
					CFRelease(statusStr);
					succeed = NO;
				}
			}
			else
			{
				CFStringRef statusStr = SecCopyErrorMessageString(status, NULL);
				NSLog(@"ERROR: [GBAskPass storeCredentialsInKeychain]: SecKeychainFindGenericPassword failed: %@", (NSString*)statusStr);
				CFRelease(statusStr);
				succeed = NO;
			}
			
			if (itemRef) CFRelease(itemRef);
		}
		else
		{
			CFStringRef statusStr = SecCopyErrorMessageString(status, NULL);
			NSLog(@"ERROR: [GBAskPass storeCredentialsInKeychain]: SecKeychainItemCreateFromContent failed: %@", (NSString*)statusStr);
			CFRelease(statusStr);
			succeed = NO;
		}
	}
    
	return succeed;
}


@end
