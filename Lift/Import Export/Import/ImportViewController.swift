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

    @objc dynamic var hasImports = false

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
        if importPath != nil, let waitingVC = storyboard?.instantiateController(withIdentifier: "progressViewController") as? ProgressViewController {

            waitingVC.operation = NSLocalizedString("Preparing for import...", comment: "Loading file file for import waiting label text")
            waitingVC.indeterminant = true
            presentAsSheet(waitingVC)

            DispatchQueue.global(qos: .userInitiated).async {
                self.refreshContent()

                DispatchQueue.main.async {
                    self.dismiss(waitingVC)
                }
            }
        }
    }

    private func hideContentView() {
        tabControl.isHidden = true
        tabView.isHidden = true
        tabViewHeightConstraint.constant = 0
        tabControlHeightConstraint.constant = 0
        self.hasImports = false

    }

    private func showContentView() {
        tabControl.animator().isHidden = false
        tabView.animator().isHidden = false
        tabViewHeightConstraint.constant = 150
        tabControlHeightConstraint.constant = 28
        self.hasImports = true

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
            if let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: nil) {
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

                guard let vc = self.storyboard?.instantiateController(withIdentifier: "textInitialViewController") as? TextImportViewController else {
                    return
                }
                vc.encoding = encoding
                vc.delegate = self
                vc.text = text as NSString
                vc.title = file.lastPathComponent
                self.tabView.addTabViewItem(NSTabViewItem(viewController: vc))
            case .xlsx(let workbook):

                for sheet in workbook.sheets {

                    guard let importView = self.storyboard?.instantiateController(withIdentifier: "importDataView") as? ImportDataViewController else {
                        return
                    }
                    importView.delegate = self

                    importView.data = sheet.sqliteData()
                    importView.title = sheet.name
                    importView.representedObject = self.representedObject

                    let newView = NSTabViewItem(viewController: importView)
                    self.tabView.addTabViewItem(newView)
                    self.showContentView()

                }
            case .xml(let document):
                do {
                    let tables = try self.parseXML(document: document)
                    for table in tables {

                        guard let importView = self.storyboard?.instantiateController(withIdentifier: "importDataView") as? ImportDataViewController else {
                            return
                        }
                        importView.delegate = self
                        importView.parsedColumns = table.properties.columns
                        importView.data = table.data
                        importView.title = table.properties.name
                        importView.representedObject = self.representedObject

                        let newView = NSTabViewItem(viewController: importView)
                        self.tabView.addTabViewItem(newView)
                        self.showContentView()

                    }
                } catch {
                    self.presentError(error)
                }
            case .json(let jsonData):
                do {
                    let tables = try self.parseJSON(data: jsonData)
                    for table in tables {

                        guard let importView = self.storyboard?.instantiateController(withIdentifier: "importDataView") as? ImportDataViewController else {
                            return
                        }
                        importView.delegate = self
                        importView.parsedColumns = table.properties.columns
                        importView.data = table.data
                        importView.title = table.properties.name
                        importView.representedObject = self.representedObject

                        let newView = NSTabViewItem(viewController: importView)
                        self.tabView.addTabViewItem(newView)
                        self.showContentView()
                    }
                } catch {
                    self.presentError(error)
                }
            case .sqlite(let otherDB):
                do {
                    for table in otherDB.tables {
                        let query = try table.exportQuery(for: table.columns)
                        query.loadInBackground(completion: { result in
                            switch result {
                            case .success(let data):
                                if data.isEmpty {
                                    return
                                }
                                guard let importView = self.storyboard?.instantiateController(withIdentifier: "importDataView") as? ImportDataViewController else {
                                    return
                                }
                                importView.delegate = self
                                importView.parsedColumns = table.columns.map { ImportViewController.TableProperties.Column(name: $0.name, type: $0.type)}
                                importView.data = data.map({ $0.map({ $0.toAny })})
                                importView.title = table.name
                                importView.representedObject = self.representedObject
                                let newView = NSTabViewItem(viewController: importView)
                                self.tabView.addTabViewItem(newView)
                                self.showContentView()

                            case .failure(let error):
                                print("Failed to query table:\(error)")
                            }
                        })
                    }
                } catch {
                    self.presentError(error)
                }
                print("database")
            case .failed:
                let alert = NSAlert()
                alert.informativeText = NSLocalizedString("Unable to parse the import file", comment: "Alert message when import failes")
                alert.messageText = NSLocalizedString("Failed to Import", comment: "Alert title when parsing fails")
                alert.runModal()
            }
        }
    }

    struct ImportTableInformation {
        let properties: TableProperties
        let data: [[Any?]]
    }

    struct TableProperties {
        var name: String
        var columns = [Column]()
        var fullSQL: String?
        init(name: String) {
            self.name = name
        }
        struct Column {
            let name: String
            let type: String
        }
    }

    private func parseXML(document: XMLDocument) throws -> [ImportTableInformation] {
        let tables: [XMLElement]
        if let rootElement = document.rootElement(), rootElement.name == "table" {
            tables = [rootElement]
        } else if let childTables = document.rootElement()?.elements(forName: "table") {
            tables = childTables
        } else {
            tables = []
        }

        guard !tables.isEmpty else {
            throw LiftError.invalidImportXML("Missing table elements, ")
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
                        props.columns.append(TableProperties.Column(name: columnName, type: type))
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

            let tableInfo = ImportTableInformation(properties: props, data: tableData)

            importInfos.append(tableInfo)
        }

        return importInfos
    }

    private func parseTable(data jsonData: [String: Any]) -> ImportTableInformation {
        var properties = TableProperties(name: "Unknown Table")
        var order = [String]()
        if let tableProperty = jsonData["properties"] as? [String: Any] {
            if let name = tableProperty["name"] as? String {
                properties.name = name
            }
            if let columns = tableProperty["columns"] as? [[String: String]] {
                for columnInfo in columns {
                    if let name = columnInfo["name"] {
                        properties.columns.append(TableProperties.Column(name: name, type: columnInfo["type"] ?? ""))
                        order.append(name)
                    }
                }
            }
        }
        var allRowData = [[Any?]]()
        if let data = jsonData["data"] as? [Any] {
            for row in data {
                switch row {
                case let dictionary as [String: Any]:
                    if order.isEmpty {
                        order = dictionary.keys.sorted()
                    }
                    var rowArray = [Any?]()
                    for column in order {
                        rowArray.append(dictionary[column])
                    }
                    allRowData.append(rowArray)
                case let arrayData as [Any?]:
                    allRowData.append(arrayData)
                default:
                    allRowData.append([])
                }
            }
        }
        return ImportTableInformation(properties: properties, data: allRowData)
    }

    private func parseJSON(data: Any) throws -> [ImportTableInformation] {
        if let tableData = data as? [String: Any] {
            return [parseTable(data: tableData)]
        } else if let arrayOfTables = data as? [[String: Any]] {
            return arrayOfTables.map { parseTable(data: $0)}
        } else {
            throw LiftError.invalidImportJSON(NSLocalizedString("Isn't a dictionary, or an array of dictionaries.", comment: "Invalid json error"))
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

        guard let importView = storyboard?.instantiateController(withIdentifier: "importDataView") as? ImportDataViewController else {
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
        return false
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
