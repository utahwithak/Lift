//
//  LiftDocumentController.swift
//  Lift
//
//  Created by Carl Wieland on 10/24/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Cocoa

class LiftDocumentController: NSDocumentController {

    override func newDocument(_ sender: Any?) {
        print("new doc")
        super.newDocument(sender)
    }

}
