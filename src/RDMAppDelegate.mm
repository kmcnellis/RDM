

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <IOKit/graphics/IOGraphicsLib.h>

#import "RDMAppDelegate.h"

#import "utils.h"
#import "ResMenuItem.h"
#import "RDM-Swift.h"


#define MAX_DISPLAYS 0x10


void DisplayReconfigurationCallback(CGDirectDisplayID cg_id,
                                    CGDisplayChangeSummaryFlags change_flags,
                                    void *app_delegate)
{
    RDMAppDelegate *appDelegate = (__bridge RDMAppDelegate*)app_delegate;
    [appDelegate refreshStatusMenu];
}


@implementation RDMAppDelegate

- (void) showAbout
{
    [NSApp activateIgnoringOtherApps:YES];
    [NSApp orderFrontStandardAboutPanel:self];
}


- (void) quit
{
    [NSApp terminate: self];
}



- (void) refreshStatusMenu
{

    statusMenu = [[NSMenu alloc] initWithTitle: @""];

    uint32_t nDisplays;
    CGDirectDisplayID displays[MAX_DISPLAYS];
    CGGetOnlineDisplayList(MAX_DISPLAYS, displays, &nDisplays);

    for (int i=0; i<nDisplays; i++)
    {
        CGDirectDisplayID display = displays[i];
        {
            NSMenuItem* item;
            NSString* title = i ? [NSString stringWithFormat: @"Display %d", i+1] : @"Main Display";
            item = [[NSMenuItem alloc] initWithTitle: title action: nil keyEquivalent: @""];
            [item setEnabled: NO];
            [statusMenu addItem: item];
        }


        int mainModeNum;
        CGSGetCurrentDisplayMode(display, &mainModeNum);
        //modes_D4 mainMode;
        //CGSGetDisplayModeDescriptionOfLength(display, mainModeNum, &mainMode, 0xD4);

        int nModes;
        modes_D4* modes;
        CopyAllDisplayModes(display, &modes, &nModes);

        NSMutableArray* displayMenuItems = [NSMutableArray new];
        ResMenuItem*    currItem         = nil;
        int currentColorDepth = 32, currentRefreshRate = 0;

        {
            //ResMenuItem* mainItem = nil;
            for (int j = 0; j <nModes; j++)
            {
                ResMenuItem* item = [[ResMenuItem alloc] initWithDisplay: display andMode: &modes[j]];
                //[item autorelease];
                if (mainModeNum == j)
                {
                    currItem = item;
                    [item setState: NSControlStateValueOn];
                }
                [displayMenuItems addObject: item];
            }
            if (currItem)
            {
                currentColorDepth = [currItem colorDepth];
                currentRefreshRate = [currItem refreshRate];
            }
            [displayMenuItems sortUsingSelector: @selector(compareResMenuItem:)];

            NSMenu* submenu = [[NSMenu alloc] initWithTitle: @""];

            ResMenuItem *lastAddedItem = nil, *item = nil;
            for (int j=0; j < [displayMenuItems count]; j++)
            {
                item = [displayMenuItems objectAtIndex: j];

                if ([item colorDepth] == currentColorDepth)
                {
                    if ([item refreshRate] == currentRefreshRate)
                        [item setTextFormat: 1];

                    if (lastAddedItem
                        && [lastAddedItem width]  == [item width]
                        && [lastAddedItem height] == [item height]
                        && [lastAddedItem scale]  == [item scale])
                    {
                        double lastRefreshRate = [lastAddedItem refreshRate];
                        double refreshRate     = [item refreshRate];

                        if (lastRefreshRate != currentRefreshRate
                            && (refreshRate == currentRefreshRate
                                || refreshRate > lastRefreshRate))
                        {
                            [submenu removeItemAtIndex:[submenu numberOfItems] - 1];
                            [submenu addItem: item];
                            lastAddedItem = item;
                        }
                    }
                    else
                    {
                        [submenu addItem: item];
                        lastAddedItem = item;
                    }
                }
            }

            NSString *screenName = @"";
            NSDictionary *deviceInfo = (__bridge NSDictionary *)IODisplayCreateInfoDictionary(IOServicePortFromCGDisplayID(display),
                                                                                              kIODisplayOnlyPreferredName);
            NSDictionary *localizedNames = [deviceInfo objectForKey:[NSString stringWithUTF8String:kDisplayProductName]];
            CFRelease((CFDictionaryRef) deviceInfo);

            if ([localizedNames count] > 0)
                screenName = [localizedNames objectForKey:[[localizedNames allKeys] objectAtIndex:0]];


            [submenu addItem:[NSMenuItem separatorItem]];

            [submenu addItem:[[EditDisplayPlistItem alloc] initWithTitle:@"Edit..."
                                                                  action:@selector(editResolutions:)
                                                                vendorID:CGDisplayVendorNumber(display)
                                                               productID:CGDisplayModelNumber(display)
                                                             displayName:screenName]];

            [submenu addItem:[[RestoreSettingsItem alloc] initWithTitle:@"Restore..."
                                                                 action:@selector(restoreSettings:)
                                                               vendorID:CGDisplayVendorNumber(display)
                                                              productID:CGDisplayModelNumber(display)
                                                            displayName:screenName]];

            NSString* title = [currItem title];

            NSMenuItem* resolution = [[NSMenuItem alloc] initWithTitle: title action: nil keyEquivalent: @""];
            [resolution setSubmenu: submenu];
            [statusMenu addItem: resolution];
        }

        {
            NSMenu* submenu = [[NSMenu alloc] initWithTitle: @""];
            for (int j=0; j< [displayMenuItems count]; j++)
            {
                ResMenuItem* item = [displayMenuItems objectAtIndex: j];
                if (   [item colorDepth] == currentColorDepth
                    && [currItem width]  == [item width]
                    && [currItem height] == [item height]
                    && [currItem scale]  == [item scale])
                {
                    ResMenuItem* copiedItem = [item copyWithZone:nil];
                    [copiedItem setTextFormat:2];
                    if (mainModeNum == j)
                        [copiedItem setState: NSControlStateValueOn];

                    [submenu addItem: copiedItem];
                }
            }

            if (currentRefreshRate)
            {
                NSMenuItem* freq = [[NSMenuItem alloc] initWithTitle: [NSString stringWithFormat: @"%d Hz", currentRefreshRate]
                                                              action: nil
                                                       keyEquivalent: @""];

                if ([submenu numberOfItems] > 1)
                    [freq setSubmenu: submenu];
                else
                    [freq setEnabled: NO];
                [statusMenu addItem: freq];
            }
        }

        free(modes);

        [statusMenu addItem: [NSMenuItem separatorItem]];
    }

    if (nDisplays > 1) {
        NSMenuItem * mirroring = [[NSMenuItem alloc] initWithTitle:@"Display mirroring"
                                                            action:@selector(toggleMirroring:)
                                                     keyEquivalent: @""];

        mirroring.state = CGDisplayIsInMirrorSet(CGMainDisplayID());

        [statusMenu addItem:mirroring];
        [statusMenu addItem: [NSMenuItem separatorItem]];
    }

    [statusMenu addItemWithTitle: @"About RDM" action: @selector(showAbout) keyEquivalent: @""];


    [statusMenu addItemWithTitle: @"Quit" action: @selector(quit) keyEquivalent: @""];
    [statusMenu setDelegate: self];
    [statusItem setMenu: statusMenu];
}



