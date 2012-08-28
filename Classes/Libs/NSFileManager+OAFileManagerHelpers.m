#import "NSFileManager+OAFileManagerHelpers.h"

@implementation NSFileManager (OAFileManagerHelpers)




#pragma mark Interrogation


+ (BOOL) isReadableDirectoryAtPath:(NSString*)path
{
  return [[self defaultManager] isReadableDirectoryAtPath:path];
}

- (BOOL) isReadableDirectoryAtPath:(NSString*)path
{
  BOOL isDirectory = NO;
  if ([self isReadableFileAtPath:path] && [self fileExistsAtPath:path isDirectory:&isDirectory])
  {
    return isDirectory;
  }
  return NO;
}

+ (BOOL) isWritableDirectoryAtPath:(NSString*)path
{
  return [[self defaultManager] isWritableDirectoryAtPath:path];
}

- (BOOL) isWritableDirectoryAtPath:(NSString*)path
{
  BOOL isDirectory = NO;
  if ([self isWritableFileAtPath:path] && [self fileExistsAtPath:path isDirectory:&isDirectory])
  {
    return isDirectory;
  }
  return NO;
}

+ (NSArray*) contentsOfDirectoryAtURL:(NSURL*)url
{
  return [[self defaultManager] contentsOfDirectoryAtURL:url];
}

- (NSArray*) contentsOfDirectoryAtURL:(NSURL*)url
{
  if (!url)
  {
    NSLog(@"WARNING: NSFileManager: url is nil; returning empty array");
    return [NSArray array];
  }
  NSError* outError = nil; 
  NSArray* URLs = [[NSFileManager defaultManager] 
                   contentsOfDirectoryAtURL:url
                   includingPropertiesForKeys:[NSArray array] 
                   options:0 
                   error:&outError];
  if (!URLs)
  {
    NSLog(@"ERROR: NSFileManager: %@", [outError localizedDescription]);
    return [NSArray array];
  }
  return URLs;
}

+ (void) calculateSizeAtURL:(NSURL*)aURL completionHandler:(void(^)())completionHandler
{
	NSFileManager* fm = [[NSFileManager alloc] init];
	
	completionHandler = [completionHandler copy];
	
	dispatch_queue_t callerQueue = dispatch_get_current_queue();
	dispatch_retain(callerQueue);
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
		
		BOOL isDir = NO;
		if (![fm fileExistsAtPath:aURL.path isDirectory:&isDir])
		{
			if (completionHandler) completionHandler(0);
			return;
		}
		
		unsigned long long bytes = 0;
		
		if (isDir)
		{
			NSPipe *pipe = [NSPipe pipe];
			NSTask *t = [[NSTask alloc] init];
			[t setLaunchPath:@"/usr/bin/du"];
			[t setArguments:[NSArray arrayWithObjects:@"-k", @"-d", @"0", aURL.path, nil]];
			[t setStandardOutput:pipe];
			[t setStandardError:[NSPipe pipe]];
			[t launch];
			[t waitUntilExit];
			
			NSString *sizeString = [[NSString alloc] initWithData:[[pipe fileHandleForReading] availableData] encoding:NSASCIIStringEncoding];
			sizeString = [[sizeString componentsSeparatedByString:@" "] objectAtIndex:0];
			bytes = [sizeString longLongValue]*1024;
		}
		else
		{
			bytes = [[fm attributesOfItemAtPath:aURL.path error:nil] fileSize];
		}
		
		dispatch_async(callerQueue, ^{
			if (completionHandler) completionHandler(bytes);
		});
		dispatch_release(callerQueue);
	});
}



#pragma mark Mutation


- (void) createFolderForPath:(NSString*)path
{
  NSError* error = nil;
  if ([self createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error])
  {
    // ok.
  }
  else
  {
    NSLog(@"NSFileManager+OAFileManagerHelpers: createFolderForPath could not create directory %@", path);
  }
}

- (void) createFolderForFilePath:(NSString*)path
{
  [self createFolderForPath:[path stringByDeletingLastPathComponent]];
}

- (void) writeData:(NSData*)data toPath:(NSString*)path
{
  if (data)
	{
    [self createFolderForFilePath:path];
		NSError* error = nil;
    if ( ! [data writeToFile:path options:NSDataWritingAtomic error:&error])
    {
      NSLog(@"NSFileManager+OAFileManagerHelpers: could not write data to %@", path);
    }
	} 
  else 
  {
    NSLog(@"NSFileManager+OAFileManagerHelpers: writeData:toPath: data is nil!");
  }
}


@end
