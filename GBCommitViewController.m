#import "GBModels.h"
#import "GBCommitViewController.h"
#import "GBRepositoryController.h"

#import "NSArray+OAArrayHelpers.h"
#import "NSSplitView+OASplitViewHelpers.h"
#import "NSObject+OAKeyValueObserving.h"
#import "NSString+OAStringHelpers.h"
#import "NSView+OAViewHelpers.h"

@interface GBCommitViewController ()
- (void) commitDidChange;
@end

@implementation GBCommitViewController

@synthesize headerRTFTemplate;
@synthesize headerScrollView;
@synthesize headerTextView;

- (void) dealloc
{
  self.headerRTFTemplate = nil;
  self.headerScrollView = nil;
  self.headerTextView = nil;
  [super dealloc];
}

- (NSData*) headerRTFTemplate
{
  if (!headerRTFTemplate)
  {
    self.headerRTFTemplate = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"commit-header-template" ofType:@"rtf"]];
  }
  return [[headerRTFTemplate retain] autorelease];
}

#pragma mark GBBaseViewController

- (void) loadView
{
  [super loadView];
  [self commitDidChange];
}

- (void) viewDidUnload
{
  [super viewDidUnload];
}


#pragma mark Actions


- (IBAction) stageShowDifference:(id)sender
{
  [[[self selectedChanges] firstObject] launchComparisonTool:sender];
}
- (BOOL) validateStageShowDifference:(id)sender
{
  return ([[self selectedChanges] count] == 1);
}

- (IBAction) stageRevealInFinder:(id)sender
{
  [[[self selectedChanges] firstObject] revealInFinder:sender];
}

- (BOOL) validateStageRevealInFinder:(id)sender
{
  if ([[self selectedChanges] count] != 1) return NO;
  GBChange* change = [[self selectedChanges] firstObject];
  return [change validateRevealInFinder:sender];
}




#pragma mark GBRepository observer


- (void) commitDidChange
{
  // Reset text view
  [self.headerTextView setEditable:NO];
  [self.headerTextView setString:@""];
  
  GBCommit* commit = self.repositoryController.selectedCommit;
  if (commit && ![commit isStage])
  {
    // Load the template
    NSTextStorage* storage = [self.headerTextView textStorage];
    [storage beginEditing];
    [storage readFromData:self.headerRTFTemplate options:nil documentAttributes:nil];
    
    // Replace placeholders
    NSMutableString* string = [storage mutableString];
    
    [string replaceOccurrencesOfString:@"commitId" 
                            withString:commit.commitId];
    
    [string replaceOccurrencesOfString:@"authorDate" 
                            withString:[commit fullDateString]];
    
    [string replaceOccurrencesOfString:@"Author Name" 
                            withString:commit.authorName];
    
    [string replaceOccurrencesOfString:@"author@email" 
                            withString:commit.authorEmail];
    
    if ([commit.authorName isEqualToString:commit.committerName])
    {
      [string replaceOccurrencesOfString:@"	Committer: 	Committer Name <committer@email>\n"
                              withString:@""];
    }
    else
    {
      [string replaceOccurrencesOfString:@"Committer Name" 
                              withString:commit.committerName];
      
      [string replaceOccurrencesOfString:@"committer@email" 
                              withString:commit.committerEmail];      
    }

    NSString* message = commit.message ? commit.message : @"";
    NSArray* paragraphs = [message componentsSeparatedByString:@"\n"];
    NSString* restOfTheMessage = @"";
    if ([paragraphs count] > 1)
    {
      restOfTheMessage = [[paragraphs subarrayWithRange:NSMakeRange(1, [paragraphs count] - 1)] componentsJoinedByString:@"\n"];
    }
    
    [string replaceOccurrencesOfString:@"Subject line" 
                            withString:[paragraphs objectAtIndex:0]];
    [string replaceOccurrencesOfString:@"Rest of the message" 
                            withString:restOfTheMessage];
    
    [storage endEditing];
    
    // Scroll to top
    [self.headerTextView scrollRangeToVisible:NSMakeRange(0, 1)];
    [self.headerScrollView reflectScrolledClipView:[self.headerScrollView contentView]];
  }
}




#pragma mark NSSplitViewDelegate



- (CGFloat) minSplitViewHeaderHeight
{
  return 85.0;
}

- (CGFloat)splitView:(NSSplitView*) aSplitView constrainMinCoordinate:(CGFloat)proposedMin ofSubviewAt:(NSInteger)dividerIndex
{
  return [self minSplitViewHeaderHeight];
}

- (CGFloat)splitView:(NSSplitView*) aSplitView constrainMaxCoordinate:(CGFloat)proposedMax ofSubviewAt:(NSInteger)dividerIndex
{
  return [self view].bounds.size.height - 80.0; // 80 px for changes table height
}

- (void) splitView:(NSSplitView*)aSplitView resizeSubviewsWithOldSize:(NSSize)oldSize
{
  [aSplitView resizeSubviewsWithOldSize:oldSize firstViewSizeLimit:[self minSplitViewHeaderHeight]];
}

@end
