//
//  ImportWindowController.swift
//  Lift
//
//  Created by Carl Wieland on 10/24/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Cocoa

class ImportWindowController: NSWindowController {


    @IBAction override func newWindowForTab(_ sender: Any?) {

        guard let otherWindowController = storyboard?.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("importWindow")) as? NSWindowController, let window = otherWindowController.window else {
            return
        }
        self.window?.addTabbedWindow(window, ordered: .above)

        window.orderFront(self.window)
        window.makeKey()


    }

    func addTab() {
        guard let otherWindowController = storyboard?.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("importViewController")) as? NSViewController else {
            return
        }
        let tabWindow = NSWindow(contentViewController: otherWindowController)
        self.window?.addTabbedWindow(tabWindow, ordered:.above)

        tabWindow.orderFront(self.window)
        tabWindow.makeKey()


    }

    @IBAction func copy(_ sender: Any) {
        
    }

}
