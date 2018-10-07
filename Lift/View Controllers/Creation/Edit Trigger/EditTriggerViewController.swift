//
//  EditTriggerViewController.swift
//  Lift
//
//  Created by Carl Wieland on 10/5/18.
//  Copyright © 2018 Datum Apps. All rights reserved.
//

import AppKit

class EditTriggerViewController: LiftViewController {

    @objc dynamic var databases = [Database]()
    @objc dynamic var triggerColumns = [Column]()

    override var representedObject: Any? {
        didSet {
            self.databases = document?.database.allDatabases ?? []
        }
    }

    var selectedTriggerTable: Table? {
        return tableController.selectedObjects?.first as? Table
    }

    @objc dynamic var triggerName: String = ""

    @IBOutlet var databaseController: NSArrayController!

    @IBOutlet var tableController: NSArrayController!
    @IBOutlet var columnController: NSArrayController!

    @IBOutlet weak var whereClauseHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var columnBoxHeightConstraint: NSLayoutConstraint!
    @objc dynamic var needsColumns = false
    @objc dynamic var timingIndex = 3

    @objc dynamic var actionIndex: NSInteger = 0 {
        didSet {
            switch actionIndex {
            case 0, 1:
                needsColumns = false
            default:
                needsColumns = true
            }
        }
    }

    private var triggerAction: TriggerParser.Trigger.Action {
        get {
            switch actionIndex {
            case 0:
                return .delete
            case 1:
                return .insert
            case 2:
                if useSpecificColumns {
                    return .updateOf(columns: specifiedColumns.map({ $0.name }))
                } else {
                    return .update
                }
            default:
                fatalError("Unavaiable trigger action!")
            }
        }
        set {
            switch newValue {
            case .delete:
                actionIndex = 0
                useSpecificColumns = false
                needsColumns = false

            case .insert:
                actionIndex = 1
                useSpecificColumns = false
                needsColumns = false
            case .update:
                actionIndex = 2
                needsColumns = true
                useSpecificColumns = false

            case .updateOf(columns: let columns):
                actionIndex = 2
                needsColumns = true
                useSpecificColumns = false
                if let table = selectedTriggerTable {
                    for column in columns {
                        if let tableColumn = table.columns.first(where: {$0.name.cleanedVersion == column.cleanedVersion}) {
                            specifiedColumns.append(tableColumn)
                        }
                    }
                }

            }
        }
    }

    private var triggerTiming: TriggerParser.Trigger.Timing {
        return TriggerParser.Trigger.Timing(rawValue: timingIndex) ?? .unspecified
    }

    var existingTrigger: Trigger? {
        willSet {
            willChangeValue(for: \.actionTitle)
        }
        didSet {
            didChangeValue(for: \.actionTitle)

            guard let parsedTrigger = existingTrigger?.parsedTrigger else {
                return
            }
            triggerName = parsedTrigger.name
            whereClause = parsedTrigger.whenExpression
            useWhereClause = !(whereClause?.isEmpty ?? true)

            if let database = existingTrigger?.database {
                databaseController.setSelectedObjects([database])
                if let table = database.tables.first(where: { $0.name == parsedTrigger.tableName }) {
                    tableController.setSelectedObjects([table])
                }
            }

            timingIndex = parsedTrigger.timing.rawValue
            triggerAction = parsedTrigger.action
            isForEachRow = parsedTrigger.forEachRow
            statements = parsedTrigger.sql

        }
    }

    @objc dynamic var actionTitle: String {
        if existingTrigger != nil {
            return NSLocalizedString("editIndexViewController.actionTitle.Modify", value: "Modify", comment: "Button title when we are modifying existing index")
        } else {
            return NSLocalizedString("editIndexViewController.actionTitle.Modify", value: "Create", comment: "Button title when we are modifying existing index")
        }
    }
    @objc dynamic var tableIndexes: NSIndexSet? {
        didSet {
            clearColumns()
        }
    }
    @objc dynamic var databaseIndexes: NSIndexSet? {
        didSet {
            clearColumns()
        }
    }

