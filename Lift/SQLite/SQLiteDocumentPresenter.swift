//
//  SQLiteDocumentPresenter.swift
//  Yield
//
//  Created by Carl Wieland on 4/10/17.
//  Copyright © 2017 Datum. All rights reserved.
//

import Foundation

class SQLiteDocumentPresenter: NSObject, NSFilePresenter {

    static let presentedItemOperationQueue = OperationQueue()

    static func addPresenters(for databaseURL: URL) {

        let p1 = SQLiteDocumentPresenter(for: databaseURL, prefix: nil, suffix: "-wal")
        NSFileCoordinator.addFilePresenter(p1)
        let p2 = SQLiteDocumentPresenter(for: databaseURL, prefix: nil, suffix: "-shm")
        NSFileCoordinator.addFilePresenter(p2)
        let p3 = SQLiteDocumentPresenter(for: databaseURL, prefix: nil, suffix: "-journal")
        NSFileCoordinator.addFilePresenter(p3)
        let p4 = SQLiteDocumentPresenter(for: databaseURL, prefix: ".", suffix: "-conch")
        NSFileCoordinator.addFilePresenter(p4)

        // +filePresenters will only return once the asynchronously added file presenters are done being registered

        _ = NSFileCoordinator.filePresenters
    }

    let primaryPresentedItemURL: URL?
    let presentedItemURL: URL?

    init(for fileURL: URL, prefix: String?, suffix: String?) {

        primaryPresentedItemURL = fileURL
        var path = fileURL.path
        if let prefix = prefix {
            let name = fileURL.lastPathComponent
            let dir = fileURL.deletingLastPathComponent()
            path = dir.appendingPathComponent("\(prefix)\(name)").path
        }
        if let suffix = suffix {
            path +=  suffix
        }
        presentedItemURL = URL(fileURLWithPath: path)

        super.init()
    }

    var presentedItemOperationQueue: OperationQueue {
        return SQLiteDocumentPresenter.presentedItemOperationQueue
    }

}
