#import "GBModels.h"
#import "GBCommitViewController.h"

#import "NSArray+OAArrayHelpers.h"
#import "NSSplitView+OASplitViewHelpers.h"
#import "NSObject+OAKeyValueObserving.h"
#import "NSString+OAStringHelpers.h"
#import "NSView+OAViewHelpers.h"

@implementation GBCommitViewController

@synthesize commit;
@synthesize headerRTFTemplate;
@synthesize headerScrollView;
@synthesize headerTextView;

- (void) dealloc
{
  self.commit = nil;
  self.headerRTFTemplate = nil;
  self.headerScrollView = nil;
  self.headerTextView = nil;
  [super dealloc];
}



#pragma mark GBBaseViewController

- (void) loadView
{
  [super loadView];
  [self update];
}

- (void) viewDidUnload
{
  [super viewDidUnload];
}


#pragma mark Actions


- (IBAction) stageShowDifference:(id)sender
{
  [[[self selectedChanges] firstObject] launchDiffWithBlock:^{
    
  }];
}
- (BOOL) validateStageShowDifference:(id)sender
{
  return ([[self selectedChanges] count] == 1);
}

- (IBAction) stageRevealInFinder:(id)sender
{
  [[[self selectedChanges] firstObject] revealInFinder];
}

- (BOOL) validateStageRevealInFinder:(id)sender
{
  if ([[self selectedChanges] count] != 1) return NO;
  GBChange* change = [[self selectedChanges] firstObject];
  return [change validateRevealInFinder];
}




- (void) update
{
  [super update];
  // Reset text view
  [self.headerTextView setEditable:NO];
  [self.headerTextView setString:@""];
  
  GBCommit* aCommit = self.commit;
  if (aCommit && ![aCommit isStage])
  {
    // Load the template
    if (!self.headerRTFTemplate) 
      self.headerRTFTemplate = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"commit-header-template" ofType:@"rtf"]];
    NSTextStorage* storage = [self.headerTextView textStorage];
    [storage beginEditing];
    [storage readFromData:self.headerRTFTemplate options:nil documentAttributes:nil];
    
    // FIXME: this code is very brittle! Should either pre-create an RTF template with proper paragraph styles
    //        or run through a list of possible attributes in a range of text to update them with truncating paragraph style.
    
    NSRange firstNewlineRange = [[storage string] rangeOfString:@"\n"];
    if (firstNewlineRange.location != NSNotFound)
    {
      NSRange truncatingRange = NSMakeRange(0, firstNewlineRange.location);
      if (truncatingRange.location != NSNotFound)
      {
        NSMutableParagraphStyle* paragraphStyle = [storage attribute:NSParagraphStyleAttributeName atIndex:0 effectiveRange:NULL];
        if (!paragraphStyle)
        {
          NSLog(@"WARNING: GBCommitViewController: no existing paragraph style.");
          paragraphStyle = [[[NSMutableParagraphStyle alloc] init] autorelease];
        }
        NSMutableParagraphStyle* truncatingParagraphStyle = [[paragraphStyle mutableCopy] autorelease];
        [truncatingParagraphStyle setLineBreakMode:NSLineBreakByTruncatingTail];
        [storage addAttribute:NSParagraphStyleAttributeName value:truncatingParagraphStyle range:truncatingRange];          
      }
    }
    
    // Replace placeholders
    NSMutableString* string = [storage mutableString];
    
    [string replaceOccurrencesOfString:@"commitId" 
                            withString:aCommit.commitId];
    
    [string replaceOccurrencesOfString:@"authorDate" 
                            withString:[aCommit fullDateString]];
    
    [string replaceOccurrencesOfString:@"Author Name" 
                            withString:aCommit.authorName];
    
    [string replaceOccurrencesOfString:@"author@email" 
                            withString:aCommit.authorEmail];
    
    if ([aCommit.authorName isEqualToString:aCommit.committerName])
    {
      [string replaceOccurrencesOfString:@"	Committer: 	Committer Name <committer@email>\n"
                              withString:@""];
    }
    else
    {
      [string replaceOccurrencesOfString:@"Committer Name" 
                              withString:aCommit.committerName];
      
      [string replaceOccurrencesOfString:@"committer@email" 
                              withString:aCommit.committerEmail];      
    }

    NSString* message = aCommit.message ? aCommit.message : @"";
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
