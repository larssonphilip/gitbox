#import "GBRef.h"

@implementation GBRef
@synthesize name;
@synthesize commitId;
@synthesize remoteAlias;
@synthesize configuredRemoteBranch;

@synthesize isTag;

+ (GBRef*) refWithCommitId:(NSString*)commitId
{
	GBRef* ref = [[self new] autorelease];
	ref.commitId = commitId;
	return ref;
}

- (void) dealloc
{
	self.name = nil;
	self.commitId = nil;
	self.remoteAlias = nil;
	self.configuredRemoteBranch = nil;
	[super dealloc];
}


- (BOOL) isEqual:(id)object
{
	return [self isEqualToRef:(GBRef*)object];
}


- (BOOL) isEqualToRef:(GBRef*)otherRef
{
	if (self == otherRef) return YES;
	if (![otherRef isKindOfClass:[self class]]) return NO;
	
	if (self.name && [self.name isEqualToString:otherRef.name])
	{
		if (self.isTag)
		{
			return YES;
		}
		
		if (self.remoteAlias)
		{
			return otherRef.remoteAlias && [self.remoteAlias isEqualToString:otherRef.remoteAlias];
		}
		else
		{
			return !otherRef.remoteAlias;
		}
	}
	else if (!self.name && !otherRef.name)
	{
		if (self.commitId) return ([self.commitId isEqualToString:otherRef.commitId]);
	}
	
	return NO;
}

- (NSString*) nameWithRemoteAlias
{
	return self.remoteAlias ? 
	[NSString stringWithFormat:@"%@/%@", self.remoteAlias, self.name] : 
	self.name;
}

- (void) setNameWithRemoteAlias:(NSString*)nameWithAlias // origin/some/branch/name
{
	NSRange slashRange = [nameWithAlias rangeOfString:@"/"];
	if (slashRange.length <= 0 || slashRange.location <= 0 || slashRange.location > [nameWithAlias length] - 2)
	{
		[NSException raise:@"GBRef: setNameWithRemoteAlias expects name in a form <alias>/<branch name>" format:@""];
		return;
	}
	
	self.name = [nameWithAlias substringFromIndex:slashRange.location + 1];
	self.remoteAlias = [nameWithAlias substringToIndex:slashRange.location];
}

- (BOOL) isLocalBranch
{
	return !isTag && !self.remoteAlias && self.name;
}

- (BOOL) isRemoteBranch
{
	return !isTag && self.remoteAlias && self.name;
}

- (NSString*) displayName
{
	if (self.name) return [self nameWithRemoteAlias];
	if (self.commitId.length > 12) return [self.commitId substringWithRange:NSMakeRange(0, 12)];
	if (self.commitId) return self.commitId;
	return nil;
}

- (NSString*) commitish
{
	if (self.name) return [self nameWithRemoteAlias];
	if (self.commitId) return self.commitId;
	return nil;
}

- (NSString*) description
{
	return [NSString stringWithFormat:@"<%@:%p name:%@ commit:%@>", [self class], self, [self nameWithRemoteAlias], self.commitId];
}


@end
