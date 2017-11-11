//
//  ExportViewController+csv.swift
//  Yield
//
//  Created by Carl Wieland on 4/27/17.
//  Copyright © 2017 Datum. All rights reserved.
//

import Cocoa

extension ExportViewController {

    func exportAsCSV() {
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

        progressViewController.setOperationText(to:String(format: NSLocalizedString("Exporting CSV", comment: "Export CSV Title")))


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

                var errorCount = 0

                try manager.createDirectory(at: url.deletingPathExtension(), withIntermediateDirectories: true, attributes: nil)
                let count = self.tablesToExport.count

                for (index, table) in self.tablesToExport.enumerated(){
                    //create CSV File for this table
                    DispatchQueue.main.async {
                        progressViewController.setOperationText(to:String(format: NSLocalizedString("Exporting Table: %@", comment: "Create Table step %@ replaced with table name"), table.name))
                        progressViewController.updateProgress(to: Double(index) / Double(count))

                    }

                    let tableURL = url.deletingPathExtension().appendingPathComponent(table.name).appendingPathExtension("csv")

                    guard manager.createFile(atPath: tableURL.path, contents: nil, attributes: nil) else {
                        throw NSError(domain: "com.datum.yield", code: 6, userInfo: [NSLocalizedDescriptionKey: NSLocalizedString("Failed to create file", comment: "Unable to create CSV file error")])
                    }

                    guard let handle = OutputStream(url: tableURL, append: false) else {
                        return
                    }
                    handle.open()
                    defer {
                        handle.close()
                    }

                    try table.exportCSV(with: handle, options: self.csvOptions)

                }


            } catch {
                print("Fail:\(error)")
                DispatchQueue.main.async {
                    let alert = NSAlert()
                    alert.messageText = NSLocalizedString("Error exporting data", comment: "Generic export error")
                    alert.informativeText = NSLocalizedString("Unable to save CSV File", comment: "CSV export error informative message")
                    
                    
                    alert.addButton(withTitle: "Ok")
                    alert.runModal()
                }
                
            }
            DispatchQueue.main.async {
                self.dismissViewController(progressViewController)
            }
        }
    }

}
