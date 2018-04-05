//
//  TableScrollView.swift
//  Lift
//
//  Created by Carl Wieland on 10/9/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Cocoa

class TableScrollView: NSScrollView {

    public private(set) var lineNumberView: TableNumberView!

    required init?(coder: NSCoder) {

        super.init(coder: coder)

        lineNumberView = TableNumberView(scrollView: self)
        self.verticalRulerView = lineNumberView
        self.rulersVisible = true

    }

}
