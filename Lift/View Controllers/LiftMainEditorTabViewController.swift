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
    case graph
    case query
}

class LiftMainEditorTabViewController: NSTabViewController {

    override var representedObject: Any? {
        didSet {
            for item in tabViewItems {
                item.viewController?.representedObject = representedObject
            }

        }
    }


    var sideBarViewController: SideBarDetailsViewController?

    
    func switchMainView( to editorType: MainEditorType) {
        switch editorType {
        case .table:
            selectedTabViewItemIndex = 0
        case .graph:
            selectedTabViewItemIndex = 1
        case .query:
            selectedTabViewItemIndex = 2
        }

    }

    override var selectedTabViewItemIndex: Int {
        didSet {
            sideBarViewController?.contentProvider = tabViewItems[selectedTabViewItemIndex].viewController as? DetailsContentProvider
        }
    }
}
