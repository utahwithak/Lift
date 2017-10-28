//
//  DatabaseDetailsViewController.swift
//  Lift
//
//  Created by Carl Wieland on 10/26/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Cocoa

class DatabaseDetailsViewController: LiftViewController {


    @objc dynamic var fKeysEnabled: Bool = false

    @objc dynamic var extensionsEnabled: Bool = false

    func refreshStatus() {
        fKeysEnabled = document?.database.foreignKeysEnabled ?? false
        extensionsEnabled = document?.database.extensionsAllowed ?? false
    }

    @IBAction func setForeignKeyStatus(_ sender: NSButton) {
        document?.database.foreignKeysEnabled = sender.state == .on
    }


    @IBAction func toggleExtensionsAllowed(_ sender: NSButton) {

        if sender.state == .on {
            document?.database.enableExtensions()
        } else {
            document?.database.disableExtensions()
        }
        extensionsEnabled = document?.database.extensionsAllowed ?? false

    }

    override func viewWillAppear() {
        refreshStatus()
    }
}
