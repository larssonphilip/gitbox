
typedef enum {
  GBCloneStateIdle = 0,
  GBCloneStateInProgress,
  GBCloneStateFinished,
  GBCloneStateFailed,
  GBCloneStateCancelled
} GBCloneState;

@interface GBCloneWindowController : NSWindowController<NSWindowDelegate>
{
  GBCloneState state;
}

@property(retain) IBOutlet NSTextField* urlField;
@property(retain) IBOutlet NSProgressIndicator* progressIndicator;
@property(retain) IBOutlet NSTextField* messageLabel;
@property(retain) IBOutlet NSButton* cloneButton;

- (IBAction) cancel:_;
- (IBAction) ok:_;

@end
