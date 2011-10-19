#import "GBTask.h"
#import "GBAskPassController.h"
#import "GBAskPassServer.h"
#import "GBAskPassBooleanPromptController.h"
#import "GBAskPassCredentialsController.h"
#import "GBMainWindowController.h"

@interface GBAskPassController ()<GBAskPassServerClient>
@property(nonatomic, copy) NSString* askPassClientId;
@property(nonatomic, copy) NSString* currentPrompt;
@property(nonatomic, assign, readwrite, getter = isCancelled) BOOL cancelled;
@property(nonatomic, copy) void(^originalTaskBlock)();
@property(nonatomic, copy, readwrite) NSString* failureMessage;
@property(nonatomic, copy, readwrite) NSString* previousUsername;
@property(nonatomic, copy, readwrite) NSString* previousPassword;
@property(nonatomic, copy) id(^taskFactory)();
@property(nonatomic, readonly) NSString* keychainService;
@property(nonatomic, assign) int numberOfSilentFailures;

// Special properties to remove failing entry from the Keychain.
@property(nonatomic, assign) SecKeychainItemRef previousKeychainItemRef;
@property(nonatomic, copy) NSString* previousKeychainUsername;

- (void) bypass;
- (BOOL) loadCredentialsFromKeychain;
- (void) cleanupPreviousKeychainItem;
@end

@implementation GBAskPassController

@synthesize askPassClientId;
@synthesize currentPrompt;
@synthesize task;
@synthesize address;
@synthesize username;
@synthesize password;
@synthesize booleanResponse;
@synthesize silent;
@synthesize bypassFailedAuthentication;
@synthesize cancelled;
@synthesize delegate;
@synthesize originalTaskBlock;
@synthesize failureMessage;
@synthesize previousUsername;
@synthesize previousPassword;
@synthesize taskFactory;
@synthesize numberOfSilentFailures;

@synthesize previousKeychainItemRef;
@synthesize previousKeychainUsername;


- (void) dealloc
{
	[askPassClientId release]; askPassClientId = nil;
	[currentPrompt release]; currentPrompt = nil;
	[task release]; task = nil;
	[address release]; address = nil;
	[username release]; username = nil;
	[password release]; password = nil;
	[booleanResponse release]; booleanResponse = nil;
	[originalTaskBlock release]; originalTaskBlock = nil;
	[failureMessage release]; failureMessage = nil;
	[previousUsername release]; previousUsername = nil;
	[previousPassword release]; previousPassword = nil;
	[taskFactory release]; taskFactory = nil;
	if (previousKeychainItemRef) CFRelease(previousKeychainItemRef);
	previousKeychainItemRef = NULL;
	[previousKeychainUsername release]; previousKeychainUsername = nil;
	[super dealloc];
}

+ (id) launchedControllerWithAddress:(NSString*)address taskFactory:(id(^)())taskFactory
{
	return [self launchedControllerWithAddress:address silent:NO taskFactory:taskFactory];
}

+ (id) launchedControllerWithAddress:(NSString*)address silent:(BOOL)silent taskFactory:(id(^)())taskFactory
{
	GBAskPassController* ctrl = [[[self alloc] init] autorelease];
	ctrl.address = address;
	ctrl.silent = silent;
	ctrl.taskFactory = taskFactory;
	ctrl.task = taskFactory();
	[ctrl.task launch];
	return ctrl;
}

- (id) init
{
	if ((self = [super init]))
	{
		self.askPassClientId = [NSString stringWithFormat:@"GBAskPassController:%p", self];
		self.delegate = self;
		[[GBAskPassServer sharedServer] addClient:self];
	}
	return self;
}

// FIXME: there is a gross bug with controller being released when dialog finishes, but the task is still running.

