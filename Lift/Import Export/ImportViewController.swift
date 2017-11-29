//
//  ImportWindowController.swift
//  Lift
//
//  Created by Carl Wieland on 10/24/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Cocoa
import SwiftXLSX

class ImportViewController: LiftViewController {

    @objc dynamic var importPath: URL? {
        didSet {
            refreshContent()
        }
    }

    @IBOutlet weak var tabControl: TabControl!
    @IBOutlet weak var tabView: NSTabView!
    @IBOutlet var tabViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var tabControlHeightConstraint: NSLayoutConstraint!

    @IBAction func chooseImportPath(_ sender: Any) {

        let chooser = NSOpenPanel()
        chooser.canChooseDirectories = true
        chooser.canChooseFiles = true

        let responseHandler: (NSApplication.ModalResponse) -> Void = { _ in
            self.importPath = chooser.url
        }

        if let window = view.window {
            chooser.beginSheetModal(for: window, completionHandler: responseHandler)
        } else {
            let response = chooser.runModal()
            responseHandler(response)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        hideContentView()
    }

    private func hideContentView() {
        tabControl.isHidden = true
        tabView.isHidden = true
        tabViewHeightConstraint.constant = 0
        tabViewHeightConstraint.isActive = true
        tabControlHeightConstraint.constant = 0
        tabControlHeightConstraint.isActive = true
    }

    private func showContentView() {
        tabControl.animator().isHidden = false
        tabView.animator().isHidden = false
        tabViewHeightConstraint.isActive = false
        tabControlHeightConstraint.isActive = false
        tabControl.reloadData()
    }

    func refreshContent() {
        guard let url = importPath else {
            hideContentView()
            return
        }

        var isDir: ObjCBool = false
        FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)

        if isDir.boolValue {
            // open files in the folder for processing
            if let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys:nil) {
                for case let fileURL as URL in enumerator {
                    checkForImport(from: fileURL)
                }
            }
        } else {
            // process file
            checkForImport(from: url)
        }

        if tabView.numberOfTabViewItems == 0 {
            hideContentView()
        } else {
            showContentView()
        }
    }

    func checkForImport(from file: URL) {


    }

}

extension ImportViewController: TabControlDatasource {
    func numberOfTabsFor(_ control: TabControl) -> Int {
        return tabView.numberOfTabViewItems
    }

    func tabControl(_ control: TabControl, itemAt index: Int) -> Any {
        return tabView.tabViewItem(at: index)
    }

    func tabControl(_ control: TabControl, titleKeyPathFor item: Any) -> String {
        return "viewController.title"
    }

    func tabControl(_ control: TabControl, canReorder item: Any) -> Bool {
        return true
    }

    func tabControl(_ control: TabControl, didReorderItems items: [Any]) -> Bool {
        guard let newItems = items as? [NSTabViewItem] else {
            return false
        }

        tabView.removeAllItems()
        for item in newItems {
            tabView.addTabViewItem(item)
        }

        return true
    }


    func tabControl(_ control: TabControl, menuFor item: Any) -> NSMenu? {
        return nil
    }

    func tabControl(_ control: TabControl, didSelect item: Any) {
        guard let tabItem = item as? NSTabViewItem else {
            fatalError("Not getting what I expect back!")
        }
        tabView.selectTabViewItem(tabItem)
    }

    func tabControl(_ control: TabControl, canEdit item: Any) -> Bool {
        return true
    }

    func tabControl(_ control: TabControl, setTitle title: String, for item: Any) {

    }
}



fileprivate enum ImportType {



    case failed
    case xml
    case json
    case csv
    case sqlite
    case xlsx
    case text

    static func importType(for url: URL) -> ImportType? {
        
        guard var data = try? Data(contentsOf: url, options: .mappedIfSafe) else {
            return .failed
        }
        
        do {
            _ = try JSONSerialization.jsonObject(with: data, options: [])
            return .json
        } catch {
            print("file's not JSON")
        }

        if Workbook(path: url) != nil {
            return .xlsx
        }

        do {
            _ = try XMLDocument(contentsOf: url, options: [])
            return .xml
        } catch {
            print("Not XML")
        }

        guard let str = String(bytesNoCopy: &data, length: data.count, encoding: .utf8, freeWhenDone: false) else {
            return .failed
        }


        return .text

    }

}
