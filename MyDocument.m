#import "MyDocument.h"
#import "MyWindowController.h"

@implementation MyDocument

+ (BOOL)isNativeType:(NSString *)aType
{
  NSLog(@"isNativeType: %@", aType);
  return [super isNativeType:aType];
}

+ (NSArray *)readableTypes
{
  id ts = [super readableTypes];
  NSLog(@"readableTypes: %@", ts);
  return ts;
}

- (id)init
{
  if (self = [super init])
  {
    // Add your subclass-specific initialization here.
    // If an error occurs here, send a [self release] message and return nil.
  }
  return self;
}

- (void)makeWindowControllers 
{
  MyWindowController* windowController = [[[MyWindowController alloc] initWithWindowNibName:@"MyDocument"] autorelease];
  [self addWindowController:windowController];
}


- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
    [super windowControllerDidLoadNib:aController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
}

//- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
//{
//    // Insert code here to write your document to data of the specified type. If the given outError != NULL, ensure that you set *outError when returning nil.
//
//    // You can also choose to override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
//
//    // For applications targeted for Panther or earlier systems, you should use the deprecated API -dataRepresentationOfType:. In this case you can also choose to override -fileWrapperRepresentationOfType: or -writeToFile:ofType: instead.
//
//    if ( outError != NULL ) {
//		*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
//	}
//	return nil;
//}

//- (BOOL) readFromFileWrapper:(NSFileWrapper*) fileWrapper 
//                      ofType:(NSString*) typeName 
//                       error:(NSError**)outError
// NSLog(@"readFromFileWrapper:%@ ofType:%@", fileWrapper, typeName);
- (BOOL)readFromURL:(NSURL *)absoluteURL 
             ofType:(NSString *)typeName 
              error:(NSError **)outError
{
  // Insert code here to read your document from the given data of the specified type.  If the given outError != NULL, ensure that you set *outError when returning NO.
  
  NSLog(@"readFromURL:%@ ofType:%@", absoluteURL, typeName);
  if ([typeName isEqualToString:@"fold"])
  {
    // TODO: check for .git folder in place
  }
  else 
  {
    if (outError != NULL)
    {
      *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
      return NO;
    }    
  }

  return YES;
}

@end
