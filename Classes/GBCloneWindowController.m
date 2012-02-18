#import "GBCloneWindowController.h"
#import "GBMainWindowController.h"
#import "NSFileManager+OAFileManagerHelpers.h"

@interface GBCloneWindowController ()
- (NSString*) urlStringFromTextField;
- (void) update;
@end

#define GBCloneWindowLastURLKey @"GBCloneWindowController-lastURL"


@implementation GBCloneWindowController

@synthesize urlField;
@synthesize nextButton;
@synthesize finishBlock;
@synthesize sourceURLString;
@synthesize targetDirectoryURL;
@synthesize targetURL;

- (void) dealloc
{
	self.urlField = nil;
	self.nextButton = nil;
	self.sourceURLString = nil;
	self.finishBlock = nil;
	self.targetDirectoryURL = nil;
	self.targetURL = nil;
	[super dealloc];
}

+ (void) setLastURLString:(NSString*)urlString
{
	[[NSUserDefaults standardUserDefaults] setObject:[[urlString copy] autorelease] forKey:GBCloneWindowLastURLKey];
}

- (void) start
{
	[[GBMainWindowController instance] presentSheet:[self window]];
}

- (IBAction) cancel:(id)sender
{
	[[GBMainWindowController instance] dismissSheet];
	self.finishBlock = nil;
}

- (IBAction) ok:(id)sender
{
	self.sourceURLString = [self urlStringFromTextField];
	
	if ([self.urlField stringValue])
	{
		[GBCloneWindowController setLastURLString:self.urlField.stringValue];
	}
	
	if (self.sourceURLString)
	{
		[[GBMainWindowController instance] dismissSheet];
		
		NSString* suggestedName = self.sourceURLString.lastPathComponent;
		suggestedName = [[suggestedName componentsSeparatedByString:@":"] lastObject]; // handle the case of "oleg.local:test.git"
		if (!suggestedName) suggestedName = @"";
		NSInteger dotgitlocation = 0;
		if (suggestedName && 
			[suggestedName length] > 4 && 
			(dotgitlocation = [suggestedName rangeOfString:@".git"].location) == ([suggestedName length] - 4))
		{
			suggestedName = [suggestedName substringToIndex:dotgitlocation];
		}
		
		NSSavePanel* panel = [NSSavePanel savePanel];
		[panel setMessage:self.sourceURLString];
		[panel setNameFieldLabel:NSLocalizedString(@"Clone To:", @"Clone")];
		[panel setNameFieldStringValue:suggestedName];
		[panel setPrompt:NSLocalizedString(@"Clone", @"Clone")];
		[panel setDelegate:self];
		[[GBMainWindowController instance] sheetQueueAddBlock:^{
			[panel beginSheetModalForWindow:[[GBMainWindowController instance] window] completionHandler:^(NSInteger result){
				[[GBMainWindowController instance] sheetQueueEndBlock];
				if (result == NSFileHandlingPanelOKButton)
				{
					self.targetDirectoryURL = [panel directoryURL];
					self.targetURL = [panel URL]; // this URL is interpreted as a file URL and breaks later
					self.targetURL = [NSURL fileURLWithPath:[self.targetURL path] isDirectory:YES]; // make it directory url explicitly
					
					if (self.targetDirectoryURL && self.targetURL)
					{
						if (self.finishBlock) self.finishBlock();
						self.finishBlock = nil;
						
						// Clean up for next use.
						[self.urlField setStringValue:@""];
						self.sourceURLString = nil;
						self.targetDirectoryURL = nil;
						self.targetURL = nil;
					}
				}
				else
				{
					[[GBMainWindowController instance] presentSheet:[self window]];
				}
			}];
		}];
	}
}

- (void) windowDidLoad
{
	[super windowDidLoad];
	[self update];
}

- (void)windowDidBecomeKey:(NSNotification *)notification
{
	NSString* lastURLString = [[NSUserDefaults standardUserDefaults] objectForKey:GBCloneWindowLastURLKey];
	if (lastURLString)
	{
		[self.urlField setStringValue:lastURLString];
		[self.urlField selectText:nil];
	}
	[self update];
}





#pragma mark NSTextFieldDelegate


- (void)controlTextDidChange:(NSNotification *)aNotification
{
	[self update];
}






#pragma mark NSOpenSavePanelDelegate


- (BOOL)panel:(NSSavePanel*)aPanel validateURL:(NSURL*)url error:(NSError **)outError
{
	return ![[NSFileManager defaultManager] fileExistsAtPath:[url path]];
}


- (NSString*)panel:(NSSavePanel*)aPanel userEnteredFilename:(NSString*)filename confirmed:(BOOL)okFlag
{
	if (okFlag) // on 10.6 we are still not receiving okFlag == NO, so I don't want to have this feature untested.
	{
		if ([[NSFileManager defaultManager] fileExistsAtPath:[[aPanel URL] path]]) return nil;
	}
	return filename;
}

- (void)panel:(NSSavePanel*)aPanel didChangeToDirectoryURL:(NSURL *)aURL
{
	NSString* enteredName = [aPanel nameFieldStringValue];
	NSString* uniqueName = enteredName;
	
	if (aURL && enteredName && [enteredName length] > 0)
	{
		NSString* targetPath = [[aPanel directoryURL] path];
		NSUInteger counter = 0;
		while ([[NSFileManager defaultManager] fileExistsAtPath:[targetPath stringByAppendingPathComponent:uniqueName]])
		{
			counter++;
			uniqueName = [enteredName stringByAppendingFormat:@"%d", counter];
		}
		[aPanel setNameFieldStringValue:uniqueName];
	}
}






#pragma mark Private



- (NSString*) urlStringFromTextField
{
	NSString* urlString = [self.urlField stringValue];
	if ([urlString isEqual:@""]) return nil;
	urlString = [urlString stringByReplacingOccurrencesOfString:@"git clone" withString:@""];
	urlString = [urlString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	
	if ([urlString rangeOfString:@"~/"].location == 0)
	{
		urlString = [urlString stringByReplacingOccurrencesOfString:@"~" withString:NSHomeDirectory()];
	}
	
	return urlString;
}


- (void) update
{
	[self.nextButton setEnabled:!![self urlStringFromTextField]];
}





@end