- (void) editResolutions: (EditDisplayPlistItem *)sender {
    NSStoryboard *storyBoard = [NSStoryboard storyboardWithName:@"Main" bundle:nil];
    editResolutionsController = [storyBoard instantiateControllerWithIdentifier:@"edit"];
    ViewController *vc = (ViewController*)editResolutionsController.window.contentViewController;
    vc.vendorID = sender.vendorID;
    vc.productID = sender.productID;
    vc.displayProductName = sender.displayName;
    [editResolutionsController showWindow:self];
    [NSApp activateIgnoringOtherApps:YES];
}



- (void) restoreSettings: (RestoreSettingsItem *)sender {
    NSAlert* prompt = [[NSAlert alloc] init];
    [prompt addButtonWithTitle:@"OK"];
    [prompt addButtonWithTitle:@"Cancel"];
    [prompt setMessageText:[NSString stringWithFormat: @"Restore all settings for %@?",
                            [sender.displayName stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]]]];

    [prompt setInformativeText:@"Reboot is required to apply changes. For safety, settings under "
                               @"/System would not be removed if no backup file was found. "
                               @"Use Edit... menu to manually reset those settings anyway."];
    [prompt setAlertStyle:NSWarningAlertStyle];

    NSArray* buttons = [prompt buttons];
    [[buttons objectAtIndex:0] setKeyEquivalent:@"\r"];   // Return key
    [[buttons objectAtIndex:1] setKeyEquivalent:@"\033"]; // Esc key

    [NSApp activateIgnoringOtherApps:YES];
    [[prompt window] setLevel:NSFloatingWindowLevel];

    if ([prompt runModal] == NSAlertFirstButtonReturn) {
        NSAlert* alert;
        NSDictionary* error;

        if ((error = [sender restoreSettings]) != nil) {
            alert = [[NSAlert alloc] initFromDict:error style:NSAlertStyleCritical];
        } else {
            alert = [[NSAlert alloc] init];
            [alert setMessageText:[NSString stringWithFormat: @"Restore success!"]];
            [alert setAlertStyle:NSInformationalAlertStyle];
        }

        [NSApp activateIgnoringOtherApps:YES];
        [[alert window] setLevel:NSFloatingWindowLevel];

        [alert runModal];
    }
}



