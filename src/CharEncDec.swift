//
//  CharEncDec.swift
//  RDM-2
//
//  Created by JNR on 26/08/2020.
//  Copyright © 2020 гык-sse2. All rights reserved.
//

import Foundation

// For decoding
extension NSData {
    func getArrayOfSwappedBytes<T: FixedWidthInteger>(asType: T.Type) -> [T] {
        let count = self.count / MemoryLayout<T>.size
        let ptr = self.bytes.assumingMemoryBound(to: asType)
        return (0..<count).map { ptr[$0].byteSwapped }
    }
}
