//
//  ExportViewController+xlsx.swift
//  Yield
//
//  Created by Carl Wieland on 4/27/17.
//  Copyright © 2017 Datum. All rights reserved.
//

import Cocoa
import SwiftXLSX

extension ExportViewController {
    func exportXLSX() {

        let savePanel = NSSavePanel()

        savePanel.canCreateDirectories = true
        savePanel.allowedFileTypes = ["xlsx"]
        savePanel.allowsOtherFileTypes = false

        let response = savePanel.runModal()

        guard response == .OK, let url = savePanel.url else {
            return
        }
        performSegue(withIdentifier: NSStoryboardSegue.Identifier(rawValue: "showProgress"), sender: self)


        guard let progressViewController = self.progressViewController else {
            return
        }

        progressViewController.setOperationText(to:String(format: NSLocalizedString("Exporting XLSX", comment: "Export XLSX Title")))


        let manager = FileManager.default

        if manager.fileExists(atPath: url.path) {
            do {
                try manager.trashItem(at: url, resultingItemURL: nil)
            } catch {
                self.presentError(error)
                return
            }
        }

        let tablesToExport = self.tablesToExport

        DispatchQueue.global(qos: .userInitiated).async {

            defer {
                DispatchQueue.main.async {
                    self.dismissViewController(progressViewController)
                }
            }

            let excelDoc = XLSXDocument()

            let count = tablesToExport.count
            for (index, table) in tablesToExport.enumerated() {
                //create CSV File for this table
                DispatchQueue.main.async {
                    progressViewController.setOperationText(to:String(format: NSLocalizedString("Generating Worksheet for Table: %@", comment: "Create worksheet step %@ replaced with table name"), table.name))
                    progressViewController.updateProgress(to: Double(index) / Double(count))
                    
                }

                let workSheet = excelDoc.addSheet(named: table.name)
                do {
                    try table.export(to: workSheet, with: self.xlsOptions)
                } catch {
                    DispatchQueue.main.async {
                        self.presentError(error)
                    }

                    print("Failed to export:\(table.name)")
                }

            }
            DispatchQueue.main.async {
                progressViewController.setOperationText(to:String(format: NSLocalizedString("Saving %@", comment: "Saving xlsx file %@ replaced with file name"), url.lastPathComponent))
                progressViewController.updateProgress(to: 1)

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
}
