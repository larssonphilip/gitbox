#import "GBColorLabelPicker.h"

NSString* const GBColorLabelClear  = @"GBColorLabelClear";
NSString* const GBColorLabelRed    = @"GBColorLabelRed";
NSString* const GBColorLabelOrange = @"GBColorLabelOrange";
NSString* const GBColorLabelYellow = @"GBColorLabelYellow";
NSString* const GBColorLabelGreen  = @"GBColorLabelGreen";
NSString* const GBColorLabelBlue   = @"GBColorLabelBlue";
NSString* const GBColorLabelPurple = @"GBColorLabelPurple";
NSString* const GBColorLabelGray   = @"GBColorLabelGray";


#define paddingTop    2.0
#define paddingBottom 2.0
#define paddingLeft   20.0
#define paddingRight  20.0
#define innerSpacing  2.0
#define buttonSize    18.0
#define buttonsCount  8 // should be in sync with value declarations listed above

@interface GBColorLabelPickerButton : NSImageView
@property(nonatomic, assign) GBColorLabelPicker* picker;
@property(nonatomic, assign) NSString* value;
@property(nonatomic, assign) BOOL selected;
+ (id) buttonWithValue:(NSString*)value picker:(GBColorLabelPicker*)picker;
@end

@interface GBColorLabelPicker ()
@property(nonatomic, retain) NSString* highlightedValue;
@property(nonatomic, retain) NSImageView* selectionImageView;
@property(nonatomic, retain) NSImageView* highlightImageView;
@property(nonatomic, retain) NSArray* buttons;
@end


@implementation GBColorLabelPicker

@synthesize value;
@synthesize highlightedValue;
@synthesize representedObject;
@synthesize target; // if target is nil, first responder receives an action
@synthesize action;
@synthesize selectionImageView;
@synthesize highlightImageView;
@synthesize buttons;

- (void) dealloc
{
  [value release]; value = nil;
  target = nil;
  action = nil;
  [representedObject release]; representedObject = nil;
  [highlightedValue release]; highlightedValue = nil;
  [selectionImageView release]; selectionImageView = nil;
  [highlightImageView release]; highlightImageView = nil;
  [buttons release]; buttons = nil;
  [super dealloc];
}

+ (id) pickerWithTarget:(id)target action:(SEL)action object:(id)representedObject
{
  NSRect frame = NSMakeRect(0.0, 
                            0.0, 
                            paddingLeft + buttonsCount*(buttonSize + innerSpacing) + paddingRight, 
                            paddingTop + buttonSize + paddingBottom);
  GBColorLabelPicker* picker = [[[GBColorLabelPicker alloc] initWithFrame:frame] autorelease];
  picker.target = target;
  picker.action = action;
  picker.representedObject = representedObject;
  return picker;
}

- (NSArray*) allValues
{
  static NSArray* values = nil;
  if (!values) values = [[NSArray arrayWithObjects:
                         GBColorLabelClear,
                         GBColorLabelRed,
                         GBColorLabelOrange,
                         GBColorLabelYellow,
                         GBColorLabelGreen,
                         GBColorLabelBlue,
                         GBColorLabelPurple,
                         GBColorLabelGray, 
                          nil] retain];
  return values;
}

- (NSRect) frameForIndex:(int)i
{
  return NSMakeRect(paddingLeft + i*(buttonSize + innerSpacing), paddingBottom, buttonSize, buttonSize);
}

- (id)initWithFrame:(NSRect)frame
{
  if ((self = [super initWithFrame:frame]))
  {
    NSArray* values = [self allValues];
    
    self.selectionImageView = [[[NSImageView alloc] initWithFrame:NSMakeRect(0,0,buttonSize,buttonSize)] autorelease];
    [self.selectionImageView setImage:[NSImage imageNamed:@"GBColorLabelSelection.png"]];
    [self addSubview:self.selectionImageView];

    self.highlightImageView = [[[NSImageView alloc] initWithFrame:NSMakeRect(0,0,buttonSize,buttonSize)] autorelease];
    [self.highlightImageView setImage:[NSImage imageNamed:@"GBColorLabelHighlight.png"]];
    [self addSubview:self.highlightImageView];
    
    [self.highlightImageView setHidden:YES];
    
    NSMutableArray* thebuttons = [NSMutableArray array];
    for (int i = 0; i < buttonsCount; i++)
    {
      NSString* aValue = [values objectAtIndex:i];
      GBColorLabelPickerButton* button = [GBColorLabelPickerButton buttonWithValue:aValue picker:self];
      [button setFrame:[self frameForIndex:i]];
      [self addSubview:button];
      [thebuttons addObject:button];
    }
    self.buttons = thebuttons;
    self.value = GBColorLabelClear;
  }
  return self;
}

