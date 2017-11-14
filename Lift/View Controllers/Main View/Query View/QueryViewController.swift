//
//  QueryViewController.swift
//  Lift
//
//  Created by Carl Wieland on 10/25/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Cocoa

class QueryViewController: LiftMainViewController {
    @IBOutlet var sqlView: SQLiteTextView!

    private var isCanceled = false

    override func viewDidLoad() {
        super.viewDidLoad()
        sqlView.setup()

        NotificationCenter.default.addObserver(forName: .DatabaseReloaded, object: nil, queue: nil, using: { notification in
            guard let database = notification.object as? Database, self.document?.database.allDatabases.contains(where: { $0 === database }) ?? false else {
                return
            }

            if let ids = self.document?.keywords() {
                self.sqlView.setIdentifiers(ids)
            }
        })
    }

    lazy var resultsViewController: QueryResultsViewController = {
        return self.storyboard?.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("queryResultsViewController")) as! QueryResultsViewController
    }()

    lazy var snippetViewController: SnippetViewController = {
        let vc =  self.storyboard?.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("snippetViewController")) as! SnippetViewController

        return vc
    }()

    @IBAction func executeStatements(_ sender: Any) {

        isCanceled = false
        resultsViewController.startQueries()

        guard let connection = document?.database.connection else {
            return
        }

        guard let waitingView = storyboard?.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("waitingOperationView")) as? WaitingOperationViewController else {
            return
        }
        waitingView.cancelHandler = { [weak self, weak waitingView] in
            guard let mySelf = self else {
                return
            }

            mySelf.isCanceled = true

            if let waitingView = waitingView {
                mySelf.dismissViewController(waitingView)
            }

        }

        presentViewControllerAsSheet(waitingView)

        windowController?.showBottomBar()

        let text = sqlView.string
        var errors = [Error]()
        DispatchQueue.global(qos: .userInitiated).async {

            Query.executeQueries(from: text, on: connection, handler: { result in
                switch result {
                case .failure(let error):
                    DispatchQueue.main.async {
                        self.presentError(error)
                    }
                    return false
                case .success(let executeResult):
                    DispatchQueue.main.async {
                        self.resultsViewController.addResult(executeResult)
                    }
                    if let error = executeResult.error {
                        errors.append(error)
                        return self.continueAfterErrors
                    }
                }

                return !self.isCanceled 

            }, keepGoing: { return !self.isCanceled })


            DispatchQueue.main.async {

                self.dismissViewController(waitingView)

                if !self.continueAfterErrors, let error = errors.first {
                    let errorAlert = NSAlert(error: error)
                    if let window = self.view.window {
                        errorAlert.beginSheetModal(for: window, completionHandler: nil)
                    } else {
                        errorAlert.runModal()
                    }
                }

                self.resultsViewController.didFinish()
                self.document?.refresh()
            }

        }



    }

    var continueAfterErrors = false

    override var preferredSections: [DetailSection] {
        var sections = super.preferredSections
        sections.append(.custom(NSImage(named: .bookmarksTemplate)!, self.snippetViewController))

        return sections
    }
    
}


extension QueryViewController: BottomEditorContentProvider {

    var editorViewController: LiftViewController {
        return self.resultsViewController
    }

}
