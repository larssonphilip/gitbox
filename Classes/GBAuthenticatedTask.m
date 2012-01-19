#import "GBAuthenticatedTask.h"
#import "GBAskPassServer.h"

#import "GBMainWindowController.h"
#import "GBAskPassBooleanPromptController.h"
#import "GBAskPassCredentialsController.h"

@interface GBAuthenticatedTask ()<GBAskPassServerClient>
@property(nonatomic, copy) NSString* askPassClientId;
@property(nonatomic, readwrite) BOOL authenticationFailed;
@property(nonatomic, readwrite) BOOL authenticationCancelledByUser;

// user-provided or loaded from keychain
@property(nonatomic, copy) NSString* password;

- (void) presentBooleanPrompt:(NSString*)prompt;
- (void) presentUsernamePrompt:(NSString*)prompt;
- (void) presentPasswordPrompt:(NSString*)prompt;

- (NSString*) keychainServiceName;
- (void) deleteKeychainItem;
- (BOOL) loadCredentialsFromKeychain;
- (void) storeCredentialsInKeychain;

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


- (void)dealloc
{
	if (keychainItem) CFRelease(keychainItem);
	
	[_remoteAddress release];
	
    [_askPassClientId release];
	[_username release];
	[_password release];

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
		[self presentUsernamePrompt:self];
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
		[self presentPasswordPrompt:self];
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
	// TODO: ...
}

- (void) storeCredentialsInKeychain
{
	// First, find and remove the exiting keychain item, otherwise bad things happen.
	if (!keychainItem)
	{
		[self loadCredentialsFromKeychain];
	}
	[self deleteKeychainItem];
	
	// TODO: store username and password.
}


@end
