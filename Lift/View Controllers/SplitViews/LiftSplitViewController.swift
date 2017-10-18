//
//  ViewController.swift
//  Lift
//
//  Created by Carl Wieland on 9/28/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Cocoa
enum SplitViewLocation {
    case left
    case right
    case bottom
}

protocol LiftSplitViewDelegate: class {
    func didUpdateState(for location: SplitViewLocation, collapsed: Bool)
}

class LiftSplitViewController: NSSplitViewController {

    weak var splitDelegate: LiftSplitViewDelegate?

    override func viewDidLoad() {
    
        splitView.delegate = self
        
        super.viewDidLoad()

    }

    override var representedObject: Any? {
        didSet {
            for item in splitViewItems {
                item.viewController.representedObject = representedObject
            }

        }
    }

    override func splitViewDidResizeSubviews(_ notification: Notification) {
        splitDelegate?.didUpdateState(for: .bottom, collapsed: splitViewItems[1].isCollapsed)
    }

}

