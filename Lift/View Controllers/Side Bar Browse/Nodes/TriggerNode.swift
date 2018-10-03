//
//  TriggerNode.swift
//  Lift
//
//  Created by Carl Wieland on 10/2/18.
//  Copyright © 2018 Datum Apps. All rights reserved.
//

import Foundation

class TriggerNode: TableChildNode {

    public private(set) weak var trigger: Trigger?
    init(parent: DataProvider, trigger: Trigger) {
        self.trigger = trigger
        super.init(name: trigger.name, provider: parent)

    }
}