- (void) setValue:(NSString *)aValue
{
  if (!aValue) aValue = GBColorLabelClear;
  
  if ([value isEqual:aValue]) return;
  
  [value release];
  value = [aValue retain];
  
  if (!value)
  {
    [self.selectionImageView setHidden:YES];
    return;
  }
  
  [self.selectionImageView setHidden:NO];
  
  NSArray* values = [self allValues];
  
  for (int i = 0; i < [values count]; i++)
  {
    GBColorLabelPickerButton* button = [self.buttons objectAtIndex:i];
    button.selected = NO;
    NSString* aValue = [values objectAtIndex:i];
    if ([aValue isEqual:value])
    {
      [self.selectionImageView setFrame:[self frameForIndex:i]];
      button.selected = YES;
    }
  }
}

- (void) setHighlightedValue:(NSString *)aValue
{
  if (!aValue && !highlightedValue) return;
  if (aValue && [highlightedValue isEqual:aValue]) return;
  
  [highlightedValue release];
  highlightedValue = [aValue retain];
  
  if (!highlightedValue || [value isEqual:highlightedValue])
  {
    [self.highlightImageView setHidden:YES];
    return;
  }
  
  [self.highlightImageView setHidden:NO];
  
  NSArray* values = [self allValues];
  
  for (int i = 0; i < [values count]; i++)
  {
    NSString* aValue = [values objectAtIndex:i];
    if ([aValue isEqual:highlightedValue])
    {
      [self.highlightImageView setFrame:[self frameForIndex:i]];
      break;
    }
  }
}

- (void) didClickValue:(NSString*)aValue
{
  self.value = aValue;
  if (self.action) [NSApp sendAction:self.action to:self.target from:self];
}

- (void) didHighlightValue:(NSString*)aValue
{
  self.highlightedValue = aValue;
}

- (void) didUnhighlightValue:(NSString*)aValue
{
  if (self.highlightedValue && aValue && [self.highlightedValue isEqual:aValue])
  {
    self.highlightedValue = nil;
  }
}

@end







@implementation GBColorLabelPickerButton

@synthesize picker;
@synthesize value;
@synthesize selected;

+ (id) buttonWithValue:(NSString*)value picker:(GBColorLabelPicker*)picker
{
  GBColorLabelPickerButton* button = [[[self alloc] initWithFrame:NSMakeRect(0, 0, buttonSize, buttonSize)] autorelease];
  button.value = value;
  button.picker = picker;
  [button setImage:[NSImage imageNamed:[NSString stringWithFormat:@"%@.png", value]]];
  return button;
}

- (void) setSelected:(BOOL)flag
{
  if (selected == flag) return;
  selected = flag;
  [self setNeedsDisplay:YES];
}

- (void) drawRect:(NSRect)dirtyRect
{
  if (self.selected)
  {
    NSRectClip(NSInsetRect([self bounds], 4, 4));
  }
  [super drawRect:dirtyRect];
}

- (void) mouseDown:(NSEvent *)theEvent
{
}

- (void) mouseUp:(NSEvent *)theEvent
{
  [self.picker didClickValue:value];
}

- (void) mouseEntered:(NSEvent *)theEvent
{
  [self.picker didHighlightValue:value];
}

- (void) mouseExited:(NSEvent *)theEvent
{
  [self.picker didUnhighlightValue:value];
}

- (void) viewDidMoveToWindow
{
  // This enables receiving mouseEntered/mouseExited events
  [self addTrackingRect:[self bounds] owner:self userData:nil assumeInside:NO];
}
@end




