//
//  ExportViewController+JSON.swift
//  Yield
//
//  Created by Carl Wieland on 5/3/17.
//  Copyright © 2017 Datum. All rights reserved.
//

import Cocoa

extension ExportViewController {

    func exportJSON() {
        let savePanel = NSSavePanel()

        savePanel.canCreateDirectories = true

        let response = savePanel.runModal()

        guard response == .OK, let url = savePanel.url else {
            return
        }

        performSegue(withIdentifier: NSStoryboardSegue.Identifier(rawValue: "showProgress"), sender: self)

        guard let progressViewController = self.progressViewController else {
            return
        }

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
                    self.dismissViewController(progressViewController)
                }
            }

            do {
                var root: [[String: Any]]?
                // if we are creating separate files per table, make the folder for them
                //
                if self.jsonOptions.separateFilePerTable {
                    try manager.createDirectory(at: url.deletingPathExtension(), withIntermediateDirectories: true, attributes: nil)
                }

                let count = self.tablesToExport.count

                for (index, table) in self.tablesToExport.enumerated() {
                    //create CSV File for this table
                    DispatchQueue.main.async {
                        progressViewController.setOperationText(to: String(format: NSLocalizedString("Exporting Table: %@", comment: "Create Table step %@ replaced with table name"), table.name))
                        progressViewController.updateProgress(to: Double(index) / Double(count))

                    }

                    let object = try table.exportJSON(with: self.jsonOptions)

                    if self.jsonOptions.separateFilePerTable {

                        let tableURL = url.deletingPathExtension().appendingPathComponent(table.name).appendingPathExtension("json")

                        let data = try JSONSerialization.data(withJSONObject: object, options: self.jsonOptions.prettyPrint ? .prettyPrinted : [])
                        try data.write(to: tableURL)

                    } else {
                        if root == nil {
                            root =  [[String: Any]]()
                        }
                        root?.append(object)
                    }
                }
                if let root = root {
                    let data = try JSONSerialization.data(withJSONObject: root, options: self.jsonOptions.prettyPrint ? .prettyPrinted : [])
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

        }

    }

}
