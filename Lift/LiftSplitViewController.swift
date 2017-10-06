//
//  ViewController.swift
//  Lift
//
//  Created by Carl Wieland on 9/28/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Cocoa

class LiftSplitViewController: NSSplitViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        splitView.delegate = self
    }

    override var representedObject: Any? {
        didSet {
            for item in splitViewItems {
                item.viewController.representedObject = representedObject
            }

        }
    }


    

    var sideBar: SideBarBrowseViewController? {
        return splitViewItems[0].viewController as? SideBarBrowseViewController
    }

    var mainEditor: LiftMainEditorTabViewController? {
        return splitViewItems[1].viewController as? LiftMainEditorTabViewController
    }

    
    
    override func splitViewDidResizeSubviews(_ notification: Notification) {

        if splitViewItems[0].isCollapsed{
            print("Subview[0] is collapsed")
        }


        if splitViewItems[2].isCollapsed{
            print("Subview[2] is collapsed")
        }

    }

}

