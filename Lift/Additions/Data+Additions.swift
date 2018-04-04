//
//  Data+Additions.swift
//  Lift
//
//  Created by Carl Wieland on 10/9/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Foundation
extension Data {
    func hexEncodedString() -> String {
        return map({ Data.hexCache[$0]!}).joined()
    }

    private static let hexCache: [UInt8: String] = {
        var tmp = [UInt8: String]()
        for i in 0...UInt8.max {
            tmp[i] = String(format: "%02x", i)
        }
        return tmp
    }()

    init<T>(from value: T) {
        var value = value
        self.init(buffer: UnsafeBufferPointer(start: &value, count: 1))
    }

    func to<T>(type: T.Type) -> T {
        return self.withUnsafeBytes { $0.pointee }
    }
}
