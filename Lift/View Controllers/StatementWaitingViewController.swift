//
//  StatementWaitingViewController.swift
//  Lift
//
//  Created by Carl Wieland on 10/6/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Cocoa

enum OperationType {
    case statement(String)
    case customCall( () throws -> Bool )
    case migrate(with: CreateTableDefinition)
}

protocol StatementWaitingViewDelegate: class {
    func waitingView(_ view: StatementWaitingViewController, finishedSuccessfully: Bool)
}

class StatementWaitingViewController: LiftViewController {

    var operation: OperationType!

    @IBOutlet weak var activityIndicator: NSProgressIndicator!

    @IBOutlet weak var indicatorHeight: NSLayoutConstraint!

    @IBOutlet weak var errorViewHeightConstraint: NSLayoutConstraint!

    weak var delegate: StatementWaitingViewDelegate?

    @IBOutlet weak var errorLabelHeight: NSLayoutConstraint!

    @IBOutlet weak var errorLabel: NSTextField!

    override func viewDidLoad() {
        super.viewDidLoad()

        errorViewHeightConstraint.constant = 0

        activityIndicator.startAnimation(nil)

        switch operation! {
        case .statement(let statement):
            document?.database.executeStatementInBackground(statement) {[weak self] (error) in
                self?.activityIndicator.stopAnimation(self)
                self?.indicatorHeight.constant = 0
                if let error = error {
                    self?.handleError(error)
                } else {
                    self?.handleSuccess()
                }
            }
        case .customCall(let operation):
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                do {
                    let success = try operation()
                    if success {
                        DispatchQueue.main.async {
                            self?.handleSuccess()
                        }
                    } else {
                        DispatchQueue.main.async {
                            self?.handleError(LiftError.unknownOperationError)
                        }
                    }
                } catch {
                    DispatchQueue.main.async {
                        self?.handleError(error)
                    }
                }
            }
        case .migrate(with: let table):
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in

                guard let doc = self?.document, let originalDefinition = table.originalDefinition else {
                    return
                }
                var startedTransaction = false

                var inSavepoint = false
                let savePointName = "\"\(NSUUID().uuidString)\""

                do {
                    let fkeysEnabled = doc.database.areForeignKeysEnabled
                    if fkeysEnabled {
                        //need to disable fkeys before going forward
                        doc.database.areForeignKeysEnabled = false
                    }

                    if doc.database.autocommitStatus == .autocommit {

                        try doc.database.beginTransaction()
                        startedTransaction = true
                    }

                    try doc.database.beginSavepoint(named: savePointName)
                    inSavepoint = true
                    let uniqueTableName = NSUUID().uuidString.sql
                    let uniqueQualifiedName: String
                    if let schema = originalDefinition.databaseName?.sql {
                        uniqueQualifiedName = "\(schema).\(uniqueTableName)"
                    } else {
                        uniqueQualifiedName = uniqueTableName
                    }

                    // rename the existing to a unique name
                    let query = "ALTER TABLE \(originalDefinition.qualifiedNameForQuery) RENAME TO \(uniqueTableName);"
                    try doc.database.exec(query)

                    // create new definition
                    let newTableDefinition = table.toDefinition
                    let creationStatement = newTableDefinition.createStatment
                    try doc.database.exec(creationStatement)

                    // copy old table data over to new table
                    var selectColumns = [String]()
                    var intoColumns = [String]()
                    for column in table.columns {
                        if let originalName = column.originalDefinition?.name {
                            selectColumns.append(originalName)
                            intoColumns.append(column.name)
                        }
                    }

                    let insertStatement = "INSERT INTO \(newTableDefinition.qualifiedNameForQuery)(\(intoColumns.joined(separator: ", "))) SELECT \(selectColumns.joined(separator: ", ")) FROM \(uniqueQualifiedName)"
                    try doc.database.exec(insertStatement)

                    try doc.database.exec("DROP TABLE \(uniqueQualifiedName)")
                    try doc.database.exec("ALTER TABLE \(newTableDefinition.qualifiedNameForQuery) RENAME TO \(uniqueTableName);")
                    try doc.database.exec("ALTER TABLE \(uniqueQualifiedName) RENAME TO \(newTableDefinition.tableName.sql);")
                    doc.database.areForeignKeysEnabled = fkeysEnabled
                    try doc.database.releaseSavepoint(named: savePointName)

                    if startedTransaction {
                        try doc.database.endTransaction()
                    }
                    DispatchQueue.main.async {
                        self?.handleSuccess()
                    }

                } catch {
                    if inSavepoint {
                        do {
                            try doc.database.rollbackSavepoint(named: savePointName)
                        } catch {
                            print("Failed to rollback savepoint!")
                        }
                    }
                    if startedTransaction {
                        doc.database.rollback()
                    }
                    DispatchQueue.main.async {
                        self?.handleError(error)
                    }
                }
            }

        }

    }

    func handleSuccess() {
        delegate?.waitingView(self, finishedSuccessfully: true)
    }

    @IBAction func toggleError(_ sender: NSButton) {
        if sender.state == .on {
            errorLabelHeight.constant = 56
        } else {
            errorLabelHeight.constant = 0
        }
    }
    func handleError(_ error: Error) {
        errorViewHeightConstraint.constant = 150
        errorLabel.stringValue = error.localizedDescription
        errorLabelHeight.constant = 56

    }
    @IBAction func abortOperation(_ sender: Any) {
        // even though we failed, report success and
        // abort the operation completly
        //
        delegate?.waitingView(self, finishedSuccessfully: true)

    }

    @IBAction func dismissWaitingView(_ sender: Any) {
        delegate?.waitingView(self, finishedSuccessfully: false)
    }

    @IBOutlet weak var abortOperationButton: NSButton!

    @IBOutlet weak var dimissViewButton: NSButton!
}
