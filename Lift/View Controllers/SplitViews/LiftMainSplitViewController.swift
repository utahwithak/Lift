//
//  LiftMainSplitViewController.swift
//  Lift
//
//  Created by Carl Wieland on 10/17/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Cocoa

class LiftMainSplitViewController: LiftSplitViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        if let middleView = splitViewItems[1].viewController as? LiftSplitViewController {
            middleView.splitDelegate = self
        }
    }

    var sideBar: SideBarBrowseViewController? {
        return splitViewItems[0].viewController as? SideBarBrowseViewController
    }

    var mainEditor: LiftMainEditorTabViewController? {
        return (splitViewItems[1].viewController as? NSSplitViewController)?.splitViewItems[0].viewController as? LiftMainEditorTabViewController
    }

    var bottomEditorContainer: BottomEditorContainer? {
        return (splitViewItems[1].viewController as? NSSplitViewController)?.splitViewItems[1].viewController as? BottomEditorContainer
    }

    var detailsViewController: SideBarDetailsViewController? {
        return splitViewItems[2].viewController as? SideBarDetailsViewController
    }

    func setLocation(_ location: SplitViewLocation, collapsed: Bool) {
        switch location {
        case .left:
            splitViewItems[0].animator().isCollapsed = collapsed
        case .bottom:
            (splitViewItems[1].viewController as! LiftSplitViewController).splitViewItems[1].animator().isCollapsed = collapsed
        case .right:
            splitViewItems[2].animator().isCollapsed = collapsed
        }
    }

    override func splitViewDidResizeSubviews(_ notification: Notification) {

        splitDelegate?.didUpdateState(for: .left, collapsed: splitViewItems[0].isCollapsed)

        splitDelegate?.didUpdateState(for: .right, collapsed: splitViewItems[2].isCollapsed)

    }

}

extension LiftMainSplitViewController: LiftSplitViewDelegate {
    func didUpdateState(for location: SplitViewLocation, collapsed: Bool) {
        splitDelegate?.didUpdateState(for: location, collapsed: collapsed)
    }
}