CGError multiConfigureDisplays(CGDisplayConfigRef configRef, CGDirectDisplayID *displays, int count, CGDirectDisplayID master) {
    CGError error;

    for (int i = 0; i < count; i++)
        if (displays[i] != master
            && (error = CGConfigureDisplayMirrorOfDisplay(configRef, displays[i], master)))
            return error;

    return kCGErrorSuccess;
}


- (void) toggleMirroring: (NSMenuItem *)sender {
    CGDisplayCount numberOfOnlineDspys;
    CGDirectDisplayID displays[MAX_DISPLAYS];
    CGDisplayConfigRef configRef;

    CGGetOnlineDisplayList(MAX_DISPLAYS, displays, &numberOfOnlineDspys);
    CGBeginDisplayConfiguration(&configRef);

    CGError error;
    if (!(error = multiConfigureDisplays(configRef, displays, numberOfOnlineDspys, sender.state ? kCGNullDirectDisplay : CGMainDisplayID())))
    {
        CGCompleteDisplayConfiguration(configRef, kCGConfigurePermanently);
    }
    else
    {
        CGCancelDisplayConfiguration(configRef);

        NSAlert* alert = [[NSAlert alloc] init];
        alert.window.level = NSFloatingWindowLevel;
        alert.alertStyle   = NSAlertStyleCritical;
        alert.messageText  = [NSString stringWithFormat:@"Cannot mirror displays!\nError: %@ (%d)", NSStringFromCGError(error), error];

        [NSApp activateIgnoringOtherApps:YES];
        [alert runModal];
    }
}


- (void) setMode: (ResMenuItem*) item
{
    CGDirectDisplayID display = [item display];
    int modeNum = [item modeNum];

    dispatch_async(self->queue, ^{
        SetDisplayModeNum(display, modeNum);
    });
}

- (void) applicationDidFinishLaunching: (NSNotification*) notification
{
    self->queue = dispatch_queue_create("setModeQueue", nil);
    // NSLog(@"Finished launching");
    [self refreshStatusMenu];
    CGDisplayRegisterReconfigurationCallback(DisplayReconfigurationCallback, (void*)self);

    // For empty box remained
    [IntegerValueTransformer registerTransformer];

    statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength: NSSquareStatusItemLength];
    [statusItem setMenu: statusMenu];

    NSImage* statusImage = [NSImage imageNamed: @"StatusIcon"];
    statusItem.button.image = statusImage;
    [statusItem.button.image setTemplate:YES];
}

@end
