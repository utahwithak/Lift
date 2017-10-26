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

    override class var autosavesInPlace: Bool {
        return true
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


    func refresh() {
        database.refresh()
    }

}

