//
//  AppDelegate.swift
//  Lift
//
//  Created by Carl Wieland on 9/28/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Cocoa
// Pick a preference key to store the shortcut between launches

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    public static let runGlobalShortcut = "GlobalRunShortcut"

    override init() {
        UserDefaults.standard.register(defaults: ["suggestCompletions": true])
        if let shortcut = MASShortcut(keyCode: UInt(kVK_F5), modifierFlags: 0) {
            MASShortcutBinder.shared()?.registerDefaultShortcuts([AppDelegate.runGlobalShortcut: shortcut])
        }

        ValueTransformer.setValueTransformer(RowCountFormatter(), forName: NSValueTransformerName(rawValue: "RowCountFormatter"))
        ValueTransformer.setValueTransformer(URLPathFormatter(), forName: NSValueTransformerName("URLPathFormatter"))
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {

        #if FREE
        pesterBuy()
        #endif
    }

    func pesterBuy() {
        #if FREE
        var time = 30
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(time)) {
            if !UserDefaults.standard.bool(forKey: "supportedLift") {
                let storyboard = NSStoryboard(name: .main, bundle: nil)
                if let contentViewController = NSApp.windows.last?.contentViewController, let vc = storyboard.instantiateController(withIdentifier: "supportLiftVC") as? SupportLiftViewController {
                    if contentViewController.children.lastIndex(where: { $0 is SupportLiftViewController}) == nil {
                        contentViewController.presentAsSheet(vc)
                    }
                }
            }
            time += (time * 4)
            if time < (60 * 60) && !UserDefaults.standard.bool(forKey: "supportedLift") {
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(time), execute: {self.pesterBuy()})
            }
        }

        print("free version!")
        #endif
    }

    func applicationWillTerminate(_ aNotification: Notification) {
    }

    func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool {
        if !UserDefaults.standard.bool(forKey: "hideWelcomeScreenOnLaunch") {
            createAndShowWelcome()
        }
        return false
    }

    @IBAction func showWelcomeToLiftWindow(_ sender: Any) {
        for window in NSApp.windows where window.contentViewController is WelcomeViewController {
            window.makeKeyAndOrderFront(self)
            return
        }
        createAndShowWelcome()
    }

    private func createAndShowWelcome() {
        let storyboard = NSStoryboard(name: .main, bundle: .main)

        guard let windowController = storyboard.instantiateController(withIdentifier: "welcomeWindow") as? WelcomeWindowController else {
            fatalError("Error getting main window controller")
        }
        windowController.showWindow(self)
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
