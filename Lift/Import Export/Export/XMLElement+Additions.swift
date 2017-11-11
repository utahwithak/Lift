//
//  XMLElement+Additions.swift
//  Yield
//
//  Created by Carl Wieland on 5/2/17.
//  Copyright © 2017 Datum. All rights reserved.
//

import Cocoa

extension XMLElement {
    func addAttribute(name: String, value: String) {
        let attribute = XMLElement(kind: .attribute)
        attribute.name = name
        attribute.stringValue = value
        addAttribute(attribute)
    }
}
