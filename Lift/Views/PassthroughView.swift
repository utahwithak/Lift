//
//  PassthroughView.swift
//  Lift
//
//  Created by Carl Wieland on 10/14/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Cocoa

class PassthroughView: NSView {

    override func hitTest(_ point: NSPoint) -> NSView? {
        return nil
    }

}
