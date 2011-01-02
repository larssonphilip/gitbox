#import "GBModels.h"
#import "GBCommitViewController.h"
#import "GBUserpicController.h"

#import "NSArray+OAArrayHelpers.h"
#import "NSSplitView+OASplitViewHelpers.h"
#import "NSObject+OAKeyValueObserving.h"
#import "NSString+OAStringHelpers.h"
#import "NSView+OAViewHelpers.h"
#import "NSObject+OAPerformBlockAfterDelay.h"
#import "NSAttributedString+OAAttributedStringHelpers.h"


@interface GBCommitViewController ()
@property(nonatomic,retain) GBUserpicController* userpicController;
- (void) updateCommitHeader;
- (void) updateTemplate:(NSTextStorage*)storage withCommit:(GBCommit*)aCommit;
- (void) updateMessageStorage:(NSTextStorage*)storage;
- (void) updateHeaderSize;
- (void) tableViewDidResize:(id)notification;
@end

@implementation GBCommitViewController

@synthesize commit;
@synthesize headerRTFTemplate;
@synthesize headerTextView;
@synthesize messageTextView;
@synthesize horizontalLine;
@synthesize authorImage;
@synthesize userpicController;

- (void) dealloc
{
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:nil 
                                                object:self.tableView];
  self.commit = nil;
  self.headerRTFTemplate = nil;
  self.headerTextView = nil;
  self.messageTextView = nil;
  self.horizontalLine = nil;
  self.authorImage = nil;
  self.userpicController = nil;
  [super dealloc];
}



#pragma mark GBBaseViewController


- (void) loadView
{
  [super loadView];
  
  [self.authorImage setImage:nil];
  
  if (!self.userpicController)
  {
    self.userpicController = [[GBUserpicController new] autorelease];
  }
  
  [self update];
  
  [self.tableView registerForDraggedTypes:[NSArray arrayWithObjects:NSStringPboardType, NSFilenamesPboardType, nil]];
  [self.tableView setDraggingSourceOperationMask:NSDragOperationNone forLocal:YES];
  [self.tableView setDraggingSourceOperationMask:NSDragOperationCopy forLocal:NO];
  [self.tableView setVerticalMotionCanBeginDrag:YES];
}





#pragma mark Update



- (void) update
{
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:NSViewFrameDidChangeNotification 
                                                object:self.tableView];
  
  [super update];
  [self updateCommitHeader];
  [self.tableView setPostsFrameChangedNotifications:YES];
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(tableViewDidResize:)
                                               name:NSViewFrameDidChangeNotification
                                             object:self.tableView];
  
}

- (void) updateCommitHeader
{
  GBCommit* aCommit = self.commit;
  
  if (!aCommit) return;
  if ([aCommit isStage]) return;

  [self.headerTextView setEditable:NO];
  [self.headerTextView setString:@""];
  
  if (!self.headerRTFTemplate)
  {
    self.headerRTFTemplate = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"GBCommitViewControllerHeader" ofType:@"rtf"]];
  }
  
  {
    NSTextStorage* storage = [self.headerTextView textStorage];
    [storage beginEditing];
    [storage readFromData:self.headerRTFTemplate options:nil documentAttributes:nil];
    [self updateTemplate:storage withCommit:aCommit];
    [storage endEditing];
  }
  
  NSString* message = aCommit.message ? aCommit.message : @"";
  [self.messageTextView setString:message];

  {
    NSTextStorage* storage = [self.messageTextView textStorage];
    [storage beginEditing];
    [self updateMessageStorage:storage];
    [storage endEditing];
  }
  
  NSString* email = aCommit.authorEmail;
  
  [self.userpicController loadImageForEmail:email withBlock:^{
    if (email && [aCommit.authorEmail isEqualToString:email])
    {
      NSImage* image = [self.userpicController imageForEmail:email];
      [self.authorImage setImage:image];
      [self updateHeaderSize];
    }
  }];
  
  [self updateHeaderSize];
}

- (void) updateMessageStorage:(NSTextStorage*)storage
{
  // I had an idea to paint "Signed-off-by: ..." line in gray, but I have a better use of my time right now. [Oleg]
}

