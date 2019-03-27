//
//  TableDefinition.swift
//  Lift
//
//  Created by Carl Wieland on 9/28/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Foundation

struct TableDefinition {

    public var isTemp = false {
        didSet {
            if isTemp {
                databaseName = "temp"
            } else {
                databaseName = nil
            }
        }
    }

    public var isVirtual = false

    public var withoutRowID = false

    public var databaseName: String? {
        didSet {
            if isTemp && databaseName != "temp" {
                isTemp = false
            }
        }
    }

    public var tableName = ""

    public var moduleArguments = ""

    public var columns = [ColumnDefinition]()

    public var tableConstraints = [TableConstraint]()

    var qualifiedNameForQuery: String {
        if let schemaName = databaseName {
            return "\(schemaName.sql).\(tableName.sql)"
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