- (void) setTask:(GBTask *)newTask
{
	if (task == newTask) return;
	
	[[self retain] autorelease]; // protect self while switching blocks
	
	if (task)
	{
		task.didTerminateBlock = self.originalTaskBlock;
		[task release];
		task = nil;
	}
	
	self.originalTaskBlock = nil;
	
	if (newTask)
	{
		task = [newTask retain];
		
		NSString* pathToAskpass = [[NSBundle mainBundle] executablePath]; // launching the same executable which will act as askpass with GBAskPassServerNameKey
		
		[task mergeEnvironment:[NSDictionary dictionaryWithObjectsAndKeys:
								pathToAskpass, @"GIT_ASKPASS",
								pathToAskpass, @"SSH_ASKPASS",
								[GBAskPassServer sharedServer].name, GBAskPassServerNameKey,
								self.askPassClientId, GBAskPassClientIdKey,
								nil]];
		
		self.originalTaskBlock = task.didTerminateBlock;
		if (!self.originalTaskBlock)
		{
			[NSException raise:@"GBAskPassController requires task with block" format:@"didTerminateBlock should not be nil when task is wrapped with GBAskPassController"];
		}
		
		task.didTerminateBlock = ^{
			if (![task isError] || self.bypassFailedAuthentication) // if no error occured or we should bypass it, simply call original block
			{
				[self bypass];
				return;
			}
			
			// Sample output values:
			//   ERROR: Permission to rails/rails.git denied to oleganza.
			//   Permission denied (publickey)
			//   fatal: Authentication failed
			
			NSString* output = [[task UTF8ErrorAndOutput] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
			if ([[output lowercaseString] rangeOfString:@"permission"].length > 0 || 
				[[output lowercaseString] rangeOfString:@"authentication"].length > 0)
			{
				self.numberOfSilentFailures += 1;
				if (self.numberOfSilentFailures > 10)
				{
					NSLog(@"GBAskPassController: repeated error detected: %@ (giving up and calling task's block)", output);
					[self bypass];
					return;
				}
				self.failureMessage = output;
				self.previousUsername = self.username;
				self.previousPassword = self.password;
				
				// reset state
				self.username = nil;
				self.password = nil;
				self.booleanResponse = nil;
				self.currentPrompt = nil;
				
				// Auth failed, try to launch the task again, but this time without using keychain.
                
				GBTask* anotherTask = self.taskFactory();
				self.task = anotherTask;
				
				[self.task launch];
			}
			else // unknown error, bypass
			{
				NSLog(@"GBAskPassController: unknown error: %@ (giving up and calling task's block)", output);
				[self bypass];
				return;
			}
		};
	}
}

- (NSString*) keychainService
{
	return [NSString stringWithFormat:@"Gitbox: %@", self.address];
}



#pragma mark GBAskPassServerClient


- (NSString*) resultForClient:(NSString*)clientId prompt:(NSString*)prompt environment:(NSDictionary*)environment
{
	if (![self.askPassClientId isEqualToString:clientId]) return nil;
    
	BOOL repeatedPrompt = (self.currentPrompt && [self.currentPrompt isEqualToString:prompt]);
	self.currentPrompt = prompt;
	
	//NSLog(@"PROMPT: %@ [%@]", prompt, clientId);
	NSString* noString = @"no";
	NSString* yesString = @"yes";
	
	// Special case: when gitosis server is rebooting, SSH issues some strange ask pass invocations with no prompt.
	if (!prompt || prompt.length < 1)
	{
		return @"";
	}
	
	if ([[prompt lowercaseString] rangeOfString:@"yes/no"].length > 0)
	{
		if ([self isCancelled])
		{
			return noString;
		}
		
		if (self.booleanResponse)
		{
			return ([self.booleanResponse boolValue] ? yesString : noString);
		}
		
		if (self.silent)
		{
			[self cancel];
			return nil;
			
		}
		
		if (!repeatedPrompt)
		{
			[self.delegate askPass:self presentBooleanPrompt:prompt];
			return nil;
		}
	}
	
	if ([self isCancelled])
	{
		return @"";
	}
	
	if ([[prompt lowercaseString] rangeOfString:@"username:"].length > 0)
	{
		if (self.username)
		{
			return self.username;
		}
		
		if (!self.failureMessage)
		{
			if ([self loadCredentialsFromKeychain]) // if failed to load, falls back to UI dialog
			{
				if (self.username) return self.username;
			}
		}
		
		if (self.silent)
		{
			[self cancel];
			return nil;
		}
		
		if (!repeatedPrompt)
		{
			[self.delegate askPassPresentUsernamePrompt:self];
		}
	}
	else
	{
		if (self.password)
		{
			return self.password;
		}
		
		if (!self.failureMessage)
		{
			if ([self loadCredentialsFromKeychain]) // if failed to load, falls back to UI dialog
			{
				if (self.password) return self.password;
			}
		}
		
		if (self.silent)
		{
			[self cancel];
			return nil;
		}
		
		if (!repeatedPrompt)
		{
			[self.delegate askPassPresentPasswordPrompt:self];
		}
	}
	
	return nil;
}

- (void) cancel
{
	self.cancelled = YES;
	self.bypassFailedAuthentication = YES;
	[self cleanupPreviousKeychainItem]; // when cancelled, clean up previously loaded keychain item (it is almost certainly is invalid)
}

- (BOOL) loadCredentialsFromKeychain
{
	const char* serviceCString = [self.keychainService cStringUsingEncoding:NSUTF8StringEncoding];
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
							NSString* newUsername = [[[NSString alloc] initWithBytes:attr.data length:attr.length encoding:NSUTF8StringEncoding] autorelease];
							if (self.username && newUsername && ![newUsername isEqualToString:self.username])
							{
								NSLog(@"ERROR: [GBAskPass loadCredentialsFromKeychain]: inconsistent username is retrieved from Keychain (already had %@, got %@)", self.username, newUsername);
							}
							self.username = newUsername;
							break;
						}
					}
					self.previousKeychainUsername = self.username;
					self.previousKeychainItemRef = itemRef;
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

