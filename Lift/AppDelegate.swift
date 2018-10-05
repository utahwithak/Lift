//
//  AppDelegate.swift
//  Lift
//
//  Created by Carl Wieland on 9/28/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {

    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool {

        showWelcomeToLiftWindow(sender)
        return false
    }

    @IBAction func showWelcomeToLiftWindow(_ sender: Any) {
        for window in NSApp.windows where window.contentViewController is WelcomeViewController {
            window.makeKeyAndOrderFront(self)
            return
        }
    }

}

extension NSStoryboard.Name {
    static let main = "Main"
    static let createItems = "CreateItems"
    static let importExport = "ImportExport"
}
