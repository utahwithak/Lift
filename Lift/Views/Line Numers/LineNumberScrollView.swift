//
//  LineNumberScrollView.swift
//  Lift
//
//  Created by Carl Wieland on 10/3/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Cocoa

class LineNumberScrollView: NSScrollView {

    var lineNumberView: LineNumberView?

    override func awakeFromNib() {
        lineNumberView = LineNumberView(scrollView: self)
        self.verticalRulerView = lineNumberView
        self.rulersVisible = true

    }
}
