//
//  URLPathFormatter.swift
//  Lift
//
//  Created by Carl Wieland on 1/2/18.
//  Copyright © 2018 Datum Apps. All rights reserved.
//

import Foundation

class URLPathFormatter: ValueTransformer {
    override func transformedValue(_ value: Any?) -> Any? {
        guard let url = value as? URL else {
            return ""
        }

        let path = url.path
        return path.replacingOccurrences(of: "/Users/\(NSUserName())/", with: "~/")

    }

    
}
