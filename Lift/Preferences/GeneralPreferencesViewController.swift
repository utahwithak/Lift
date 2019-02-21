//
//  GeneralPreferencesViewController.swift
//  Lift
//
//  Created by Carl Wieland on 2/21/19.
//  Copyright © 2019 Datum Apps. All rights reserved.
//

import Foundation

class GeneralPreferencesViewController: NSViewController {
    @IBOutlet weak var shortcutView: MASShortcutView!

    override func viewDidLoad() {
        shortcutView.associatedUserDefaultsKey = AppDelegate.runGlobalShortcut
    }
}
