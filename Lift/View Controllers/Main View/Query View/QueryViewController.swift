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
    private var potentialCompletions = [SQLiteTextView.CompletionResult]()
    private var isCanceled = false
    @objc dynamic var shouldContinueAfterErrors = false
    override func viewDidLoad() {
        super.viewDidLoad()
        sqlView.setup()
        NotificationCenter.default.addObserver(self, selector: #selector(databaseReloaded), name: .DatabaseReloaded, object: nil)
        sqlView.completionDelegate = self
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        MASShortcutBinder.shared()?.bindShortcut(withDefaultsKey: AppDelegate.runGlobalShortcut, toAction: {[weak self] in
            self?.executeStatements(nil)
        })
    }

    override func viewDidDisappear() {
        super.viewDidDisappear()
        MASShortcutBinder.shared()?.breakBinding(withDefaultsKey: AppDelegate.runGlobalShortcut)
    }
    @objc private func databaseReloaded(_ noti: Notification) {
        guard let database = noti.object as? Database, self.document?.database.allDatabases.contains(where: { $0 === database }) ?? false else {
            return
        }

        refreshCompletions()

    }

    lazy var resultsViewController: QueryResultsViewController? = {
        return self.storyboard?.instantiateController(withIdentifier: "queryResultsViewController") as? QueryResultsViewController
    }()

    lazy var snippetViewController: SnippetViewController? = {
        let vc =  self.storyboard?.instantiateController(withIdentifier: "snippetViewController") as? SnippetViewController
        vc?.snippetDataProvider = self
        return vc
    }()

    @IBAction func executeStatements(_ sender: Any?) {
        guard view.window != nil else {
            return
        }
        isCanceled = false
        resultsViewController?.startQueries()

        guard let connection = document?.database.connection else {
            return
        }

        guard let waitingView = storyboard?.instantiateController(withIdentifier: "waitingOperationView") as? WaitingOperationViewController else {
            return
        }
        waitingView.cancelHandler = { [weak self, weak waitingView] in
            guard let mySelf = self else {
                return
            }

            mySelf.isCanceled = true

            if let waitingView = waitingView {
                mySelf.dismiss(waitingView)
            }

        }

        presentAsSheet(waitingView)

        waitingView.indeterminate = false

        windowController?.showBottomBar()

        let text = sqlView.string
        var errors = [Error]()
        DispatchQueue.global(qos: .userInitiated).async {

            Query.executeQueries(from: text, on: connection, handler: { result, progress in

                DispatchQueue.main.async {
                    waitingView.value = progress
                }

                switch result {
                case .failure(let error):

                    errors.append(error)

                    return self.shouldContinueAfterErrors
                case .success(let executeResult):
                    DispatchQueue.main.async {
                        self.resultsViewController?.addResult(executeResult)
                    }
                    if let error = executeResult.error {
                        errors.append(error)
                        return self.shouldContinueAfterErrors
                    }
                }

                return !self.isCanceled

            }, keepGoing: { return !self.isCanceled })

            DispatchQueue.main.async {

                if waitingView.presentingViewController != nil {
                    self.dismiss(waitingView)
                }

                if !self.shouldContinueAfterErrors, let error = errors.first, !(error as NSError).isUserCanceledError {
                    let errorAlert = NSAlert(error: error)
                    if let window = self.view.window {
                        errorAlert.beginSheetModal(for: window, completionHandler: nil)
                    } else {
                        errorAlert.runModal()
                    }
                }

                self.resultsViewController?.didFinish()
                self.document?.refresh()
            }

        }

    }

    override var preferredSections: [DetailSection] {
        var sections = super.preferredSections
        if let snippetVC = self.snippetViewController {
            sections.append(.custom(NSImage(named: NSImage.bookmarksTemplateName)!, snippetVC))
        } else {
            print("Unable to create snippetVC!?")
        }

        return sections
    }

    private static let keywordCompletions: [SQLiteTextView.CompletionResult] = {
        let keywords = ["ABORT", "ACTION", "ADD", "AFTER", "ALL", "ALTER", "ANALYZE", "AND", "AS", "ASC", "ATTACH", "AUTOINCREMENT", "BEFORE", "BEGIN", "BETWEEN", "BY", "CASCADE", "CASE", "CAST", "CHECK", "COLLATE", "COLUMN", "COMMIT", "CONFLICT", "CONSTRAINT", "CREATE", "CROSS", "CURRENT_DATE", "CURRENT_TIME", "CURRENT_TIMESTAMP", "DATABASE", "DEFAULT", "DEFERRABLE", "DEFERRED", "DELETE", "DESC", "DETACH", "DISTINCT", "DROP", "EACH", "ELSE", "END", "ESCAPE", "EXCEPT", "EXCLUSIVE", "EXISTS", "EXPLAIN", "FAIL", "FOR", "FOREIGN", "FROM", "FULL", "GLOB", "GROUP", "HAVING", "IF", "IGNORE", "IMMEDIATE", "IN", "INDEX", "INDEXED", "INITIALLY", "INNER", "INSERT", "INSTEAD", "INTERSECT", "INTO", "IS", "ISNULL", "JOIN", "KEY", "LEFT", "LIKE", "LIMIT", "MATCH", "NATURAL", "NO", "NOT", "NOTNULL", "NULL", "OF", "OFFSET", "ON", "OR", "ORDER", "OUTER", "PLAN", "PRAGMA", "PRIMARY", "QUERY", "RAISE", "RECURSIVE", "REFERENCES", "REGEXP", "REINDEX", "RELEASE", "RENAME", "REPLACE", "RESTRICT", "RIGHT", "ROLLBACK", "ROW", "SAVEPOINT", "SELECT", "SET", "TABLE", "TEMP", "TEMPORARY", "THEN", "TO", "TRANSACTION", "TRIGGER", "UNION", "UNIQUE", "UPDATE", "USING", "VACUUM", "VALUES", "VIEW", "VIRTUAL", "WHEN", "WHERE", "WITH", "WITHOUT", "INTEGER", "TEXT", "BLOB", "NULL", "REAL", "FALSE", "TRUE"]
        return keywords.map { SQLiteTextView.CompletionResult.keyword($0) }
    }()

    private func refreshCompletions() {

        var ids = Set<String>()

        var potentials = QueryViewController.keywordCompletions
        guard let document = document else {
            return
        }

        for db in document.database.allDatabases {
            potentials.append(.database(db.name))
            ids.insert(db.name)
            for table in db.tables {
                ids.insert(table.name)
                potentials.append(.table(table.name, database: db.name))
                for column in table.columns {
                    ids.insert(column.name)
                    potentials.append(.column(column.name, table: table.name))
                }
            }
        }
        sqlView.setIdentifiers(ids)
        potentials.sort(by: { $0.completion < $1.completion })
        self.potentialCompletions = potentials
    }

}

