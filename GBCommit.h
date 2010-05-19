@class GBChange;
@class GBRepository;
@interface GBCommit : NSObject
{
  NSString* revision;
  NSArray* changes;

  NSString* message;
  NSString* authorName;
  NSString* authorEmail;
  NSDate* date;
  
  GBRepository* repository;
}

@property(retain) NSString* revision;
@property(retain) NSArray* changes;

@property(retain) NSString* message;
@property(retain) NSString* authorName;
@property(retain) NSString* authorEmail;
@property(retain) NSDate* date;

@property(assign) GBRepository* repository;

- (BOOL) isStage;

- (void) updateChanges;
- (void) reloadChanges;

- (NSArray*) allChanges;
- (NSArray*) loadChanges;

- (NSArray*) changesFromDiffOutput:(NSData*) data;

@end
