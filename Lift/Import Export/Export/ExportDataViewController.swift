//
//  ExportDataViewController.swift
//  Lift
//
//  Created by Carl Wieland on 9/28/18.
//  Copyright © 2018 Datum Apps. All rights reserved.
//

import AppKit
import SwiftXLSX

class ExportDataViewController: LiftViewController {

    enum DataExportType: Int {
        case csv
        case json
        case xml
        case xlsx
    }

    public var data: [[SQLiteData]]!
    public var columns: [String]!
    @IBOutlet weak var carriageRadioButton: NSButton!
    @IBOutlet weak var newLineRadioButton: NSButton!

    @objc dynamic var exportTypeSelection: NSNumber = 0

    @objc dynamic let csvOptions = CSVExportOptions()
    @objc dynamic let sqliteOptions = SQLiteExportOptions()
    @objc dynamic let xlsxOptions = XLSXExportOptions()
    @objc dynamic let xmlOptions = XMLExportOptions()
    @objc dynamic let jsonOptions = JSONExportOptions()

    private(set) weak var progressViewController: ProgressViewController?

    var exportType: DataExportType {
        return DataExportType(rawValue: exportTypeSelection.intValue)!
    }

    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        progressViewController = segue.destinationController as? ProgressViewController
    }

    @IBAction func toggleCSVLineEndings(_ sender: NSButton) {
        if carriageRadioButton.state == .on {
            csvOptions.lineEnding = "\r"
        } else if newLineRadioButton.state == .on {
            csvOptions.lineEnding = "\n"
        }
    }

    @IBAction func toggleXLSXBlobOptions(_ sender: NSButton) {
        xlsxOptions.exportRawBlobData = sender.tag == 0
    }

    var totalCount: Double {
        return Double(self.data.count)
    }

    @IBAction func export(_ sender: Any) {

        switch exportType {
        case .csv:
            exportAsCSV()
        case .xlsx:
            exportXLSX()
        case .xml:
            exportXML()
        case .json:
            exportJSON()
        }
        dismiss(nil)
    }

    func exportAsCSV() {
        let savePanel = NSSavePanel()
        savePanel.canCreateDirectories = true
        let response = savePanel.runModal()

        guard response == .OK, let url = savePanel.url else {
            return
        }
        performSegue(withIdentifier: "showProgress", sender: self)
        guard let progressViewController = self.progressViewController else {
            return
        }
        progressViewController.setOperationText(to: String(format: NSLocalizedString("Exporting CSV", comment: "Export CSV Title")))
        let manager = FileManager.default

        if manager.fileExists(atPath: url.path) {
            do {
                try manager.trashItem(at: url, resultingItemURL: nil)
            } catch {
                self.presentError(error)
                return
            }
        }

        DispatchQueue.global(qos: .userInitiated).async {
            do {

                DispatchQueue.main.async {
                    progressViewController.setOperationText(to: String(format: NSLocalizedString("Exporting Data", comment: "Create Table step %@ replaced with table name")))
                }

                let tableURL = url

                guard manager.createFile(atPath: tableURL.path, contents: nil, attributes: nil) else {
                    throw LiftError.unableToCreateFile
                }

                let handle = try FileHandle(forWritingTo: tableURL)

                handle.open()
                defer {
                    handle.closeFile()
                }
                let writer = handle
                let options = self.csvOptions

                if options.includeColumnNames {
                    //write out the included column names
                    let names = self.columns.map({ $0.name.CSVFormattedString(qouted: options.shouldQuoteFields, separator: options.separator) })
                    let header = names.joined(separator: options.separator)
                    writer.write("\(header)\(options.lineEnding)")
                }
                let separator = options.separator
                let lineEnding = options.lineEnding
                let blobPlaceholder = options.blobDataPlaceHolder.CSVFormattedString(qouted: options.shouldQuoteFields, separator: options.separator)
                let total = self.totalCount
                var current = 0.0
                for row in self.data {
                    for (index, data) in row.enumerated() {
                        switch data {
                        case .text(let text):
                            writer.write(text.CSVFormattedString(qouted: options.shouldQuoteFields, separator: options.separator))
                        case .integer(let intVal):
                            writer.write(intVal.description)
                        case .float(let dVal):
                            writer.write(dVal.description)
                        case .null:
                            writer.write(options.nullPlaceHolder)
                        case .blob(let data):
                            if options.exportRawBlobData {
                                writer.write("<\(data.hexEncodedString())>")
                            } else {
                                writer.write(blobPlaceholder)
                            }

                        }
                        if index < row.count - 1 {
                            writer.write(separator)
                        } else {
                            writer.write(lineEnding)
                        }
                    }
                    current += 1
                    DispatchQueue.main.async {
                        progressViewController.updateProgress(to: current / total)
                    }
                }

            } catch {
                print("Fail:\(error)")
                DispatchQueue.main.async {
                    let alert = NSAlert()
                    alert.messageText = NSLocalizedString("Error exporting data", comment: "Generic export error")
                    alert.informativeText = NSLocalizedString("Unable to save CSV File, failed with error:\n\(error.localizedDescription)", comment: "CSV export error informative message")

                    alert.addButton(withTitle: "Ok")
                    alert.runModal()
                }
            }
            DispatchQueue.main.async {
                self.dismiss(progressViewController)
            }
        }
    }

    func exportXLSX() {

        let savePanel = NSSavePanel()

        savePanel.canCreateDirectories = true
        savePanel.allowedFileTypes = ["xlsx"]
        savePanel.allowsOtherFileTypes = false

        let response = savePanel.runModal()

        guard response == .OK, let url = savePanel.url else {
            return
        }
        performSegue(withIdentifier: "showProgress", sender: self)

        guard let progressViewController = self.progressViewController else {
            return
        }
        progressViewController.indeterminant = false
        progressViewController.setOperationText(to: String(format: NSLocalizedString("Exporting XLSX", comment: "Export XLSX Title")))

        let manager = FileManager.default

        if manager.fileExists(atPath: url.path) {
            do {
                try manager.trashItem(at: url, resultingItemURL: nil)
            } catch {
                self.presentError(error)
                return
            }
        }

        DispatchQueue.global(qos: .userInitiated).async {

            defer {
                DispatchQueue.main.async {
                    self.dismiss(progressViewController)
                }
            }

            let excelDoc = XLSXDocument()

            DispatchQueue.main.async {
                progressViewController.setOperationText(to: String(format: NSLocalizedString("Generating Worksheet from data", comment: "Create worksheet data")))
            }

            let workSheet = excelDoc.addSheet(named: "data")
            let options = self.xlsxOptions
            if options.includeColumnNames {
                let row = workSheet.addRow()
                let rowValues: [XLSXExpressible] = self.columns.map({ return $0.name})
                row.setColumnData(rowValues)
            }
            let total = self.totalCount
            var current = 0.0
            for row in self.data {
                let nextRow = workSheet.addRow()

                let xlsValues = row.map({ (data) -> XLSXExpressible? in
                    switch data {
                    case .integer(let intVal):
                        return intVal
                    case .float(let double):
                        return double
                    case .text(let strVal):
                        return strVal
                    case .null:

                        guard options.exportNULLValues else {
                            return nil
                        }

                        if !options.nullPlaceHolder.isEmpty {
                            return options.nullPlaceHolder
                        } else {
                            return ""
                        }

                    case .blob(let data):

                        guard options.exportBlobData else {
                            return nil
                        }

                        if options.exportRawBlobData {
                            return data.hexEncodedString()
                        } else {
                            return options.blobDataPlaceHolder
                        }
                    }

                })
                current += 1
                DispatchQueue.main.async {
                    progressViewController.updateProgress(to: current / total)
                }
                nextRow.setColumnData(xlsValues)
            }

            DispatchQueue.main.async {
                progressViewController.setOperationText(to: String(format: NSLocalizedString("Saving %@", comment: "Saving xlsx file %@ replaced with file name"), url.lastPathComponent))
                progressViewController.updateProgress(to: 1)
                progressViewController.indeterminant = true

            }
            do {
                try excelDoc.save(to: url)
            } catch {
                DispatchQueue.main.async {
                    self.presentError(error)
                }

                print("Failed to save XLSX File:\(error)")
            }

        }
    }

    public static func defaultXMLDocument() -> XMLDocument {
        let doc = XMLDocument()
        doc.version = "1.0"
        doc.characterEncoding = "UTF-8"
        doc.isStandalone = true
        return doc
    }

    func exportXML() {
        let savePanel = NSSavePanel()

        savePanel.canCreateDirectories = true

        let response = savePanel.runModal()

        guard response == .OK, let url = savePanel.url else {
            return
        }

        performSegue(withIdentifier: "showProgress", sender: self)

        guard let progressViewController = self.progressViewController else {
            return
        }

        progressViewController.setOperationText(to: String(format: NSLocalizedString("Exporting XML", comment: "Export XML Title")))

        let manager = FileManager.default

        if manager.fileExists(atPath: url.path) {
            do {
                try manager.trashItem(at: url, resultingItemURL: nil)
            } catch {
                self.presentError(error)
                return
            }
        }

        DispatchQueue.global(qos: .userInitiated).async {

            do {

                var rootElement: XMLElement?

                // if we are creating separate files per table, make the folder for them
                //
                if self.xmlOptions.separateFilePerTable {
                    try manager.createDirectory(at: url.deletingPathExtension(), withIntermediateDirectories: true, attributes: nil)
                }

                let options = self.xmlOptions
                DispatchQueue.main.async {
                    progressViewController.setOperationText(to: String(format: NSLocalizedString("Exporting Data", comment: "exporting data operation text")))
                }

                let dataElement = XMLElement(name: options.dataSectionName)
                let total = Double(self.data.count)
                var current = 0.0
                for row in self.data {

                    let rowElement = XMLElement(name: options.rowName)

                    for data in row {
                        let element: XMLElement
                        switch data {
                        case .null:
                            element = XMLElement(name: "null", stringValue: options.nullPlaceHolder)
                        case .integer(let val):
                            element = XMLElement(name: "integer", stringValue: "\(val)")
                        case .float(let doub):
                            element = XMLElement(name: "double", stringValue: "\(doub)")
                        case .text(let str):
                            element = XMLElement(name: "text", stringValue: str)
                        case .blob(let data):
                            element = XMLElement(name: "blob", stringValue: options.exportRawBlobData ? data.hexEncodedString() : options.blobDataPlaceHolder)
                        }

                        rowElement.addChild(element)
                    }
                    current += 1
                    DispatchQueue.main.async {
                        progressViewController.updateProgress(to: current / total)
                    }
                    dataElement.addChild(rowElement)
                }
                rootElement = dataElement
                if let root = rootElement {
                    let databaseDoc = ExportViewController.defaultXMLDocument()
                    databaseDoc.addChild(root)
                    let data = databaseDoc.xmlData(options: options.exportOptions)
                    try data.write(to: url)
                }

            } catch {
                print("Fail:\(error)")
                DispatchQueue.main.async {
                    let alert = NSAlert()
                    alert.messageText = NSLocalizedString("Error exporting data", comment: "Generic export error")
                    alert.informativeText = NSLocalizedString("Unable to save XML File", comment: "CSV export error informative message")

                    alert.addButton(withTitle: "Ok")
                    alert.runModal()
                }

            }
            DispatchQueue.main.async {
                self.dismiss(progressViewController)
            }
        }

    }

    func exportJSON() {
        let savePanel = NSSavePanel()
        savePanel.canCreateDirectories = true
        guard savePanel.runModal() == .OK, let url = savePanel.url else {
            return
        }
        performSegue(withIdentifier: "showProgress", sender: self)

        guard let progressViewController = self.progressViewController else { return }
        progressViewController.setOperationText(to: String(format: NSLocalizedString("Exporting JSON", comment: "Export JSON Title")))

        let manager = FileManager.default
        if manager.fileExists(atPath: url.path) {
            do {
                try manager.trashItem(at: url, resultingItemURL: nil)
            } catch {
                self.presentError(error)
                return
            }
        }
        DispatchQueue.global(qos: .userInitiated).async {
            defer {
                DispatchQueue.main.async {
                    self.dismiss(progressViewController)
                }
            }

            do {
                var root = [[String: Any]]()

                DispatchQueue.main.async {
                    progressViewController.setOperationText(to: String(format: NSLocalizedString("Exporting Data", comment: "export data operation")))
                }

                let options = self.jsonOptions
                var tableData = [String: Any]()

                let names = self.columns ?? []
                var rows = [Any]()
                let total = Double(self.data.count)
                var current = 0.0
                for row in self.data {

                    var arrayElements = [Any?]()
                    var dictElements = [String: Any?]()

                    for (i, name) in names.enumerated() {

                        let data = row[i]

                        switch data {
                        case .null:
                            if options.useNullLiterals {
                                arrayElements.append(nil)
                                dictElements[name] = nil
                            } else {
                                arrayElements.append( options.nullPlaceHolder)
                                dictElements[name] = options.nullPlaceHolder
                            }

                        case .integer(let val):
                            arrayElements.append(val)
                            dictElements[name] = val
                        case .float(let val):
                            arrayElements.append(val)
                            dictElements[name] = val
                        case .text(let str):
                            arrayElements.append(str)
                            dictElements[name] = str
                        case .blob(let data):
                            let value: String = {
                                if options.exportRawBlobData {
                                    return data.hexEncodedString()
                                } else {
                                    return options.blobDataPlaceHolder
                                }
                            }()
                            arrayElements.append(value)
                            dictElements[name] = value
                        }

                    }
                    current += 1
                    DispatchQueue.main.async {
                        progressViewController.updateProgress(to: current / total)
                    }

                    if options.rowsAsDictionaries {
                        rows.append(dictElements)
                    } else {
                        rows.append(arrayElements)
                    }
                }
                tableData[options.rowName] = rows
                root.append(tableData)

                let data = try JSONSerialization.data(withJSONObject: root, options: self.jsonOptions.prettyPrint ? .prettyPrinted : [])
                try data.write(to: url)

            } catch {
                print("Fail:\(error)")
                DispatchQueue.main.async {
                    let alert = NSAlert()
                    alert.messageText = NSLocalizedString("Error exporting data", comment: "Generic export error")
                    alert.informativeText = NSLocalizedString("Unable to save JSON File", comment: "CSV export error informative message")

                    alert.addButton(withTitle: "Ok")
                    alert.runModal()
                }
            }
        }
    }

}
