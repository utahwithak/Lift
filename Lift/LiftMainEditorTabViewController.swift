//
//  LiftMainEditorTabViewController.swift
//  Lift
//
//  Created by Carl Wieland on 10/5/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Cocoa

enum MainEditorType {
    case table
    case canvas
}

class LiftMainEditorTabViewController: NSTabViewController {

    
    func switchMainView( to editorType: MainEditorType) {
        switch editorType {
        case .table:
            selectedTabViewItemIndex = 0
        case .canvas:
            selectedTabViewItemIndex = 1
        }

    }
}
