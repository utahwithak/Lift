//
//  WelcomeViewController.swift
//  Lift
//
//  Created by Carl Wieland on 12/30/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Cocoa

class WelcomeViewController: NSViewController {

    private var observationContext: NSKeyValueObservation?

    @IBOutlet weak var closeButton: NSButton!
    @IBOutlet weak var whiteBox: NSBox!

    @IBAction func createNewInMemory(_ sender: Any) {
        NSDocumentController.shared.newDocument(self)
        self.view.window?.close()
    }

    @objc dynamic var recentURLs = [URL]()
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet var tableViewMenu: NSMenu!

    @IBAction func createNewDatabase(_ sender: Any) {
        let spanel = NSSavePanel()
        spanel.canCreateDirectories = true
        spanel.canSelectHiddenExtension = true
        spanel.treatsFilePackagesAsDirectories = true
        spanel.begin { (response) in
            if response == .OK, let url = spanel.url {
                do {
                    FileManager.default.createFile(atPath: url.path, contents: nil, attributes: nil)
                    let document = try LiftDocument(contentsOf: url, ofType: "db")
                    document.makeWindowControllers()
                    document.showWindows()
                    self.view.window?.close()
                    NSDocumentController.shared.addDocument(document)
                    NSDocumentController.shared.noteNewRecentDocument(document)
                } catch {
                    self.presentError(error)
                }
            }
        }

    }

    @IBAction func showInFinder(_ sender: Any) {
        let clickedRow = tableView.clickedRow
        guard clickedRow >= 0 && clickedRow < recentURLs.count else {
            return
        }
        let urlToShow = recentURLs[clickedRow]
        NSWorkspace.shared.activateFileViewerSelecting([urlToShow])

    }

    @IBAction func performClose(_ sender: Any) {
        view.window?.close()
    }

    override func viewDidLoad() {

        super.viewDidLoad()
        observationContext = NSDocumentController.shared.observe(\.recentDocumentURLs, options: [.initial, .new], changeHandler: { [weak self] (controller, _) in
            self?.recentURLs = controller.recentDocumentURLs

        })
        tableView.doubleAction = #selector(openSelection)
        tableView.target = self

        // Insert code here to initialize your application
        let trackingArea = NSTrackingArea(rect: closeButton.bounds, options: [.mouseEnteredAndExited, .activeAlways], owner: self, userInfo: nil)
        closeButton.addTrackingArea(trackingArea)

        // Insert code here to initialize your application
        let whiteAreaTracking = NSTrackingArea(rect: whiteBox.bounds, options: [.mouseEnteredAndExited, .activeAlways], owner: self, userInfo: nil)
        whiteBox.addTrackingArea(whiteAreaTracking)
    }

    override func viewWillAppear() {
        view.window?.isOpaque                        =    false
        view.window?.styleMask = [NSWindow.StyleMask.resizable, .titled, .fullSizeContentView]
        view.window?.isMovableByWindowBackground    =    true
        view.window?.titlebarAppearsTransparent     =     true
        view.window?.titleVisibility                =    .hidden
        view.window?.showsToolbarButton            =    false
        view.window?.standardWindowButton(NSWindow.ButtonType.miniaturizeButton)?.isHidden    =    true
        view.window?.standardWindowButton(NSWindow.ButtonType.closeButton)?.isHidden        =    true
        view.window?.standardWindowButton(NSWindow.ButtonType.zoomButton)?.isHidden            =    true
        view.window?.center()

    }

    override func mouseEntered(with event: NSEvent) {
        closeButton.animator().isHidden = false

        let viewLocation = closeButton.convert(event.locationInWindow, from: nil)
        if closeButton.bounds.contains(viewLocation) {
            closeButton.animator().image = #imageLiteral(resourceName: "over")
        }

    }

    override func mouseExited(with event: NSEvent) {
        let viewLocation = whiteBox.convert(event.locationInWindow, from: nil)
        if !whiteBox.bounds.contains(viewLocation) {
            closeButton.animator().isHidden = true
        }

        closeButton.animator().image = #imageLiteral(resourceName: "closeSimple")
    }

    @objc private func openSelection(_ sender: Any) {
        let selectedRow = tableView.clickedRow
        guard selectedRow >= 0 else {
            return
        }

        let url = recentURLs[selectedRow]
        NSDocumentController.shared.openDocument(withContentsOf: url, display: true) {[weak self] (doc, alreadyOpen, error) in
            if error == nil {
                self?.performClose(NSDocumentController.shared)
            }

            if doc != nil && !alreadyOpen {
                NSDocumentController.shared.noteNewRecentDocumentURL(url)
            }
        }

    }
}
