//
//  PassThroughScrollView.swift
//  Lift
//
//  Created by Carl Wieland on 10/19/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Cocoa

class PassThroughScrollView: NSScrollView {
    override func scrollWheel(with event: NSEvent) {
        nextResponder?.scrollWheel(with: event)
    }
}
