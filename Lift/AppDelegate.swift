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
        #if FREE
        if !UserDefaults.standard.bool(forKey: "supportedLift") {
            if let contentViewController = NSApp.keyWindow?.contentViewController, let storyboard = contentViewController.storyboard, let vc = storyboard.instantiateController(withIdentifier: "supportLiftVC") as? SupportLiftViewController {
                contentViewController.presentAsSheet(vc)
            }
        }

        print("free version!")
        #endif

    }

    func applicationWillTerminate(_ aNotification: Notification) {
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

    @IBAction func showSupport(_ sender: Any) {
        NSWorkspace.shared.open(URL(string: "https://www.datumapps.com/contact-us/")!)
    }

    @IBAction func sendFeedback(_ sender: Any) {
        let encodedSubject = "SUBJECT=Feedback"
        let encodedTo = "carl@datumapps.com".addingPercentEncoding(withAllowedCharacters: CharacterSet.urlHostAllowed)!
        let urlstring = "mailto:\(encodedTo)?\(encodedSubject)"
        if let url = URL(string: urlstring) {
            NSWorkspace.shared.open(url)
        }
    }
}

extension NSStoryboard.Name {
    static let main = "Main"
    static let createItems = "CreateItems"
    static let importExport = "ImportExport"
    static let constraints = "Constraints"
}
