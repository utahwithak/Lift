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
}