- (void) cleanupPreviousKeychainItem
{
	if (self.previousKeychainItemRef)
	{
		SecKeychainItemDelete(self.previousKeychainItemRef);
		self.previousKeychainItemRef = NULL;
		self.previousUsername = nil;
	}
}

- (BOOL) storeCredentialsInKeychain
{
	if (self.previousKeychainItemRef)
	{
		// If we have previously loaded keychain data and now storing another username, we should remove the previous entry.
		if (self.username && self.previousKeychainUsername && ![self.username isEqualToString:self.previousKeychainUsername])
		{
			[self cleanupPreviousKeychainItem];
		}
	}
	
	NSString* account = self.username;
	if (!account || [account length] < 1)
	{
		// Try to get username from NSURL
		NSURL* url = [NSURL URLWithString:self.address];
		account = [url user];
	}
	if (!account || [account length] < 1)
	{
		account = @"default";
	}
	
	const char* serviceCString = [self.keychainService cStringUsingEncoding:NSUTF8StringEncoding];
	const char* usernameCString = [account cStringUsingEncoding:NSUTF8StringEncoding];
	const char* passwordCString = [self.password cStringUsingEncoding:NSUTF8StringEncoding];
	
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



#pragma mark Private


- (void) bypass
{
	[self retain];
	[[GBAskPassServer sharedServer] removeClient:self];
	if (self.originalTaskBlock) self.originalTaskBlock();
	self.originalTaskBlock = nil;
	[self release];
	return;
}




#pragma GBAskPassControllerDelegate - controller is a delegate for itself by default



- (void) askPass:(GBAskPassController*)askPassController presentBooleanPrompt:(NSString*)prompt
{
	prompt = [prompt stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
	prompt = [prompt stringByReplacingOccurrencesOfString:@" (yes/no)?" withString:@"?"];
	
	GBAskPassBooleanPromptController* ctrl = [GBAskPassBooleanPromptController controller];
	ctrl.address = self.address;
	ctrl.question = prompt;
	ctrl.callback = ^(BOOL result) {
		askPassController.booleanResponse = [NSNumber numberWithBool:result];
		[[GBMainWindowController instance] dismissSheet:ctrl];
	};
	[[GBMainWindowController instance] presentSheet:ctrl];
	[NSApp requestUserAttention:NSCriticalRequest];
}

- (void) askPassPresentUsernamePrompt:(GBAskPassController*)askPassController
{
	GBAskPassCredentialsController* ctrl = [GBAskPassCredentialsController controller];
	ctrl.address = askPassController.address;
	ctrl.username = askPassController.previousUsername;
	ctrl.callback = ^(BOOL promptCancelled) {
		if (promptCancelled)
		{
			[askPassController cancel];
		}
		else
		{
			askPassController.username = ctrl.username;
			askPassController.password = ctrl.password;
			[askPassController storeCredentialsInKeychain];
		}
		[[GBMainWindowController instance] dismissSheet:ctrl];
	};
	[[GBMainWindowController instance] presentSheet:ctrl];
	[NSApp requestUserAttention:NSCriticalRequest];
}

- (void) askPassPresentPasswordPrompt:(GBAskPassController*)askPassController
{
	GBAskPassCredentialsController* ctrl = [GBAskPassCredentialsController passwordOnlyController];
	ctrl.address = askPassController.address;
	ctrl.callback = ^(BOOL promptCancelled) {
		if (promptCancelled)
		{
			[askPassController cancel];
		}
		else
		{
			askPassController.password = ctrl.password;
			[askPassController storeCredentialsInKeychain];
		}
		[[GBMainWindowController instance] dismissSheet:ctrl];
	};
	[[GBMainWindowController instance] presentSheet:ctrl];
	[NSApp requestUserAttention:NSCriticalRequest];
}

- (void) setPreviousKeychainItemRef:(SecKeychainItemRef)newPreviousKeychainItemRef
{
	if (previousKeychainItemRef == newPreviousKeychainItemRef) return;
	
	if (previousKeychainItemRef) CFRelease(previousKeychainItemRef);
	previousKeychainItemRef = newPreviousKeychainItemRef;
	if (previousKeychainItemRef) CFRetain(previousKeychainItemRef);
}




@end