    @objc dynamic var isForEachRow = false

    @objc dynamic var useSpecificColumns = false

    @objc dynamic var useWhereClause = false {
        didSet {
            if isViewLoaded {
                whereClauseHeightConstraint.animator().constant = useWhereClause ? 100 : 0
            }
        }
    }

    @objc dynamic var whereClause: String?

    @objc dynamic var statements: String?

    override func viewDidLoad() {
        whereClauseHeightConstraint.animator().constant = useWhereClause ? 100 : 0
        if let action = existingTrigger?.parsedTrigger?.action {
            switch action {
            case .delete, .insert:
                needsColumns = false
            case .update, .updateOf(columns: _):
                needsColumns = true
            }
        } else {
            needsColumns = false
        }

    }

    @objc dynamic var specifiedColumns = [Column]() {
        didSet {
            columnBoxHeightConstraint?.animator().constant = CGFloat(specifiedColumns.count) * 22.0 + 30
        }
    }

    @IBAction func addSpecifiedColumn(_ sender: Any) {
        guard let table = selectedTriggerTable else {
            return
        }

        if specifiedColumns.count < table.columns.count {
            specifiedColumns.append(table.columns[specifiedColumns.count])
        }
    }

    private func clearColumns() {
        specifiedColumns.removeAll(keepingCapacity: true)
    }

    @IBAction func performAction(_ sender: NSButton) {
        guard !triggerName.isEmpty, let table = selectedTriggerTable, let statements = statements, !statements.isEmpty else {
            return
        }

        let mainStoryboard = NSStoryboard(name: .main, bundle: .main)
        guard let waitingView = mainStoryboard.instantiateController(withIdentifier: "statementWaitingView") as? StatementWaitingViewController else {
            return
        }
        let operation: () throws -> Bool = { [weak self] in
            guard let database = self?.document?.database, let self = self else {
                return false
            }
            let savePointName = "DatumApps_CreateTrigger"
            try database.beginSavepoint(named: savePointName)
            do {
                if let existingTrigger = self.existingTrigger {
                    try database.exec("DROP TRIGGER \(existingTrigger.qualifiedName)")
                }

                var newQuery = "CREATE TRIGGER "

                guard let dbIndex = self.databaseIndexes?.firstIndex, dbIndex >= 0 && dbIndex < self.databases.count else {
                    return false
                }

                let intoDB = self.databases[dbIndex]
                newQuery += intoDB.name + "." + self.triggerName.sqliteSafeString()

                newQuery += " \(self.triggerTiming.sql)"

                switch self.triggerAction {
                case .delete:
                    newQuery += "DELETE ON "
                case .insert:
                    newQuery += "INSERT ON "
                case .update:
                    newQuery += "INSERT ON "
                case .updateOf(columns: let columns):
                    let columnStr = columns.map({ $0.sqliteSafeString() }).joined(separator: ", ")
                    newQuery += "UPDATE OF \(columnStr) ON "
                }

                newQuery += table.name.sqliteSafeString()

                if self.isForEachRow {
                    newQuery += " FOR EACH ROW "
                }

                if self.useWhereClause, let clause = self.whereClause {
                    newQuery += " WHEN \(clause) "
                }
                newQuery += " BEGIN \(statements) END"

                try database.exec(newQuery)
                try database.releaseSavepoint(named: savePointName)
                return true
            } catch {
                do {
                    try database.rollbackSavepoint(named: savePointName)
                    try database.releaseSavepoint(named: savePointName)

                } catch {
                    print("Failed to rollback savepoint!")
                }
                throw error
            }

        }

        waitingView.delegate = self

        waitingView.operation = .customCall(operation)

        waitingView.representedObject = representedObject
        presentAsSheet(waitingView)

    }
}

extension EditTriggerViewController: StatementWaitingViewDelegate {
    func waitingView(_ view: StatementWaitingViewController, finishedSuccessfully: Bool) {
        dismiss(view)

        if finishedSuccessfully {
            document?.database.refresh()
            dismiss(self)
        }
    }
}

