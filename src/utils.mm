
#import <Foundation/Foundation.h>
#import <IOKit/graphics/IOGraphicsLib.h>

#import <dlfcn.h>

#import "utils.h"


void CopyAllDisplayModes(CGDirectDisplayID display, modes_D4** modes, int* cnt)
{
    int nModes;
    CGSGetNumberOfDisplayModes(display, &nModes);
    
    if (nModes)
        *cnt = nModes;
    
    if (!modes)
        return;
    
    *modes = (modes_D4*) malloc(sizeof(modes_D4)* nModes);
    for (int i=0; i<nModes; i++)
    {        
        CGSGetDisplayModeDescriptionOfLength(display, i, &(*modes)[i], 0xD4);
    }
}

void SetDisplayModeNum(CGDirectDisplayID display, int modeNum)
{
    CGDisplayConfigRef config;
    CGBeginDisplayConfiguration(&config);
    CGSConfigureDisplayMode(config, display, modeNum);
    CGCompleteDisplayConfiguration(config, kCGConfigurePermanently);
}


io_service_t IOServicePortFromCGDisplayID(CGDirectDisplayID displayID)
{
    io_iterator_t iter;
    io_service_t serv, servicePort = 0;
    
    // releases matching for us
    if (IOServiceGetMatchingServices(kIOMasterPortDefault,
                                     IOServiceMatching("IODisplayConnect"),
                                     &iter) != 0) {
        return 0;
    }
    
    CFDictionaryRef info;
    CFIndex vendorID, productID;
    CFNumberRef vendorIDRef, productIDRef;
    
    while ((serv = IOIteratorNext(iter)) != 0) {
        info = IODisplayCreateInfoDictionary(serv,
                                             kIODisplayOnlyPreferredName);
        
        vendorIDRef = static_cast<CFNumberRef>(CFDictionaryGetValue(info,
                                                                    CFSTR(kDisplayVendorID)));
        productIDRef = static_cast<CFNumberRef>(CFDictionaryGetValue(info,
                                                                     CFSTR(kDisplayProductID)));
        
        if (vendorIDRef == nullptr || productIDRef == nullptr) {
            CFRelease(info);
            continue;
        }
        
        CFNumberGetValue(vendorIDRef, kCFNumberCFIndexType,
                         &vendorID);
        CFNumberGetValue(productIDRef, kCFNumberCFIndexType,
                         &productID);
        
        if (CGDisplayVendorNumber(displayID) != vendorID ||
            CGDisplayModelNumber(displayID) != productID) {
            CFRelease(info);
            continue;
        }
        
        // we're a match
        servicePort = serv;
        CFRelease(info);
        break;
    }
    
    IOObjectRelease(iter);
    return servicePort;
}
