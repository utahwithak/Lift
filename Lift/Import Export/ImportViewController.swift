//
//  ImportWindowController.swift
//  Lift
//
//  Created by Carl Wieland on 10/24/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Cocoa
import SwiftXLSX

protocol ImportViewDelegate: class {
    func importView(_ importVC: ImportViewController, showSQL text: String)
}


class ImportViewController: LiftViewController {

    @objc dynamic var importPath: URL?

    @IBOutlet weak var tabControl: TabControl!
    @IBOutlet weak var tabView: NSTabView!
    @IBOutlet var tabViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var tabControlHeightConstraint: NSLayoutConstraint!

    public weak var delegate: ImportViewDelegate?

    @IBAction func chooseImportPath(_ sender: Any) {

        let chooser = NSOpenPanel()
        chooser.canChooseDirectories = true
        chooser.canChooseFiles = true

        let responseHandler: (NSApplication.ModalResponse) -> Void = { _ in
            self.importPath = chooser.url
            self.refreshContent()

        }

        if let window = view.window {
            chooser.beginSheetModal(for: window, completionHandler: responseHandler)
        } else {
            let response = chooser.runModal()
            responseHandler(response)
        }
    }

    override func viewDidLoad() {
        tabView.removeAllItems()
        tabControl.reloadData()
        tabControl.datasource = self
        super.viewDidLoad()
        hideContentView()

        refreshContent()

    }

    private func hideContentView() {
        tabControl.isHidden = true
        tabView.isHidden = true
        tabViewHeightConstraint.constant = 0
        tabControlHeightConstraint.constant = 0
    }

    private func showContentView() {
        tabControl.animator().isHidden = false
        tabView.animator().isHidden = false
        tabViewHeightConstraint.constant = 150
        tabControlHeightConstraint.constant = 28

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

        let importType = ImportType.importType(for: file)

        switch importType {
        case .text(let text, let encoding):
            guard let vc = storyboard?.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("textInitialViewController")) as? TextImportViewController else {
                return
            }
            vc.encoding = encoding
            vc.delegate = self
            vc.text = text as NSString
            vc.title = file.lastPathComponent
            tabView.addTabViewItem(NSTabViewItem(viewController: vc))
        case .xlsx(let workbook):

            for sheet in workbook.sheets.sheets {

                guard let importView = storyboard?.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("importDataView")) as? ImportDataViewController else {
                    return
                }
                importView.delegate = self

                importView.data = sheet.sqliteData()
                importView.title = sheet.sheetName
                importView.representedObject = representedObject

                let newView = NSTabViewItem(viewController: importView)
                tabView.addTabViewItem(newView)
            }
        default:
            print("type:\(importType)")
        }

    }

}

extension ImportViewController: TextImportDelegate {
    func textImport(_ textVC: TextImportViewController, processAsSQL text: String) {
        delegate?.importView(self, showSQL: text)
    }

    func textImport(_ textVC: TextImportViewController, showImportFor CSV: [[String]]) {
        guard let item = tabView.selectedTabViewItem else {
            return
        }

        guard let importView = storyboard?.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("importDataView")) as? ImportDataViewController else {
            return
        }
        importView.delegate = self
        importView.data = CSV
        importView.title = textVC.title
        importView.representedObject = representedObject
        
        let index = tabView.indexOfTabViewItem(item)

        let newView = NSTabViewItem(viewController: importView)
        tabView.removeTabViewItem(at: index)
        tabView.insertTabViewItem(newView, at: index)
        tabControl.reloadData()
        tabControl.selectedItem = newView
    }
}

extension ImportViewController: ImportDataDelegate {
    func closeImportView(_ vc: ImportDataViewController) {
        guard let index = tabView.tabViewItems.index(where: { $0.viewController === vc}) else {
            return
        }

        tabView.removeTabViewItem(at: index)
        if tabView.numberOfTabViewItems > 0 {
            tabControl.reloadData()
            tabView.selectTabViewItem(at: 0)
            tabControl.selectedItem = tabView.tabViewItems[0]
        } else {
            hideContentView()
        }
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
    case sqlite
    case xlsx(Workbook)
    case text(String, String.Encoding)

    static func importType(for url: URL) -> ImportType {
        
        guard var data = try? Data(contentsOf: url, options: .mappedIfSafe) else {
            return .failed
        }
        
        do {
            _ = try JSONSerialization.jsonObject(with: data, options: [])
            return .json
        } catch {
            print("file's not JSON")
        }

        if let workbook = Workbook(path: url) {
            return .xlsx(workbook)
        }

        do {
            _ = try XMLDocument(contentsOf: url, options: [])
            return .xml
        } catch {
            print("Not XML")
        }

        let simpleString = data.withUnsafeMutableBytes { (ptr: UnsafeMutablePointer<UInt8>) -> ImportType? in
            let unsafePtr = UnsafeMutableRawPointer(ptr)
            if let str = String(bytesNoCopy: unsafePtr, length: data.count, encoding: .utf8, freeWhenDone: false) {
                return .text(str, .utf8)
            } else if let rom = String(bytesNoCopy: unsafePtr, length: data.count, encoding: .macOSRoman, freeWhenDone: false) {
                return .text(rom, .macOSRoman)
            }
            return nil
        }

        if let type = simpleString {
            return type
        } else {
            return .failed
        }
    }

}

extension Worksheet {
    func sqliteData() -> [[Any?]] {
        guard let flatData = self.flatData() else {
            return [[]]
        }

        var data = [[Any?]]()

        for row in flatData {
            var rowData = [Any?]()
            for expressible in row {
                if let value = expressible {
                    rowData.append(value)
                } else {
                    rowData.append(nil)
                }
            }
            data.append(rowData)
        }
        return data
    }
}
