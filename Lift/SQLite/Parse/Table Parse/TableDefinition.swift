//
//  TableDefinition.swift
//  Lift
//
//  Created by Carl Wieland on 9/28/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Foundation

class TableDefinition: NSObject {

    init(originalDefinition: TableDefinition? = nil) {
        self.originalDefinition = originalDefinition
        super.init()

        guard let orig = originalDefinition else {
            return
        }
        isTemp = orig.isTemp
        withoutRowID = orig.withoutRowID
        databaseName = orig.databaseName?.copy
        tableName = orig.tableName
        columns = orig.columns.map({ $0.duplicateForEditing() })

    }

    @objc dynamic public var isTemp = false {
        didSet {
            if isTemp {
                databaseName = SQLiteName(rawValue: "temp")
            } else {
                databaseName = nil
            }
        }
    }

    @objc dynamic public var withoutRowID = false

    @objc dynamic public var databaseName: SQLiteName? {
        didSet {
            if isTemp && databaseName?.rawValue != "temp" {
                isTemp = false
            }
        }
    }

    @objc dynamic public var tableName = "" {
        willSet {
            willChangeValue(forKey: #keyPath(hasValidName))
        }
        didSet {
            didChangeValue(forKey: #keyPath(hasValidName))
        }
    }

    @objc dynamic public var hasValidName: Bool {
        return !tableName.isEmpty
    }
    
    @objc dynamic public var columns = [ColumnDefinition]() {
        didSet {
            columns.forEach({ $0.table = self })
        }
    }

    @objc dynamic public var tableConstraints = [TableConstraint]()

    public let originalDefinition: TableDefinition?

    func copyForEditing() -> TableDefinition {
        return TableDefinition(originalDefinition: self)
    }


    var qualifiedNameForQuery: String {
        if let schemaName = databaseName {
            return "\(schemaName.sql).\(tableName.sqliteSafeString())"
        } else {
            return tableName.sqliteSafeString()
        }
    }

    var createStatment: String {
        var builder = "CREATE TABLE \(qualifiedNameForQuery)"
        builder += "(\n\t"

        builder += columns.map({ $0.creationStatement}).joined(separator: ",\n\t")

        let tConst = tableConstraints.compactMap({ $0.sql }).joined(separator: ",\n\t")
        if !tConst.isEmpty {
            builder += ",\n\t" + tConst
        }

        builder += ")"

        if withoutRowID {
            builder += " WITHOUT ROWID"
        }

        return builder

    }

    func createStatement(with includedColumnNames: [String], checkExisting: Bool) -> String {

        var builder = "CREATE TABLE "
        if checkExisting {
            builder += "IF NOT EXISTS "
        }
        builder += qualifiedNameForQuery
        builder += "("

        let includedColumns = columns.filter({includedColumnNames.contains($0.name.cleanedVersion) })
        builder += includedColumns.map({ $0.creationStatement}).joined(separator: ", ")

        let tabConstraints = tableConstraints.compactMap({ $0.sql(with: includedColumnNames )})
        if !tabConstraints.isEmpty {
            builder += ", " + tabConstraints.joined(separator: ", ")
        }

        builder += ") "
        if withoutRowID {
            builder += "WITHOUT ROWID"
        }

        return builder
    }

}
