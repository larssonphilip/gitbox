#import "GBLocalRefsTask.h"
#import "GBRef.h"

@implementation GBLocalRefsTask

@synthesize branches;
@synthesize tags;
@synthesize remoteBranchesByRemoteAlias;

- (void) dealloc
{
  self.branches = nil;
  self.tags = nil;
  self.remoteBranchesByRemoteAlias = nil;
  [super dealloc];
}



- (NSArray*) arguments
{
//  --dereference
//                Dereference tags into object IDs as well. They will be shown with "^{}" appended.
  return [NSArray arrayWithObjects:@"show-ref", @"--dereference", nil];
}

- (void) didFinish
{
  [super didFinish];
  
  if (self.terminationStatus != 0)
  {
    return;
  }
  
  NSMutableArray* theBranches = [NSMutableArray array];
  NSMutableArray* theTags     = [NSMutableArray array];
  NSMutableDictionary* theRemoteBranchesByRemoteAlias = [NSMutableDictionary dictionary];
  
  /*
  9e88f7a12c635713073943a58a4a5c759c1e9a4c refs/heads/leopard
  561298804bad570ab6f1fbe801c17b1f978474a3 refs/heads/master
  281cf8f952357b3cc8bcaa3636be49dcefe9435a refs/heads/master1
  d44df1aa3c4d0cf15b783a4d5665ed73dabb10db refs/heads/search
  07f939c9b7d6ab1550be6f35f7fbfdd710d5da3b refs/remotes/oleganza/master
  a1a391bb19aaad178c9c575ee049b3c331dd9e35 refs/remotes/origin/master
  d44df1aa3c4d0cf15b783a4d5665ed73dabb10db refs/remotes/origin/search
  9034b2aacc4d1992c3a38211d6248850592a8bf4 refs/stash
  078286bdfabb900f831631a43ea599f672405801 refs/tags/0.1
  e2adf7eb769722f40ab17ce90db4ad8be2c3773d refs/tags/0.2
  3f6c7cce5d9ce2434b6f926507ebb700877925a7 refs/tags/0.8
  0bbaa4118237a65f4cb55f9a88f6f3ce208add27 refs/tags/0.9.5
  5db1343563acba25d95e19c7c8f6ee370c843d98 refs/tags/0.9.6
  b1f9554e636f1a707c4405c0851fd8aa9d321e82 refs/tags/0.9.7
  cac7493f1ec3c45655f861dcf6db2b99fe5b1cda refs/tags/1.0         <- if variant with "^{}" is missing, then using this as commit ID
  c2d1cfbe2d930f302571e674a6f196e416e7ebc4 refs/tags/v1.6.1      <- it has "^{}" variant, so it is not a commit ID, but tag ID
  f19ba84343b114ac1cfc254aae729773833fd3f3 refs/tags/v1.6.1^{}   <- this is real commit ID
   
  */
  
  GBRef* prevTag = nil;
  
  for (NSString* line in [[self UTF8OutputStripped] componentsSeparatedByString:@"\n"])
  {
    if (line && [line length] > 0)
    {
      // ["32c5bb7b9a75638ef53c757efd9a0f54576c7c61", "refs/heads/master"]
      NSArray* commitAndRef = [line componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]; 
      if (commitAndRef && [commitAndRef count] >= 2)
      {
        NSString* commitId = [commitAndRef objectAtIndex:0];
        NSString* refName = [commitAndRef objectAtIndex:1];
        
        BOOL hasStrangeSuffix = ([refName rangeOfString:@"^{}"].length > 0);
        
        if (hasStrangeSuffix)
        {
          refName = [refName stringByReplacingOccurrencesOfString:@"^{}" withString:@""];
        }
        
        if ([commitId length] != 40)
        {
          NSLog(@"ERROR: GBLocalRefsTask: invalid commit ID: %@ for ref %@", commitId, refName);
        }
        else if ([refName hasPrefix:@"refs/HEAD"])
        {
          // skip
        }
        else if ([refName hasPrefix:@"refs/heads/"])
        {
          GBRef* ref = [[GBRef new] autorelease];
          ref.repository = self.repository;
          ref.commitId = commitId;
          ref.name = [refName substringFromIndex:[@"refs/heads/" length]];
          
          if (![ref.name isEqualToString:@"HEAD"]) // ignore HEAD meta-ref
          {
            [theBranches addObject:ref];
          }
        }
        else if ([refName hasPrefix:@"refs/tags/"])
        {
          GBRef* ref = [[GBRef new] autorelease];
          ref.repository = self.repository;
          ref.commitId = commitId;
          ref.name = [refName substringFromIndex:[@"refs/tags/" length]];
          ref.isTag = YES;
          
          if (prevTag.name && [prevTag.name isEqualToString:ref.name] && hasStrangeSuffix)
          {
            // Apply correct dereferenced commitId.
            prevTag.commitId = commitId;
          }
          else
          {
            prevTag = ref;
            [theTags addObject:ref];
          }
        }
        else if ([refName hasPrefix:@"refs/remotes/"])
        {
          NSString* nameWithAlias = [refName substringFromIndex:[@"refs/remotes/" length]];
          
          if ([nameWithAlias rangeOfString:@"/"].length > 0)
          {
            GBRef* ref = [[GBRef new] autorelease];
            ref.repository = self.repository;
            ref.commitId = commitId;
            [ref setNameWithRemoteAlias:nameWithAlias];
            ref.isTag = NO;
            
            if (![ref.name isEqualToString:@"HEAD"]) // ignore HEAD meta-ref
            {
              NSMutableArray* remoteBranches = [theRemoteBranchesByRemoteAlias objectForKey:ref.remoteAlias];
              if (!remoteBranches)
              {
                remoteBranches = [NSMutableArray array];
                [theRemoteBranchesByRemoteAlias setObject:remoteBranches forKey:ref.remoteAlias];
              }
              [remoteBranches addObject:ref];
            }
          }
          else
          {
            NSLog(@"ERROR: GBLocalBranchesTask: expected refs/remotes/<remote alias>/<branch name>, got: %@", line);
          }
        }
        else if ([refName hasPrefix:@"refs/stash"])
        {
          // skip
        }
        else
        {
          NSLog(@"%@: skipping unknown line %@", [self class], line);
        }
      }
      else
      {
        NSLog(@"ERROR: GBLocalBranchesTask: expected '<sha1> <ref>', got: %@", line);
      } // if line is valid
    } // if line not empty
  } // for loop
  
  self.branches = theBranches;
  self.tags = theTags;
  self.remoteBranchesByRemoteAlias = theRemoteBranchesByRemoteAlias;
}


@end