- (void) updateTemplate:(NSTextStorage*)storage withCommit:(GBCommit*)aCommit
{  
  for (NSString* line in [NSArray arrayWithObjects:
                          @"	Parent 1: 	$parentId1", 
                          @"	Parent 2: 	$parentId2",
                          @"	Commit: 	$commitId",
                          @"	Date: 	$authorDate",
                          @"	Author: 	$Author Name <$author@email>",
                          @"	 	Committed by $Committer Name <$committer@email>",
                          nil])
  {
    [storage updateAttribute:NSParagraphStyleAttributeName forSubstring:line withBlock:^(NSParagraphStyle* style){
      NSMutableParagraphStyle* mutableStyle = [[style mutableCopy] autorelease];
      if (!mutableStyle)
      {
        mutableStyle = [[[NSMutableParagraphStyle alloc] init] autorelease];
      }
      [mutableStyle setLineBreakMode:NSLineBreakByTruncatingTail];
      return mutableStyle;
    }];
  }
  
  // Replace placeholders
  NSMutableString* string = [storage mutableString];
  
  
  NSString* parentId1 = [aCommit.parentIds objectAtIndex:0 or:nil];
  NSString* parentId2 = [aCommit.parentIds objectAtIndex:1 or:nil];
  
  if (!parentId1 && !parentId2)
  {
    [string replaceOccurrencesOfString:@"	Parent 1: 	$parentId1\n" 
                            withString:@""];
    [string replaceOccurrencesOfString:@"	Parent 2: 	$parentId2\n" 
                            withString:@""];
  }
  else if (parentId1 && !parentId2)
  {
    [string replaceOccurrencesOfString:@"Parent 1:" 
                            withString:@"Parent:"];
    [string replaceOccurrencesOfString:@"	Parent 2: 	$parentId2\n" 
                            withString:@""];
  }
  
  if (parentId1)
  {
    [string replaceOccurrencesOfString:@"$parentId1" withString:parentId1];
  }
  if (parentId2)
  {
    [string replaceOccurrencesOfString:@"$parentId2" withString:parentId2];
  }
  
  [string replaceOccurrencesOfString:@"$commitId" 
                          withString:aCommit.commitId];
  
  [string replaceOccurrencesOfString:@"$authorDate" 
                          withString:[aCommit fullDateString]];
  
  [string replaceOccurrencesOfString:@"$Author Name" 
                          withString:aCommit.authorName];
  
  [string replaceOccurrencesOfString:@"$author@email" 
                          withString:aCommit.authorEmail];
  
  if ([aCommit.authorName isEqualToString:aCommit.committerName])
  {
    [string replaceOccurrencesOfString:@"\n	 	Committed by $Committer Name <$committer@email>"
                            withString:@""];
  }
  else
  {
    [string replaceOccurrencesOfString:@"$Committer Name" 
                            withString:aCommit.committerName];
    
    [string replaceOccurrencesOfString:@"$committer@email" 
                            withString:aCommit.committerEmail];      
  }
}

