//
//  LiftDocumentController.swift
//  Lift
//
//  Created by Carl Wieland on 10/24/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Cocoa

class LiftDocumentController: NSDocumentController {

    override func noteNewRecentDocumentURL(_ url: URL) {

        willChangeValue(for: \.recentDocumentURLs)
        super.noteNewRecentDocumentURL(url)
        didChangeValue(for: \.recentDocumentURLs)

    }
}
