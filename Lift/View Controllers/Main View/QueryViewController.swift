//
//  QueryViewController.swift
//  Lift
//
//  Created by Carl Wieland on 10/25/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Cocoa

class QueryViewController: LiftMainViewController {
    @IBOutlet var sqlView: SQLiteTextView!

    override func viewDidLoad() {
        super.viewDidLoad()
        sqlView.setup()

        NotificationCenter.default.addObserver(forName: .DatabaseReloaded, object: nil, queue: nil, using: { notification in
            guard let database = notification.object as? Database, self.document?.database.allDatabases.contains(where: { $0 === database }) ?? false else {
                return
            }

            if let ids = self.document?.keywords() {
                self.sqlView.setIdentifiers(ids)
            }
        })
    }
}
