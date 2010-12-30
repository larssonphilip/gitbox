#import "GBModels.h"
#import "GBCommitViewController.h"

#import "NSArray+OAArrayHelpers.h"
#import "NSSplitView+OASplitViewHelpers.h"
#import "NSObject+OAKeyValueObserving.h"
#import "NSString+OAStringHelpers.h"
#import "NSView+OAViewHelpers.h"
#import "NSObject+OAPerformBlockAfterDelay.h"

@implementation GBCommitViewController

@synthesize commit;
@synthesize headerRTFTemplate;
@synthesize headerTextView;

- (void) dealloc
{
  self.commit = nil;
  self.headerRTFTemplate = nil;
  self.headerTextView = nil;
  [super dealloc];
}



#pragma mark GBBaseViewController


- (void) loadView
{
  [super loadView];
  [self update];
  
  [self.tableView registerForDraggedTypes:[NSArray arrayWithObjects:NSStringPboardType, NSFilenamesPboardType, nil]];
  [self.tableView setDraggingSourceOperationMask:NSDragOperationNone forLocal:YES];
  [self.tableView setDraggingSourceOperationMask:NSDragOperationCopy forLocal:NO];
  [self.tableView setVerticalMotionCanBeginDrag:YES];
}





#pragma mark Update



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
      self.headerRTFTemplate = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"GBCommitViewControllerHeader" ofType:@"rtf"]];
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
      [string replaceOccurrencesOfString:@"	 	Committed by Committer Name <committer@email>\n"
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
    [[self.headerTextView enclosingScrollView] reflectScrolledClipView:[[self.headerTextView enclosingScrollView] contentView]];
  }
}






#pragma mark Actions


- (IBAction) stageExtractFile:_
{
  GBChange* change = [[[self selectedChanges] firstObject] nilIfBusy];
  if (!change || ![change validateExtractFile]) return;
  
  NSSavePanel* panel = [NSSavePanel savePanel];
  [panel setNameFieldLabel:NSLocalizedString(@"Save As:", @"Commit")];
  [panel setNameFieldStringValue:[change defaultNameForExtractedFile]];
  [panel setPrompt:NSLocalizedString(@"Save", @"Commit")];
  [panel setDelegate:self];
  [panel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
    if (result == NSFileHandlingPanelOKButton)
    {
      [change extractFileWithTargetURL:[panel URL]];
      NSString* path = [[panel URL] path];
      [NSObject performBlock:^{
        [[NSWorkspace sharedWorkspace] selectFile:path inFileViewerRootedAtPath:nil];
      } afterDelay:0.7];
      
//      dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 700000000), dispatch_get_main_queue(), ^{
//        [[NSWorkspace sharedWorkspace] selectFile:path inFileViewerRootedAtPath:nil];  
//      });
    }
  }];
  
}

- (BOOL) validateStageExtractFile:_
{
  if ([[self selectedChanges] count] != 1) return NO;
  return [[[[self selectedChanges] firstObject] nilIfBusy] validateExtractFile];
}







#pragma mark Drag and drop


- (BOOL)tableView:(NSTableView *)aTableView
writeRowsWithIndexes:(NSIndexSet *)indexSet
     toPasteboard:(NSPasteboard *)pasteboard
{
  NSArray* items = [[self.changes objectsAtIndexes:[self changesIndexesForTableIndexes:indexSet]] valueForKey:@"pasteboardItem"];
  [pasteboard writeObjects:items];
  return YES;
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
  NSString* extension = [enteredName pathExtension];
  NSString* basename = [enteredName stringByDeletingPathExtension];
  
  if (aURL && enteredName && [enteredName length] > 0)
  {
    NSString* targetPath = [[aPanel directoryURL] path];
    NSUInteger counter = 0;
    while ([[NSFileManager defaultManager] fileExistsAtPath:[targetPath stringByAppendingPathComponent:uniqueName]])
    {
      counter++;
      if (extension && ![extension isEqualToString:@""] && basename && ![basename isEqualToString:@""])
      {
        uniqueName = [[basename stringByAppendingFormat:@"%d", counter] stringByAppendingPathExtension:extension];
      }
      else
      {
        uniqueName = [enteredName stringByAppendingFormat:@"%d", counter];
      }
    }
    [aPanel setNameFieldStringValue:uniqueName];
  }
}


//
//
//#pragma mark NSSplitViewDelegate
//
//
//
//- (CGFloat) minSplitViewHeaderHeight
//{
//  return 85.0;
//}
//
//- (CGFloat)splitView:(NSSplitView*) aSplitView constrainMinCoordinate:(CGFloat)proposedMin ofSubviewAt:(NSInteger)dividerIndex
//{
//  return [self minSplitViewHeaderHeight];
//}
//
//- (CGFloat)splitView:(NSSplitView*) aSplitView constrainMaxCoordinate:(CGFloat)proposedMax ofSubviewAt:(NSInteger)dividerIndex
//{
//  return [self view].bounds.size.height - 80.0; // 80 px for changes table height
//}
//
//- (void) splitView:(NSSplitView*)aSplitView resizeSubviewsWithOldSize:(NSSize)oldSize
//{
//  [aSplitView resizeSubviewsWithOldSize:oldSize firstViewSizeLimit:[self minSplitViewHeaderHeight]];
//}

@end
