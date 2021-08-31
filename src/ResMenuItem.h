


static inline CFDictionaryRef CGDisplayModeGetDictionary(CGDisplayModeRef mode) {
    CFDictionaryRef infoDict = ((CFDictionaryRef *)mode)[2]; // DIRTY, dirty, smelly, no good very bad hack
    return infoDict;
}


@interface ResMenuItem : NSMenuItem
{
    CGDirectDisplayID _display;

    int modeNum;

    //CGDisplayModeRef _mode;

    int refreshRate;
    float scale;
    int colorDepth;
    int width;
    int height;
    NSString* emoji;
}



- (id) initWithDisplay: (CGDirectDisplayID) display andMode: (modes_D4*) mode;

- (id) copyWithZone:(NSZone *)zone;

- (CGDirectDisplayID) display;

- (void) setTextFormat: (int) textFormat;

- (void) setEmoji: (NSString*) e;


//- (CGDisplayModeRef) mode;

- (int) modeNum;

- (int) colorDepth;
- (int) width;
- (int) height;
- (int) refreshRate;
- (float) scale;
- (float) aspectRatio;

- (NSComparisonResult) compareResMenuItem: (ResMenuItem*) otherItem;

@end
