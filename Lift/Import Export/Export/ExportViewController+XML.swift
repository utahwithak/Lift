//
//  ExportViewController+XML.swift
//  Yield
//
//  Created by Carl Wieland on 5/1/17.
//  Copyright © 2017 Datum. All rights reserved.
//

import Cocoa

extension ExportViewController {

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

        performSegue(withIdentifier: NSStoryboardSegue.Identifier(rawValue: "showProgress"), sender: self)


        guard let progressViewController = self.progressViewController else {
            return
        }

        progressViewController.setOperationText(to:String(format: NSLocalizedString("Exporting XML", comment: "Export XML Title")))


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

                let count = self.tablesToExport.count

                let options = self.xmlOptions.exportOptions

                for (index, table) in self.tablesToExport.enumerated(){
                    //create CSV File for this table
                    DispatchQueue.main.async {
                        progressViewController.setOperationText(to:String(format: NSLocalizedString("Exporting Table: %@", comment: "Create Table step %@ replaced with table name"), table.name))
                        progressViewController.updateProgress(to: Double(index) / Double(count))

                    }

                    // Create the XML Element
                    let tableElement = try table.exportXML(with: self.xmlOptions)


                    if self.xmlOptions.separateFilePerTable {

                        let tableURL = url.deletingPathExtension().appendingPathComponent(table.name).appendingPathExtension("xml")
                        let tableDoc = ExportViewController.defaultXMLDocument()
                        tableDoc.addChild(tableElement)

                        let data = tableDoc.xmlData(options: options)
                        try data.write(to: tableURL)

                    } else {
                        if rootElement == nil {
                            rootElement = XMLElement()
                            rootElement!.name = self.xmlOptions.rootNodeName
                        }
                        rootElement?.addChild(tableElement)
                    }


                }
                if let root = rootElement {
                    let databaseDoc = ExportViewController.defaultXMLDocument()
                    databaseDoc.addChild(root)
                    let data = databaseDoc.xmlData(options: options)
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
                self.dismissViewController(progressViewController)
            }
        }

    }

    
}
