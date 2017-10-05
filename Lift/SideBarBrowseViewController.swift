//
//  SideBarBrowseViewController.swift
//  Lift
//
//  Created by Carl Wieland on 10/3/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Cocoa

class SideBarBrowseViewController: NSViewController {

    var document: LiftDocument {
        return representedObject as! LiftDocument
    }


    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        (segue.destinationController as? NSViewController)?.representedObject = representedObject
    }


    @IBAction func showCreateView(_ sender: Any?) {
        performSegue(withIdentifier: NSStoryboardSegue.Identifier("createView"), sender: sender)
    }

    @IBAction func showCreateTable(_ sender: Any?) {
        performSegue(withIdentifier: NSStoryboardSegue.Identifier("createTable"), sender: sender)
    }

    @IBAction func showMenu(_ sender: NSButton) {
        if let menu = sender.menu, let event = NSApplication.shared.currentEvent {
            NSMenu.popUpContextMenu(menu, with: event, for: sender)
        }
    }
}
