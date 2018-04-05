//
//  LogViewController.swift
//  Lift
//
//  Created by Carl Wieland on 10/27/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Cocoa

class LogViewController: LiftViewController {

    @IBOutlet var arrayController: FilterableArrayController!
    @objc dynamic var log = [String]()

    override var representedObject: Any? {
        didSet {
            if let document = document {
                log = document.database.history.reversed()
            }
        }
    }

    @IBAction func clearHistory(_ sender: Any) {
        log = []
        document?.database.clearHistory()
    }

    @IBAction func copy(_ sender: Any) {
        guard let lines =  arrayController.selectedObjects as? [String] else {
            return
        }

        if !lines.isEmpty {
            NSPasteboard.general.declareTypes([.string], owner: nil)
            NSPasteboard.general.setString(lines.joined(separator: "\n"), forType: .string)
        }
    }

}

extension LogViewController: NSTableViewDelegate {
    static let attributes: [NSAttributedStringKey: Any] = [.font: NSFont.systemFont(ofSize: 13)]

    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {

        guard let str = (arrayController.arrangedObjects as? NSArray)?[row] as? NSString else {
            return 19
        }

        let rect = str.boundingRect(with: CGSize(width: tableView.frame.width, height: CGFloat.greatestFiniteMagnitude), options: .usesLineFragmentOrigin, attributes: LogViewController.attributes)

        return max(19, rect.size.height)

    }
}

class FilterableArrayController: NSArrayController {
    var searchString: String?

    override func arrange(_ objects: [Any]) -> [Any] {

        guard let searchString = searchString, !searchString.isEmpty, let strs = objects as? [String] else {
            return super.arrange(objects)
        }

        let filtered = strs.filter({ $0.localizedCaseInsensitiveContains(searchString)})

        return super.arrange(filtered)
    }

    @IBAction func search(_ sender: NSSearchField) {

        searchString = sender.stringValue

        rearrangeObjects()
    }
}
