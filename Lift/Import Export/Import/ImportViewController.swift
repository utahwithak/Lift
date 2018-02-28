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
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        if importPath != nil, let waitingVC = storyboard?.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("progressViewController")) as? ProgressViewController {

            waitingVC.operation = NSLocalizedString("Preparing for import...", comment: "Loading file file for import waiting label text")
            waitingVC.indeterminant = true
            presentViewControllerAsSheet(waitingVC)

            DispatchQueue.global(qos: .userInitiated).async {
                self.refreshContent()

                DispatchQueue.main.async {
                    self.dismissViewController(waitingVC)
                }
            }
        }
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

        DispatchQueue.main.async {
            if self.tabView.numberOfTabViewItems == 0 {
                self.hideContentView()
            } else {
                self.showContentView()
            }
        }
    }

    func checkForImport(from file: URL) {

        let importType = ImportType.importType(for: file)

        DispatchQueue.main.async {
            switch importType {
            case .text(let text, let encoding):

                guard let vc = self.storyboard?.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("textInitialViewController")) as? TextImportViewController else {
                    return
                }
                vc.encoding = encoding
                vc.delegate = self
                vc.text = text as NSString
                vc.title = file.lastPathComponent
                self.tabView.addTabViewItem(NSTabViewItem(viewController: vc))
            case .xlsx(let workbook):

                for sheet in workbook.sheets {

                    guard let importView = self.storyboard?.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("importDataView")) as? ImportDataViewController else {
                        return
                    }
                    importView.delegate = self

                    importView.data = sheet.sqliteData()
                    importView.title = sheet.name
                    importView.representedObject = self.representedObject

                    let newView = NSTabViewItem(viewController: importView)
                    self.tabView.addTabViewItem(newView)
                }
            case .xml(let document):
                do {
                    let tables = try self.parseXML(document: document)
                    for table in tables {

                        guard let importView = self.storyboard?.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("importDataView")) as? ImportDataViewController else {
                            return
                        }
                        importView.delegate = self

                        importView.data = table.data
                        importView.title = table.proprties.name
                        importView.representedObject = self.representedObject

                        let newView = NSTabViewItem(viewController: importView)
                        self.tabView.addTabViewItem(newView)
                    }
                } catch {
                    self.presentError(error)
                }
            default:
                print("type:\(importType)")
            }
        }
    }

    struct ImportTableInformation {
        let proprties: TableProperties
        let data: [[Any?]]
    }

    struct TableProperties {
        var name: String
        var columns = [(String, String)]()
        var fullSQL: String?
        init(name: String) {
            self.name = name
        }
    }

    private func parseXML(document: XMLDocument) throws -> [ImportTableInformation] {

        guard let tables = document.rootElement()?.elements(forName: "table"), !tables.isEmpty else {
            throw LiftError.invalidImportXML("Missing table elements, <root> <table></table> <root>")
        }

        var importInfos = [ImportTableInformation]()
        for (index, tableElement) in tables.enumerated() {
            var props = TableProperties(name: String(format: NSLocalizedString("Table %i", comment: "unknown table import name %@ replaced with what number it is"), index + 1))

            if let originalName = tableElement.attribute(forName: "name")?.stringValue {
                props.name = originalName
            }

            if let properties = tableElement.child(named: "properities") {
                props.name = properties.child(named: "tableName")?.stringValue ?? props.name
                props.fullSQL = properties.child(named: "sql")?.stringValue

                if let columns = properties.child(named: "columns")?.elements(forName: "column") {
                    for (colIndex, columnElement) in columns.enumerated() {
                        let columnName = columnElement.child(named: "name")?.stringValue ?? "Column \(colIndex + 1)"
                        let type = columnElement.child(named: "type")?.stringValue ?? ""
                        props.columns.append((columnName, type))
                    }
                }

            }
            guard let rows = tableElement.child(named: "data")?.elements(forName: "row") else {
                throw LiftError.invalidImportXML("Missing <data> section containing rows")
            }

            var tableData = [[Any?]]()
            for rowElement in rows {
                var rowData = [Any?]()
                guard let values = rowElement.children as? [XMLElement] else {
                    continue
                }
                for value in values {
                    guard let name = value.name else {
                        rowData.append(value.stringValue)
                        continue
                    }
                    switch name.lowercased() {
                    case "null":
                        rowData.append(nil)
                    case "integer":
                        if let strVal = value.stringValue {
                            if let intVal = Int(strVal) {
                                rowData.append(intVal)
                            } else {
                                rowData.append(strVal)
                            }
                        } else {
                            rowData.append(nil)
                        }
                    case "double":
                        if let strVal = value.stringValue {
                            if let doubVal = Double(strVal) {
                                rowData.append(doubVal)
                            } else {
                                rowData.append(strVal)
                            }
                        } else {
                            rowData.append(nil)
                        }
                    case "text":
                        rowData.append(value.stringValue)
                    case "blob":
                        // will be converted higher up
                        rowData.append(value.stringValue)
                    default:
                        rowData.append(value.stringValue)
                    }
                }

                tableData.append(rowData)
            }


            let tableInfo = ImportTableInformation(proprties: props, data: tableData)

            importInfos.append(tableInfo)
        }

        return importInfos
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


extension Sheet {
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

extension XMLElement {
    func child(named name: String) -> XMLElement? {
        return children?.first(where: { $0.name == name}) as? XMLElement
    }
}

