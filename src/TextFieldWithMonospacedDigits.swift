//
//  TextFieldWithMonospacedDigits.swift
//  RDM
//
//  Created by usrsse2 on 01.12.2020.
//  Copyright © 2020 гык-sse2. All rights reserved.
//

import Foundation
import Cocoa

class TextFieldWithMonospacedDigits : NSTextField {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        font = super.font
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        font = super.font
    }
    
    override var font: NSFont? {
        get {
            return super.font
        }
        set (value) {
            if let font = value {
                let origDesc = CTFontCopyFontDescriptor(font)
                let monoDesc = CTFontDescriptorCreateCopyWithFeature(origDesc, kNumberSpacingType as CFNumber, kMonospacedNumbersSelector as CFNumber)
                let monoFont = CTFontCreateWithFontDescriptor(monoDesc, font.pointSize, nil)
                super.font = monoFont
            }
        }
    }
}
