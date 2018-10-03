//
//  TableChildNode.swift
//  Lift
//
//  Created by Carl Wieland on 10/2/18.
//  Copyright © 2018 Datum Apps. All rights reserved.
//

import Foundation

class TableChildNode: BrowseViewNode {

    public private(set) weak var provider: DataProvider?
    init(name: String, provider: DataProvider) {
        self.provider = provider
        super.init(name: name)
    }
}
