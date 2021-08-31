


#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

#import "utils.h"
#import "ResMenuItem.h"

@implementation ResMenuItem : NSMenuItem


- (id) initWithDisplay: (CGDirectDisplayID) display andMode: (modes_D4*) mode
{
    if ((self = [super initWithTitle: @"" action: @selector(setMode:) keyEquivalent: @""]) && display && mode)
    {
        _display = display;

        modeNum = mode->derived.mode;
        scale = mode->derived.density;

        width = mode->derived.width;
        height = mode->derived.height;

        refreshRate = mode->derived.freq;

        colorDepth = (mode->derived.depth == 4) ? 32 : 16;

        [self setEmoji:@""];
        [self setTextFormat:0];
        return self;
    }
    else
    {
        return NULL;
    }
}

- (id) copyWithZone:(NSZone *)zone
{
    ResMenuItem* copied = [super copyWithZone:zone];
    copied->_display = _display;
    copied->modeNum  = modeNum;
    copied->scale    = scale;
    copied->width    = width;
    copied->height   = height;
    copied->refreshRate = refreshRate;
    copied->colorDepth  = colorDepth;
    return copied;
}

- (void) setTextFormat: (int) textFormat
{
    NSString* title;
    title = [NSString stringWithFormat: @"%d × %d%@", width, height, emoji];

    if (refreshRate && textFormat == 0)
        title = [NSString stringWithFormat: @"%d × %d%@, %d Hz", width, height, emoji, refreshRate];

    if (refreshRate && textFormat == 2)
        title = [NSString stringWithFormat: @"%d Hz", refreshRate];

    [self setTitle: title];
}

- (void) setEmoji: (NSString*) e
{
  if (scale == 2.0f)
  {
    emoji = [NSString stringWithFormat: @"%@ ⚡️",e];
  }
  else
  {
    emoji = [NSString stringWithFormat: @"%@",e];
  }

}

- (CGDirectDisplayID) display
{
    return _display;
}

- (int) modeNum
{
    return modeNum;
}

- (int) colorDepth
{
    return colorDepth;
}

- (int) width
{
    return width;
}

- (int) height
{
    return height;
}

- (int) refreshRate
{
    return refreshRate;
}

- (float) scale
{
    return scale;
}

- (float) aspectRatio
{
    return ((float) width)/((float) height);
}

- (NSComparisonResult) compareResMenuItem: (ResMenuItem*) otherItem
{
    {
        int o_width = [otherItem width];
        if (width < o_width)
            return NSOrderedDescending;
        else if (width > o_width)
            return NSOrderedAscending;
        //      return NSOrderedSame;
    }
    {
        int o_scale = [otherItem scale];
        if (scale < o_scale)
            return NSOrderedDescending;
        else if (scale > o_scale)
            return NSOrderedAscending;
        //      return NSOrderedSame;
    }
    {
        int o_height = [otherItem height];
        if (height < o_height)
            return NSOrderedDescending;
        else if (height > o_height)
            return NSOrderedAscending;
        //      return NSOrderedSame;
    }
    {
        int o_refreshRate = [otherItem refreshRate];
        if (refreshRate < o_refreshRate)
            return NSOrderedDescending;
        else if (refreshRate > o_refreshRate)
            return NSOrderedAscending;
        return NSOrderedSame;
    }


}

@end
