//
//  BottomEditorContainer.swift
//  Lift
//
//  Created by Carl Wieland on 11/10/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Cocoa

protocol BottomEditorContentProvider: class {
    var editorViewController: LiftViewController { get }
}

class BottomEditorContainer: LiftViewController {

    weak var provider: BottomEditorContentProvider? {
        didSet {
            updateContent()
        }
    }

    private func updateContent() {
        view.subviews = []
        childViewControllers.removeAll(keepingCapacity: true)

        if let provider = provider {
            let controller = provider.editorViewController
            controller.view.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(controller.view)
            childViewControllers.append(controller)
            view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[view]|", options: [], metrics: nil, views: ["view": controller.view]))
            view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[view]|", options: [], metrics: nil, views: ["view": controller.view]))
        }
    }
}
