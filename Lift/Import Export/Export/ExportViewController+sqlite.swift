//
//  ExportViewController+sqlite.swift
//  Yield
//
//  Created by Carl Wieland on 4/27/17.
//  Copyright © 2017 Datum. All rights reserved.
//

import Cocoa

extension ExportViewController {

    public func exportAsDumpFile() {
        let savePanel = NSSavePanel()

        let response = savePanel.runModal()

        guard response == .OK, let url = savePanel.url else {
            return
        }

        performSegue(withIdentifier: NSStoryboardSegue.Identifier(rawValue: "showProgress"), sender: self)

        guard let progressViewController = self.progressViewController else {
            return
        }

        progressViewController.setOperationText(to: NSLocalizedString("Writing Dump File", comment: "Create database step"))
        let manager = FileManager.default

        guard manager.createFile(atPath: url.path, contents: nil, attributes: nil), let handle = FileHandle(forWritingAtPath: url.path) else {
            print("Failed to create file")
            dismissViewController(progressViewController)
            return
        }
        DispatchQueue.global(qos: .userInitiated).async {

            defer {
                DispatchQueue.main.async {
                    self.dismissViewController(progressViewController)
                }

            }

            do {

                let helper = DumpHelper(handle: handle) { tableName in
                    DispatchQueue.main.async {
                        progressViewController.setOperationText(to: String(format: NSLocalizedString("Dumping data for: %@", comment: "export data step %@ replaced with table name"), tableName))
                    }
                }

                helper.preserveRowId = self.sqliteOptions.maintainRowID
                /* When playing back a "dump", the content might appear in an order
                 ** which causes immediate foreign key constraints to be violated.
                 ** So disable foreign-key constraint enforcement to prevent problems. */
                handle.write( "PRAGMA foreign_keys=OFF;\n")
                handle.write( "BEGIN TRANSACTION;\n")

                try self.document?.database.beginSavepoint(named: "dump")
                try self.document?.database.exec("PRAGMA writable_schema=ON")

                try self.document?.database.dump(query: "SELECT name, type, sql FROM sqlite_master WHERE sql NOT NULL AND type=='table' AND name!='sqlite_sequence'", to: helper)
                try self.document?.database.dump(query: "SELECT name, type, sql FROM sqlite_master WHERE name=='sqlite_sequence'", to: helper)

                try self.document?.database.dump(query: "SELECT sql FROM sqlite_master WHERE sql NOT NULL AND type IN ('index','trigger','view')", to: helper)

                if helper.writableSchema {
                    handle.write(  "PRAGMA writable_schema=OFF;\n")
                    helper.writableSchema = false
                }
                try self.document?.database.exec("PRAGMA writable_schema=OFF;")
                try self.document?.database.releaseSavepoint(named: "dump")
                handle.write( helper.errorCount != 0  ? "ROLLBACK; -- due to errors\n" : "COMMIT;\n")

            } catch {
                print("Failed to write dump file!\(error)")
            }
        }
    }

