// Used in projects (time revisited):
// - oleganza/gitbox (22.05.2010)

@interface NSString (OAGitHelpers)

// Returns unescaped file name that was escaped by git
- (NSString*) stringByUnescapingGitFilename;

// Returns nil if commit is 0{40}
- (NSString*) nonZeroCommitId;

@end
