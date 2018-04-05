//
//  ImportExportWindowController.swift
//  Lift
//
//  Created by Carl Wieland on 10/24/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Cocoa

class ExportViewController: LiftViewController {
    enum ExportType: Int {
        case CSV
        case JSON
        case XML
        case XLSX
        case dump
        case SQLite
    }

    override var representedObject: Any? {
        didSet {
            if let document = document {
                exportTrees = document.database.allDatabases.map { ExportDatabaseNode(database: $0) }
            }
        }
    }

    @objc dynamic var exportTrees = [ExportDatabaseNode]()

    var tablesToExport: [ExportTableNode] {
        return exportTrees.flatMap { ($0.children as! [ExportTableNode]).filter({ $0.export }) }
    }

    @IBOutlet var treeController: NSTreeController!

    @IBOutlet weak var outlineView: NSOutlineView!
    @IBOutlet weak var carriageRadioButton: NSButton!
    @IBOutlet weak var newLineRadioButton: NSButton!

    @objc dynamic var exportTypeSelection: NSNumber = 0

    @objc dynamic let csvOptions = CSVExportOptions()
    @objc dynamic let sqliteOptions = SQLiteExportOptions()
    @objc dynamic let xlsxOptions = XLSXExportOptions()
    @objc dynamic let xmlOptions = XMLExportOptions()
    @objc dynamic let jsonOptions = JSONExportOptions()

    private(set) weak var progressViewController: ProgressViewController?

    var exportType: ExportType {
        return ExportType(rawValue: exportTypeSelection.intValue)!
    }

    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        progressViewController = segue.destinationController as? ProgressViewController
    }

    @IBAction func export(_ sender: Any) {

        switch exportType {
        case .CSV:
            exportAsCSV()
        case .dump:
            exportAsDumpFile()
        case .SQLite:
            exportAsDatabase()
        case .XLSX:
            exportXLSX()
        case .XML:
            exportXML()
        case .JSON:
            exportJSON()
        }
        dismiss(nil)
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
    override func viewDidLoad() {
        super.viewDidLoad()

    }
}
