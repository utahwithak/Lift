//
//  Document.swift
//  Lift
//
//  Created by Carl Wieland on 9/28/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Cocoa

class LiftDocument: NSDocument {

    let database: Database

    override init() {
        database = try! Database(type: .inMemory(name: "main"))
        super.init()

    }

    override var isDocumentEdited: Bool {
        return false
    }
    
    override func canClose(withDelegate delegate: Any, shouldClose shouldCloseSelector: Selector?, contextInfo: UnsafeMutableRawPointer?) {
        var allowed = true

        let shouldClose = {
            guard let shouldCloseSelector = shouldCloseSelector else { return }
            let Class: AnyClass = Swift.type(of: delegate as AnyObject)
            let method = class_getMethodImplementation(Class, shouldCloseSelector)

            typealias signature = @convention(c) (Any, Selector, AnyObject, Bool, UnsafeMutableRawPointer?) -> Void
            let function = unsafeBitCast(method, to: signature.self)

            function(delegate, shouldCloseSelector, self, allowed, contextInfo)
        }

        if database.autocommitStatus == .inTransaction {
            let alert = NSAlert()
            alert.messageText = NSLocalizedString("Currently in transaction", comment: "Alert title when attempting to close while in transaction")
            alert.informativeText = NSLocalizedString("The database is currently in a transaction. Closing now could result in loss of data. Would you like to attempt to commit these changes?", comment: "Alert message when attempting to close while in transaction")
            alert.addButton(withTitle: NSLocalizedString("Commit", comment: "option to commit when closing"))
            alert.addButton(withTitle: NSLocalizedString("Close without committing", comment:" option to close document with out commiting"))
            alert.addButton(withTitle: NSLocalizedString("Cancel", comment:"cancel button when closing"))

            let handler: (NSApplication.ModalResponse) -> Void = { response in
                if response == NSApplication.ModalResponse.alertFirstButtonReturn {
                    do {
                        try self.database.endTransaction()
                        allowed = true
                    } catch {
                        self.presentError(error)
                        allowed = false
                    }

                } else if response == NSApplication.ModalResponse.alertSecondButtonReturn {
                    allowed = true
                } else if response == NSApplication.ModalResponse.alertThirdButtonReturn {
                    allowed = false
                }
                shouldClose()

            }
            if let window = windowControllers.first?.window {
                alert.beginSheetModal(for: window, completionHandler:handler)
            } else {
                let response = alert.runModal()
                handler(response)
            }
        } else {
            shouldClose()
        }


    }
    init(contentsOf url: URL, ofType typeName: String) throws {
        SQLiteDocumentPresenter.addPresenters(for: url)

        database = try Database(type: .disk(path: url, name: "main"))

        super.init()
        fileURL = url
        displayName = url.lastPathComponent

    }

    public convenience init(for urlOrNil: URL?, withContentsOf contentsURL: URL, ofType typeName: String) throws {
        try self.init(contentsOf: contentsURL, ofType: typeName)
    }

    override func makeWindowControllers() {
        // Returns the Storyboard that contains your Document window.
        let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
        let windowController = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("Document Window Controller")) as! NSWindowController
        self.addWindowController(windowController)
    }

    override func save(to url: URL, ofType typeName: String, for saveOperation: NSDocument.SaveOperationType, completionHandler: @escaping (Error?) -> Void) {

        completionHandler(nil)

    }

    func keywords() -> Set<String> {
        var keywords = Set<String>()

        for database in database.allDatabases {
            keywords.insert(database.name)
            for table in database.tables {
                keywords.insert(table.name)
                keywords.formUnion(table.columns.map({ $0.name }))
            }
        }

        return keywords
    }

    func refresh() {
        database.refresh()
    }

    func cleanDatabase() throws {
        try database.cleanDatabase()
    }

    func checkDatabaseIntegrity() throws -> Bool {
        return try database.checkDatabaseIntegrity()
    }

    func checkForeignKeys() throws -> Bool {
        return try database.checkForeignKeyIntegrity()
    }

}

