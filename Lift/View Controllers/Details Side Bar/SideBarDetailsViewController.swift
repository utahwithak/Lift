//
//  SideBarDetailsViewController.swift
//  Lift
//
//  Created by Carl Wieland on 10/5/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Cocoa

protocol DetailsContentProvider: class {
    var preferredSections: [DetailSection] { get }
}

enum DetailSection {
    case database
    case table
    case custom(NSImage, NSViewController)

    var image: NSImage {
        switch self {
        case .database:
            return #imageLiteral(resourceName: "smallDB")
        case .table:
            return NSImage(named: NSImage.listViewTemplateName)!
        case .custom(let image, _):
            return image
        }
    }

    var identifier: NSStoryboard.SceneIdentifier? {
        switch self {
        case .database:
            return "databaseDetails"
        case .table:
            return "tableDetailView"
        case .custom:
            return nil
        }
    }
}
extension DetailSection: Equatable { }
func == (lhs: DetailSection, rhs: DetailSection) -> Bool {
    switch (lhs, rhs) {
    case (.database, .database), (.table, .table):
        return true
    case (.custom(let lI, let lVc ), .custom(let rI, let rVc)):
        return lI == rI && lVc == rVc
    default:
        return false
    }
}

class SideBarDetailsViewController: LiftViewController {

    @IBOutlet weak var segmentedControl: HiddenSegmentedControl! {
        didSet {
            oldValue?.removeFromSuperview()
        }
    }
    @IBOutlet weak var tabControl: NSTabView!

    override var representedObject: Any? {
        didSet {
            sections = [.database, .table]
        }
    }

    weak var contentProvider: DetailsContentProvider? {
        didSet {
            sections = contentProvider?.preferredSections ?? [.database]
        }
    }

    var sections: [DetailSection] = [.database, .table] {
        didSet {
            let pastIndex = segmentedControl.selectedSegment
            var pastVal: DetailSection?
            if pastIndex >= 0 && pastIndex < oldValue.count {
                pastVal = oldValue[pastIndex]
            }
            refreshSegmentedControl(oldSelection: pastVal, oldValues: oldValue)
        }
    }

    private func refreshSegmentedControl(oldSelection: DetailSection?, oldValues: [DetailSection]) {

        let images = sections.map({ $0.image })
        let segmentedControl = HiddenSegmentedControl(images: images, trackingMode: .selectAny, target: self, action: #selector(changeTab))
        segmentedControl.segmentStyle = .texturedSquare
        view.addSubview(segmentedControl)
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        view.addConstraint(NSLayoutConstraint(item: segmentedControl, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1, constant: 0))
        view.addConstraint(NSLayoutConstraint(item: segmentedControl, attribute: .leading, relatedBy: .greaterThanOrEqual, toItem: view, attribute: .leading, multiplier: 1, constant: 8))
        view.addConstraint(NSLayoutConstraint(item: segmentedControl, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1, constant: 0))
        segmentedControl.addConstraint(NSLayoutConstraint(item: segmentedControl, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 30))

        self.segmentedControl = segmentedControl

        for (index, section) in sections.enumerated() {
            if index < oldValues.count && section == oldValues[index] && index < tabControl.numberOfTabViewItems, let vc = tabControl.tabViewItem(at: index).viewController {
                vc.representedObject = representedObject
                continue
            } else {
                if index < tabControl.numberOfTabViewItems {
                    tabControl.tabViewItem(at: index).viewController?.representedObject = nil
                    tabControl.removeTabViewItem(at: index)
                }
            }

            var item: NSTabViewItem?
            if let identifier = section.identifier, let vc = storyboard?.instantiateController(withIdentifier: identifier) as? LiftViewController {
                vc.representedObject = representedObject
                item = NSTabViewItem(viewController: vc)
            } else if case .custom(_, let viewController) = section {
                viewController.representedObject = representedObject
                 item = NSTabViewItem(viewController: viewController)
            }

            if let item = item {
                if index < tabControl.numberOfTabViewItems {
                    tabControl.insertTabViewItem(item, at: index)
                } else {
                    tabControl.addTabViewItem(item)
                }
            }
        }

        var index = 0
        if let old = oldSelection, let newIndex = sections.index(of: old) {
            index = newIndex
        }

        segmentedControl.setSelected(true, forSegment: index)
        tabControl.selectTabViewItem(at: index)

    }

    @objc private func changeTab(_ control: HiddenSegmentedControl) {
        tabControl.selectTabViewItem(at: control.selectedSegment)
    }

}
