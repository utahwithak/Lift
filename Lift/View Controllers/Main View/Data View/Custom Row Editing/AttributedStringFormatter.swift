//
//  AttributedStringFormatter.swift
//  Lift
//
//  Created by Carl Wieland on 3/7/18.
//  Copyright © 2018 Datum Apps. All rights reserved.
//

import Foundation

class AttributedStringConverter: ValueTransformer {
    override class func transformedValueClass() -> Swift.AnyClass {
        return NSAttributedString.self
    }

    override class func allowsReverseTransformation() -> Bool {
        return true
    }

    override func transformedValue(_ value: Any?) -> Any? {
        if let val = value as? String {
            return NSAttributedString(string: val)
        }
        return nil

    }

    override func reverseTransformedValue(_ value: Any?) -> Any? {
        if let attrString = value as? NSAttributedString {
            return attrString.string
        }

        return nil
    }
}
