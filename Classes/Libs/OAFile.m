#import "OAFile.h"

@implementation OAFile






#pragma mark Read



+ (NSData*) dataForPath:(NSString*)path
{
	NSData* data = nil;
	if (path && [[NSFileManager defaultManager] fileExistsAtPath:path])
	{
		NSError* error = nil;
		data = [NSData dataWithContentsOfFile:path options:NSMappedRead error:&error];
		if (error || !data)
		{
			NSLog(@"OAFile: Could not read data from %@", path);
		}
	}
	return data;
}


+ (id) propertyListForPath:(NSString*)path mutabilityOption:(NSPropertyListMutabilityOptions)opt
{
	return [self propertyListFromData:[self dataForPath:path] mutabilityOption:opt];
}


+ (id) immutablePropertyListForPath:(NSString*)path
{
	return [self immutablePropertyListFromData:[self dataForPath:path]];
}


+ (id) mutablePropertyListForPath:(NSString*)path
{
	return [self mutablePropertyListFromData:[self dataForPath:path]];
}


+ (NSString*) stringForPath:(NSString*)path encoding:(NSStringEncoding)encoding
{
	return [[[NSString alloc] initWithData:[OAFile dataForPath:path] encoding:encoding] autorelease];
}


+ (NSString*) utf8StringForPath:(NSString*)path
{
	return [self stringForPath:path encoding:NSUTF8StringEncoding];
}


+ (BOOL) isReadable:(NSString*)path
{
	return [[NSFileManager defaultManager] isReadableFileAtPath:path];
}





#pragma mark Write


+ (id) createFolderForPath:(NSString*)path
{
	NSError* error = nil;
	if ([[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error])
	{
		// ok.
	}
	else
	{
		NSLog(@"OAFile createFolderForPath could not create directory %@", path);
	}
	return self;
}

+ (id) createFolderForFilePath:(NSString*)path
{
	return [self createFolderForPath:[path stringByDeletingLastPathComponent]];
}

+ (id) setData:(NSData*)data forPath:(NSString*)path
{
	if (data)
	{
		[self createFolderForFilePath:path];
		NSError* error = nil;
		if ( ! [data writeToFile:path options:NSAtomicWrite error:&error])
		{
			NSLog(@"FileHelper setData could not write data to %@", path);
		}
	} 
	else 
	{
		NSLog(@"FileHelper setData: data is nil!");
	}
	return self;
}


+ (id) setPropertyList:(id)plist forPath:(NSString*)path
{  
	[self setData:[self dataFromPropertyList: plist] forPath:path];
	return self;
}


+ (id) setString:(NSString*) string withEncoding:(NSStringEncoding)encoding forPath: (NSString*) path
{
	[OAFile setData:[string dataUsingEncoding:encoding] forPath:path];
	return self;
}


+ (id) setUtf8String:(NSString*) string forPath: (NSString*) path
{
	return [self setString:string withEncoding:NSUTF8StringEncoding forPath: path];
}






#pragma mark Delete


// this handles non-empty folders as well
+ (id) removeFileAtPath:(NSString*)path 
{	
	NSError* error = nil;
	if (!path) 
	{
		NSLog(@"OAFile removeFileAtPath: path is nil");
	}
	if ([[NSFileManager defaultManager] removeItemAtPath:path error:&error] == NO)
	{
		if ([[NSFileManager defaultManager] fileExistsAtPath:path])
		{
			NSLog(@"OAFile: Could not removeFileAtPath: %@; file still exists.", path);
		}
	}
	return self;
}






#pragma mark Conversion Helpers


+ (NSData*) dataFromPropertyList:(id) plist
{
	NSString *errorString = nil;
	NSData *data = [NSPropertyListSerialization dataFromPropertyList:plist 
															  format:NSPropertyListXMLFormat_v1_0 
													errorDescription:&errorString];
	if (errorString) 
	{
		NSLog(@"OAFile: Error occured while serializing property list: %@", errorString);
		[errorString release];
	}
	
	return data;
}


+ (id) propertyListFromData:(NSData*)data mutabilityOption:(NSPropertyListMutabilityOptions)opt
{  
	if (data) 
	{
		NSPropertyListFormat format;
		NSString* errorString = nil;
		NSArray *plist = [NSPropertyListSerialization propertyListFromData:data 
														  mutabilityOption:opt
																	format:&format 
														  errorDescription:&errorString];
		if (errorString)
		{
			NSLog(@"OAFile: Corrupted plist file: %@", errorString);
			[errorString release];
			return nil;
		}
		else
		{
			return plist;
		}
	}
	else
	{
		return nil;
	}
}


+ (id) immutablePropertyListFromData:(NSData*)data
{
	return [self propertyListFromData:data mutabilityOption:NSPropertyListImmutable];
}


+ (id) mutablePropertyListFromData:(NSData*)data
{
	return [self propertyListFromData:data mutabilityOption:NSPropertyListMutableContainersAndLeaves];
}


@end