    public func exportAsDatabase() {

        let savePanel = NSSavePanel()
        savePanel.canCreateDirectories = true

        let response = savePanel.runModal()

        guard response == .OK, let url = savePanel.url else {
            return
        }

        performSegue(withIdentifier: NSStoryboardSegue.Identifier(rawValue: "showProgress"), sender: self)

        guard let progressViewController = self.progressViewController else {
            return
        }
        progressViewController.setOperationText(to: NSLocalizedString("Creating Database", comment: "Create database step"))
        let manager = FileManager.default

        var into = try? Database(type: .aux(path: url))
        if into == nil, manager.fileExists(atPath: url.path) {
            do {
                try manager.trashItem(at: url, resultingItemURL: nil)
                into = try? Database(type: .aux(path: url))
            } catch {
                presentError(error)
                dismissViewController(progressViewController)
                return
            }
        }

        guard let intoDatabase = into else {
            let alert = NSAlert()
            alert.messageText = NSLocalizedString("Unable to create database", comment: "Error message when attempting to export SQLite but can't create database")
            alert.addButton(withTitle: "Ok")
            alert.runModal()
            dismissViewController(progressViewController)
            return
        }

        intoDatabase.foreignKeysEnabled = false
        SQLiteDocumentPresenter.addPresenters(for: url)

        DispatchQueue.global(qos: .userInitiated).async {

            do {
                var errorCount = 0
                try intoDatabase.beginTransaction()
                let count = self.tablesToExport.count
                var databases = Set<Database>()

                for (index, tableNode) in self.tablesToExport.enumerated() {

                    if let database = tableNode.table.database {
                        databases.insert(database)
                    }
                    DispatchQueue.main.async {
                        progressViewController.setOperationText(to: String(format: NSLocalizedString("Creating Table: %@", comment: "Create Table step %@ replaced with table name"), tableNode.name))
                        progressViewController.updateProgress(to: Double(index) / Double(count))
                    }

                    guard let exportQuery = try tableNode.exportQuery() else {
                        print("Failed to create export query for:\(tableNode.name)")
                        errorCount += 1
                        continue
                    }

                    do {
                        let createTable = try Statement(connection: intoDatabase.connection, text: tableNode.createTableStatment())
                        do {
                            _ = try createTable.step()
                        } catch {
                            print("Failed to create destination table:\(error)")
                            errorCount += 1
                            continue
                        }
                    } catch {
                        print("failed to create create table:\(error)")
                        errorCount += 1
                        continue

                    }

                    guard let insertStatement = tableNode.importStatement(with: exportQuery),
                        let insertQuery = try? Query(connection: intoDatabase.connection, query: insertStatement) else {
                            print("Failed to create import query)")
                            errorCount += 1
                            continue
                    }

                    do {

                        DispatchQueue.main.async {
                            progressViewController.setOperationText(to: String(format: NSLocalizedString("Exporting data for: %@", comment: "export data step %@ replaced with table name"), tableNode.name))

                        }

                        try insertQuery.processData(from: exportQuery)
                    } catch {
                        print("Failed to process data for:\(tableNode.name) error:\(error)")
                        errorCount += 1
                    }

                }

                for db in databases {
                    do {
                        let allOtherSQLQuery = try Query(connection: db.connection, query: "Select sql from \(db.name.sqliteSafeString()).sqlite_master where type NOT IN ('table', 'view')")
                        try allOtherSQLQuery.processRows { row in
                            guard let data = row.first else {
                                return
                            }

                            guard case .text(let sql) = data else {
                                return
                            }

                            if try !intoDatabase.execute(statement: sql) {
                                errorCount += 1
                                print("Failed to execute sqlite_master query")
                            }

                        }
                    } catch {
                        errorCount += 1
                        print("Failed to create sqlite_master sql:\(error)")
                    }
                }

                if errorCount == 0 {
                    do {
                        try intoDatabase.endTransaction()
                    } catch {
                        print("FAILED TO COMMIT TRANSACTION!")
                        intoDatabase.rollback()
                        throw error
                    }

                } else {
                    DispatchQueue.main.async {

                        let alert = NSAlert()
                        alert.messageText = NSLocalizedString("Export completed with errors", comment: "Export error message")
                        alert.informativeText = NSLocalizedString("During export unexpected errors occured. Would you like to abort and roll back the changes, or continue and commit what has been done", comment: "Error message when there were errors during import")
                        alert.addButton(withTitle: NSLocalizedString("Commit", comment: " continue with changes even with errors"))
                        alert.addButton(withTitle: NSLocalizedString("Abort", comment: "Abort button title"))
                        let response = alert.runModal()
                        if response.rawValue == 1000 {
                            do {
                                try intoDatabase.endTransaction()
                            } catch {
                                let alert = NSAlert()
                                alert.messageText = NSLocalizedString("Error exporting data", comment: "Generic export error")
                                alert.informativeText = NSLocalizedString("Unable to save data in new database", comment: "SQLite export Error informative message")
                                alert.addButton(withTitle: "Ok")
                                alert.runModal()
                                intoDatabase.rollback()

                            }
                        } else {
                            intoDatabase.rollback()
                        }
                    }
                }

            } catch {
                DispatchQueue.main.async {
                    let alert = NSAlert()
                    alert.messageText = NSLocalizedString("Error exporting data", comment: "Generic export error")
                    alert.informativeText = NSLocalizedString("Unable to save data in new database", comment: "SQLite export Error informative message")
                    alert.addButton(withTitle: "Ok")
                    alert.runModal()
                }
            }
            DispatchQueue.main.async {
                self.dismissViewController(progressViewController)
            }
        }

    }

}
