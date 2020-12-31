//
//  DisplayIcon.swift
//  RDM
//
//  Created by usrsse2 on 16.12.2020.
//  Copyright © 2020 гык-sse2. All rights reserved.
//

import Cocoa

public let kDisplayIcon = "display-icon"
public let kDisplayResolutionPreviewIcon = "display-resolution-preview-icon"

public let kResolutionPreviewWidth = "resolution-preview-width"
public let kResolutionPreviewHeight = "resolution-preview-height"
public let kResolutionPreviewX = "resolution-preview-x"
public let kResolutionPreviewY = "resolution-preview-y"

class DisplayIcon : NSObject
{
    @objc var Properties : [String : AnyHashable]

    @objc var DisplayIcon : NSImage? {
        get {
            if let imagePath = Properties[kDisplayIcon] as? String {
                return NSImage(contentsOfFile: imagePath)      
            }
            return nil
        }
    }
    
    @objc var DisplayResolutionPreviewIcon : NSImage? {
        get {
            if let imagePath = Properties[kDisplayResolutionPreviewIcon] as? String {
                return NSImage(contentsOfFile: imagePath)            
            }
            return nil
        }
    }
    
    private func GetValueOrZero(forKey key: String) -> Int {
        if let i = Properties[key] as? Int {
            return i
        }
        return 0
    }
    
    private func SetOrRemoveValue(forKey key: String, value: Int) {
        if value == 0 {
            Properties.removeValue(forKey: key)
        }
        else {
            Properties[key] = value
        }
    }
    
    @objc var ResolutionPreviewWidth : Int {
        get {
            return GetValueOrZero(forKey: kResolutionPreviewWidth)
        }
        set(value) {
            SetOrRemoveValue(forKey: kResolutionPreviewWidth, value: value)
        }
    }
    
    @objc var ResolutionPreviewHeight : Int {
        get {
            return GetValueOrZero(forKey: kResolutionPreviewHeight)
        }
        set(value) {
            SetOrRemoveValue(forKey: kResolutionPreviewHeight, value: value)
        }
    }

    @objc var ResolutionPreviewX : Int {
        get {
            return GetValueOrZero(forKey: kResolutionPreviewX)
        }
        set(value) {
            SetOrRemoveValue(forKey: kResolutionPreviewX, value: value)
        }
    }
    
    @objc var ResolutionPreviewY : Int {
        get {
            return GetValueOrZero(forKey: kResolutionPreviewY)
        }
        set(value) {
            SetOrRemoveValue(forKey: kResolutionPreviewY, value: value)
        }
    }
    
    init(properties : [String : AnyHashable]) {
        Properties = properties
    }
    
    static func ==(lhs: DisplayIcon, rhs: DisplayIcon) -> Bool {
        return lhs.Properties == rhs.Properties
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        if let other = object as? DisplayIcon {
            return 
                Properties == other.Properties || 
                Properties.filter({$0.key != kDisplayResolutionPreviewIcon && $0.key != kDisplayIcon}) == other.Properties.filter({$0.key != kDisplayResolutionPreviewIcon && $0.key != kDisplayIcon}) &&
                DisplayResolutionPreviewIcon?.tiffRepresentation == other.DisplayResolutionPreviewIcon?.tiffRepresentation &&
                DisplayIcon?.tiffRepresentation == other.DisplayIcon?.tiffRepresentation
        }
        return false
    }
    
    override var hash: Int {
        return 0 // Properties.hashValue //Int(_width | _height | (UInt32)(_hiDPIFlag & 0xffffffff))
    }

}
