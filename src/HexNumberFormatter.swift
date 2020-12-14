//
//  HexNumberFormatter.swift
//  RDM
//
//  Created by usrsse2 on 30.11.2020.
//  Copyright © 2020 гык-sse2. All rights reserved.
//

import Foundation
import Cocoa

class ParseError : Error {
}

class HexNumberFormatter : NumberFormatter {
    override func string(for obj: Any?) -> String? {
        if let number = obj as? UInt64 {
            return String(format: "%016lx", number)
        }
        return nil
    }
    
    override func getObjectValue(_ obj: AutoreleasingUnsafeMutablePointer<AnyObject?>?, for string: String, range rangep: UnsafeMutablePointer<NSRange>?) throws {
        if let num = UInt64(string, radix: 16) {
            obj?.pointee = NSNumber(value: num)
            rangep?.pointee = NSMakeRange(0, string.count)
        }
        else {
            throw ParseError()
        }
    }
}