- (void) updateHeaderSize
{
  //NSLog(@"COMMIT: updateHeaderSize ----------------- ");
  
  // Force layout
  [[self.headerTextView layoutManager] glyphRangeForTextContainer:[self.headerTextView textContainer]];
  [[self.messageTextView layoutManager] glyphRangeForTextContainer:[self.messageTextView textContainer]];
  
  NSRect headerTVRect  = [[self.headerTextView layoutManager] usedRectForTextContainer:[self.headerTextView textContainer]];
  NSRect messageTVRect = [[self.messageTextView layoutManager] usedRectForTextContainer:[self.messageTextView textContainer]];

//  NSLog(@"COMMIT: headerTVRect = %@ (textContainer: %@)", NSStringFromRect(headerTVRect), NSStringFromSize([[self.headerTextView textContainer] containerSize]));
//  NSLog(@"COMMIT: messageTVRect = %@ (textContainer: %@)", NSStringFromRect(messageTVRect), NSStringFromSize([[self.messageTextView textContainer] containerSize]));
  
  CGFloat headerTVHeight = ceil(headerTVRect.size.height);
  CGFloat messageTVHeight = ceil(messageTVRect.size.height);
  
//  NSLog(@"COMMIT: headerTVHeight = %f [img: %f], messageTVHeight = %f", headerTVHeight, [self.authorImage frame].size.height, messageTVHeight);
  
  headerTVHeight += 0.0;
  messageTVHeight += 0.0;
  
  // From top to bottom:
  // 1. header top padding
  // 2. headerTextView height
  // 3. header bottom padding
  // 4. line NSBox height
  // 5. message top padding
  // 6. messageTextView height
  // 7. message bottom padding
  
  static CGFloat authorImagePadding = 10.0;
  static CGFloat headerTopPadding = 8.0;
  static CGFloat headerBottomPadding = 8.0;
  static CGFloat messageTopPadding = 8.0;
  static CGFloat messageBottomPadding = 5.0;
  
  headerTVHeight = MAX(headerTVHeight + 2*headerTopPadding, [self.authorImage frame].size.height + 2*authorImagePadding) - 2*headerTopPadding;
  
  CGFloat currentY = messageBottomPadding;
  
  {
    NSRect fr = [[self.messageTextView enclosingScrollView] frame];
    fr.size.height = messageTVHeight;
    fr.origin.y = currentY;
    [[self.messageTextView enclosingScrollView] setFrame:fr];
    
    //NSLog(@"COMMIT: messageTextView: %@", NSStringFromRect(fr));
    
    currentY += fr.size.height;
  }
  
  currentY += messageTopPadding;
  
  {
    NSRect fr = [self.horizontalLine frame];
    fr.origin.y = currentY;
    [self.horizontalLine setFrame:fr];
    
    //NSLog(@"COMMIT: horizontalLine: %@", NSStringFromRect(fr));
    currentY += fr.size.height;
  }
  
  currentY += headerBottomPadding;
    
  {
    NSRect fr = [[self.headerTextView enclosingScrollView] frame];
    fr.size.height = headerTVHeight;
    fr.origin.y = currentY;
    [[self.headerTextView enclosingScrollView] setFrame:fr];
    
    //NSLog(@"COMMIT: headerTextView: %@", NSStringFromRect(fr));
    
    currentY += fr.size.height;
  }
  
  currentY += headerTopPadding;
  
  {
    NSRect fr = [self.authorImage frame];
    fr.origin.y = currentY - authorImagePadding - fr.size.height;
    [self.authorImage setFrame:fr];
  }
  
  {
    NSRect fr = self.headerView.frame;
    fr.size.height = headerTopPadding + 
                     [self.headerTextView frame].size.height + 
                     headerBottomPadding +
                     [self.horizontalLine frame].size.height +
                     messageTopPadding + 
                     [self.messageTextView frame].size.height + 
                     messageBottomPadding;
    BOOL autoresizesSubviews = [self.headerView autoresizesSubviews];
    [self.headerView setAutoresizesSubviews:NO];
    [self.headerView setFrame:fr];
    [self.headerView setAutoresizesSubviews:autoresizesSubviews];
  }
  
  [self.tableView noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndex:0]];
  
  [self.headerTextView scrollRangeToVisible:NSMakeRange(0, 1)];
  [[self.headerTextView enclosingScrollView] reflectScrolledClipView:[[self.headerTextView enclosingScrollView] contentView]];
  
//  [self.messageTextView scrollRangeToVisible:NSMakeRange(0, 1)];
//  [[self.messageTextView enclosingScrollView] reflectScrolledClipView:[[self.headerTextView enclosingScrollView] contentView]];
//  
//  [[self.messageTextView enclosingScrollView] setNeedsDisplay:YES];
//  [self.messageTextView setNeedsDisplay:YES];
  
  [self performSelector:@selector(fixupRareGlitchWithTextView) withObject:nil afterDelay:0.0];
}

- (void) fixupRareGlitchWithTextView
{
  [self.messageTextView scrollRangeToVisible:NSMakeRange(0, 1)];
  [[self.messageTextView enclosingScrollView] reflectScrolledClipView:[[self.headerTextView enclosingScrollView] contentView]];
  [[self.messageTextView enclosingScrollView] setNeedsDisplay:YES];
  [self.messageTextView setNeedsDisplay:YES];
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




#pragma mark Resizing


- (void) tableViewDidResize:(id)notification
{
  if (![self.tableView inLiveResize]) return;
  [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(tableViewDidLiveResizeDelayed) object:nil];
  [self performSelector:@selector(tableViewDidLiveResizeDelayed) withObject:nil afterDelay:0.1];
}

- (void) tableViewDidLiveResizeDelayed
{
  [self updateHeaderSize];
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
