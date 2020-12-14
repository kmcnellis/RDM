


@interface RDMAppDelegate : NSObject <NSApplicationDelegate, NSMenuDelegate>
{
    NSMenu* statusMenu;
    NSWindowController* editResolutionsController;
    NSStatusItem* statusItem;
    dispatch_queue_t queue;
}
- (void) refreshStatusMenu;
@end

