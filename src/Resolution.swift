//
//  Resolution.swift
//  RDM-2
//
//  Created by JNR on 26/08/2020.
//  Copyright © 2020 гык-sse2. All rights reserved.
//

import Foundation

let kFlagHiDPI         : UInt64 = 0x0000000100000000
let kFlagUnknown1      : UInt64 = 0x0000000000200000
let kFlagRetinaDisplay : UInt64 = 0x0000000800000000
let kFlagUnknown2      : UInt64 = 0x0000000000800000
let kFlagUnknown3      : UInt64 = 0x0000000200000000

@objc class Resolution : NSObject {
    private var _width     : UInt32
    private var _height    : UInt32
    private var _hiDPIFlag : UInt64
    
    var hiDPIMode : UInt64 {
        get {
            return _hiDPIFlag
        }
    }
    
    private var isHiDPI : Bool {
        get {
            return _hiDPIFlag & kFlagHiDPI != 0
        }
    }

    @objc dynamic var width : UInt32 {
        get {
            return isHiDPI ? _width / 2 : _width
        }

        set(value) {
            _width = isHiDPI ? value * 2 : value
        }
    }

    @objc dynamic var height : UInt32 {
        get {
            return isHiDPI ? _height / 2 : _height
        }

        set(value) {
            _height = isHiDPI ? value * 2 : value
        }
    }
    
    func setFlag(_ flag : UInt64, _ value : Bool) {
        if value {
            RawFlags = RawFlags | flag
        }
        else {
            RawFlags = RawFlags & ~flag
        }
    }

    @objc dynamic var RawFlags : UInt64 {
        get {
            return _hiDPIFlag
        }
        set(value) {
            willChangeValue(forKey: "HiDPI")
            willChangeValue(forKey: "Retina")
            willChangeValue(forKey: "Unknown1")
            willChangeValue(forKey: "Unknown2")
            willChangeValue(forKey: "Unknown3")
            let wasHiDPI = isHiDPI
            _hiDPIFlag = value
            if isHiDPI != wasHiDPI {
                if isHiDPI {
                    _width  *= 2
                    _height *= 2
                } else {
                    _width  /= 2
                    _height /= 2
                }
            }
            didChangeValue(forKey: "HiDPI")
            didChangeValue(forKey: "Retina")
            didChangeValue(forKey: "Unknown1")
            didChangeValue(forKey: "Unknown2")
            didChangeValue(forKey: "Unknown3")
        }
    }
    
    @objc dynamic var HiDPI : Bool {
        get {
            return RawFlags & kFlagHiDPI != 0
        }
        set(value) {
            setFlag(kFlagHiDPI, value)
        }
    }
    
    @objc dynamic var Retina : Bool {
        get {
            return RawFlags & kFlagRetinaDisplay != 0
        }
        set(value) {
            setFlag(kFlagRetinaDisplay, value)
        }
    }

    @objc var Unknown1 : Bool {
        get {
            return RawFlags & kFlagUnknown1 != 0
        }
        set(value) {
            setFlag(kFlagUnknown1, value)
        }
    }

    @objc dynamic var Unknown2 : Bool {
        get {
            return RawFlags & kFlagUnknown2 != 0
        }
        set(value) {
            setFlag(kFlagUnknown2, value)
        }
    }
    
    @objc dynamic var Unknown3 : Bool {
        get {
            return RawFlags & kFlagUnknown3 != 0
        }
        set(value) {
            setFlag(kFlagUnknown3, value)
        }
    }
    
    override init() {
        self._width = 0
        self._height = 0
        self._hiDPIFlag = kFlagRetinaDisplay | kFlagHiDPI | kFlagUnknown1

        super.init()
    }

    private init(width : UInt32, height : UInt32, flags : UInt64) {
        self._width     = width
        self._height    = height
        self._hiDPIFlag = flags

        super.init()
    }

    convenience init(nsdata : NSData?) {
        if let nsdata = nsdata {
            let array = nsdata.getArrayOfSwappedBytes(asType: UInt32.self)
            var flags : UInt64 = 0
            if array.count >= 3 {
                flags |= UInt64(array[2]) << 32
                if array.count >= 4 {
                    flags |= UInt64(array[3])
                }
            }
            self.init(width:  array[0],
                      height: array[1],
                      flags:  flags)
        } else {
            self.init()
        }
    }
    
    static func bytes(number : UInt32) -> [UInt8] {
        return [UInt8(number >> 24), UInt8((number >> 16) & 0xff), UInt8((number >> 8) & 0xff), UInt8(number & 0xff)]
    }

    func toData() -> NSData {
        // TODO: check on big-endian platforms!
        // is ARM big-endian or little-endian?
        
        var d = Data()
        d.append(contentsOf: Resolution.bytes(number: _width))
        d.append(contentsOf: Resolution.bytes(number: _height))
        if _hiDPIFlag != 0 {
            d.append(contentsOf: Resolution.bytes(number: UInt32(_hiDPIFlag >> 32)))
            if _hiDPIFlag & 0xffffffff != 0 {
                d.append(contentsOf: Resolution.bytes(number: UInt32(_hiDPIFlag & 0xffffffff)))
            }
        }
        
        return d as NSData
    }

    static func ==(lhs: Resolution, rhs: Resolution) -> Bool {
        return (lhs._height    == rhs._height   )
            && (lhs._width     == rhs._width    )
            && (lhs._hiDPIFlag == rhs._hiDPIFlag)
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        if let other = object as? Resolution {
            return _width == other._width && _height == other._height && _hiDPIFlag == other._hiDPIFlag
        }
        return false
    }
    
    override var hash: Int {
        return 0 //Int(_width | _height | (UInt32)(_hiDPIFlag & 0xffffffff))
    }
}