extension QueryViewController: BottomEditorContentProvider {

    var editorViewController: LiftViewController {
        return self.resultsViewController!
    }

}
extension QueryViewController: SnippetDataDelegate {
    var currentSQL: String {
        return sqlView.string
    }

}

extension QueryViewController: SQLiteTextViewCompletionDelegate {
    func completionsFor(range: NSRange, in textView: SQLiteTextView) -> [SQLiteTextView.CompletionResult] {

        let partialWord = (textView.string as NSString).substring(with: range)

        if partialWord.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return self.potentialCompletions
        } else {
            // last will be empty string from the "." so we drop that and get the actual last
            //
            if partialWord.last == ".", let parent = partialWord.components(separatedBy: ".").dropLast().last {
                return potentialCompletions.filter {
                    return $0.parentText?.lowercased() == parent.lowercased()
                }
            } else if let lastComponent = partialWord.components(separatedBy: ".").last {
                return potentialCompletions.filter {
                    return $0.completion.lowercased().hasPrefix(lastComponent.lowercased())
                }
            } else {
                return potentialCompletions.filter {
                    return $0.completion.lowercased().hasPrefix(partialWord.lowercased())
                }
            }
        }
    }
}
extension QueryViewController: PrintableViewController {
    func printView() {
        sqlView.printView(self)
    }
}
