//
//  AttachDatabaseViewController.swift
//  Lift
//
//  Created by Carl Wieland on 10/10/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Cocoa

class AttachDatabaseViewController: LiftViewController {


    @IBOutlet weak var destinationView: DestinationView!

    @objc dynamic var name: String = ""
    @objc dynamic var path: URL? {
        didSet {
            if name.isEmpty || name == oldValue?.deletingPathExtension().lastPathComponent {
                name = path?.deletingPathExtension().lastPathComponent ?? ""
            }
        }
    }

    override func viewDidLoad() {
        destinationView.delegate = self
    }

    @IBAction func choosePath(_ sender: Any) {
        let openPanel = NSOpenPanel()

        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false

        openPanel.runModal()
        path = openPanel.url

    }
    @IBAction func attachDatabase(_ sender: Any) {

        guard let database = document?.database, let path = path else {
            print("No database to attach to!")
            return
        }

        database.attachDatabase(at: path, with: name.sqliteSafeString()) { (error) in
            print("Error:\(error)")
            
        }

    }
}


extension AttachDatabaseViewController: DestinationViewDelegate {

    func processURLs(_ urls: [URL], center: NSPoint) {
        path = urls.first
    }
}
