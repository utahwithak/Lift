//
//  Table.swift
//  Yield
//
//  Created by Carl Wieland on 4/3/17.
//  Copyright © 2017 Datum. All rights reserved.
//

import Foundation
import SwiftXLSX

extension Notification.Name {
    static let TableDidChangeRowCount = NSNotification.Name("TableDidLoadRowCountNotification")
    static let TableDidBeginRefreshingRowCount = NSNotification.Name("TableDidStartRefreshingRowCount")
    static let TableDidEndRefreshingRowCount = NSNotification.Name("TableDidStartRefreshingRowCount")


}

class Table: DataProvider {

    let foreignKeys: [ForeignKeyConnection]

    let definition: TableDefinition?

//https://www.sqlite.org/lang_altertable.html
    override init(database: Database, data: [SQLiteData], connection: sqlite3) throws {

        //type|name|tbl_name|rootpage|sql
        guard case .text(let sql) = data[4],
            case .text(let name) = data[1] else {
            throw LiftError.invalidTable
        }

        do {
            definition = try SQLiteCreateTableParser.parseSQL(sql)
        } catch {
            print("Failed to parse sql!:\(error)")
            definition = nil
        }

        // Foreign Keys

        let foreignKeyQuery = try Query(connection: connection, query:  "PRAGMA \(database.name.sqliteSafeString()).foreign_key_list(\(name.sqliteSafeString()))")
        var curID = -1
        //id|seq|table|from|to|on_update|on_delete|match
        var curFrom = [String]()
        var curTo = [String]()
        var curToTable = ""
        var connections = [ForeignKeyConnection]()

        try foreignKeyQuery.processRows { rowData in
            guard case .integer(let id) = rowData[0],
                case .text(let toTable) = rowData[2],
                case .text(let fromCol) = rowData[3],
                case .text(let toCol) = rowData[4] else {
                    return
            }

            if id != curID {
                if !curTo.isEmpty {
                    connections.append(ForeignKeyConnection(fromTable: name, fromColumns: curFrom, toTable: curToTable, toColumns: curTo))
                    curFrom.removeAll(keepingCapacity: true)
                    curTo.removeAll(keepingCapacity: true)
                }
                curID = id
                curToTable = toTable
            }
            curFrom.append(fromCol)
            curTo.append(toCol)

        }
        if !curTo.isEmpty {
            connections.append(ForeignKeyConnection(fromTable: name, fromColumns: curFrom, toTable: curToTable, toColumns: curTo))
        }
        
        foreignKeys = connections

        try super.init(database: database, data: data, connection: connection)

        columns.forEach{ $0.table = self }
        for column in columns {
            column.definition = definition?.columns.first(where: { $0.name.cleanedVersion == column.name })
        }

    }

    func foreignKeys(from columnName: String) -> [ForeignKeyConnection] {
        return foreignKeys.filter { $0.fromColumns.contains(columnName) }
    }

    func addDefaultValues() throws -> Bool {
        let statement = try Statement(connection: connection, text: "INSERT INTO \(qualifiedNameForQuery) DEFAULT VALUES")
        let success = try statement.step()

        if success {
            refreshTableCount()
        }

        return success
    }

    func exportQuery(for columns: [Column]) throws -> Query {

        let builder = "SELECT \( columns.map({ $0.name.sqliteSafeString() }).joined(separator: ", ")) FROM \(qualifiedNameForQuery)"

        return try Query(connection: connection, query: builder)

    }


    func tableCreationStatement(with columns: [Column]) -> String {

        if let definition = definition {
            return definition.createStatement(with: columns.map({ $0.name }), checkExisting: true)
        } else {
            let columnCreation = columns.map({ $0.simpleColumnCreationStatement } ).joined(separator: ", ")
            return "CREATE TABLE IF NOT EXISTS \(name.sqliteSafeString()) (\(columnCreation));"
        }

    }

    func importStatement(for columns: [Column], using exportQuery: Query) -> String? {
        guard !columns.isEmpty else {
            return nil
        }

        let mappedArgs = exportQuery.numericArguments.joined(separator: ", ")
        return "INSERT INTO \(name.sqliteSafeString())(\(columns.map({ $0.name.sqliteSafeString() }).joined(separator: ", "))) VALUES (\(mappedArgs));"
    }

    func exportCSV( columns: [Column], writer: Writer, with options: CSVExportOptions) throws {
        let query = try exportQuery(for: columns)

        if options.includeColumnNames {
            //write out the included column names
            let names = columns.map({ $0.name.CSVFormattedString(qouted: options.shouldQuoteFields, separator: options.separator) })
            let header = names.joined(separator: options.separator)
            writer.write("\(header)\(options.lineEnding)")
        }
        let separator = options.separator
        let lineEnding = options.lineEnding
        let blobPlaceholder = options.blobDataPlaceHolder.CSVFormattedString(qouted: options.shouldQuoteFields, separator: options.separator)
        try query.processRows(handler: { row in
            for (index, data) in row.enumerated() {
                switch data {
                case .text(let text):
                    writer.write(text.CSVFormattedString(qouted: options.shouldQuoteFields, separator: options.separator))
                case .integer(let intVal):
                    writer.write(intVal.description)
                case .float(let dVal):
                    writer.write(dVal.description)
                case .null:
                    writer.write(options.nullPlaceHolder)
                case .blob(let data):
                    if options.exportRawBlobData {
                        writer.write("<\(data.hexEncodedString())>")
                    } else {
                        writer.write(blobPlaceholder)
                    }

                }
                if index < row.count - 1 {
                    writer.write(separator)
                } else {
                    writer.write(lineEnding)
                }
            }

        })
        
    }


    func export(to worksheet: Sheet, columns: [Column], with options: XLSXExportOptions) throws {


        let query = try exportQuery(for: columns)

        if options.includeColumnNames {
            let row = worksheet.addRow()
            let rowValues: [XLSXExpressible] = columns.map({ return $0.name})
            row.setColumnData(rowValues)
        }

        try query.processRows(handler: { row in

            let nextRow = worksheet.addRow()

            let xlsValues = row.map({ (data) -> XLSXExpressible? in
                switch data {
                case .integer(let intVal):
                    return intVal
                case .float(let double):
                    return double
                case .text(let strVal):
                    return strVal
                case .null:

                    guard options.exportNULLValues else {
                        return nil
                    }

                    if !options.nullPlaceHolder.isEmpty {
                        return options.nullPlaceHolder
                    } else {
                        return ""
                    }

                case .blob(let data):

                    guard options.exportBlobData else {
                        return nil
                    }

                    if options.exportRawBlobData {
                        return data.hexEncodedString()
                    } else {
                        return options.blobDataPlaceHolder
                    }
                }

            })

            nextRow.setColumnData(xlsValues)
        })
    }



    func exportToXML(columns: [Column], with options: XMLExportOptions) throws -> XMLElement {

        let query = try exportQuery(for: columns)

        let tableElementName = "table"
        let tableElement = XMLElement(name: tableElementName)
        tableElement.addAttribute(name: "name", value: name)

        if options.includeProperties {
            let tableProperties = XMLElement(name: "properities")
            tableElement.addChild(tableProperties)
            tableProperties.addChild(XMLElement(name: "tableName", stringValue: name))
            tableProperties.addChild(XMLElement(name: "sql", stringValue: sql))
            let columnElements = XMLElement(name: "columns")
            tableProperties.addChild(columnElements)
            for column in columns {
                let colElement = XMLElement(name: "column")
                colElement.addChild(XMLElement(name: "name", stringValue: column.name))
                colElement.addChild(XMLElement(name: "type", stringValue: column.type))
                columnElements.addChild(colElement)
            }
        }


        let dataElement = XMLElement(name: options.dataSectionName)
        tableElement.addChild(dataElement)

        try query.processRows(handler: { row in

            let rowElement = XMLElement(name: options.rowName)

            for data in row {
                let element: XMLElement
                switch data {
                case .null:
                    element = XMLElement(name:"null", stringValue:options.nullPlaceHolder)
                case .integer(let val):
                    element = XMLElement(name:"integer", stringValue:"\(val)")
                case .float(let doub):
                    element = XMLElement(name:"double", stringValue:"\(doub)")
                case .text(let str):
                    element = XMLElement(name:"text", stringValue:str)
                case .blob(let data):
                    element = XMLElement(name:"blob", stringValue: options.exportRawBlobData ? data.hexEncodedString() : options.blobDataPlaceHolder)
                }

                rowElement.addChild(element)
            }

            dataElement.addChild(rowElement)
        })

        return tableElement
    }


    func exportToJSON(columns: [Column], with options: JSONExportOptions) throws -> [String: Any] {

        let query = try exportQuery(for: columns)

        var tableData = [String: Any]()

        if options.includeProperties {
            var tableProperties = [String: Any]()
            tableProperties["name"] = name
            var columnElements = [[String: Any]]()

            for column in columns {
                var options = [String: Any]()
                options["name"] = column.name
                options["type"] = column.type
                columnElements.append(options)
            }

            tableProperties["columns"] = columnElements
            tableData["properities"] = tableProperties
        }

        let names = columns.map { $0.name }
        var rows = [Any]()
        try query.processRows(handler: { row in

            var arrayElements = [Any?]()
            var dictElements = [String: Any?]()


            for (i, name) in names.enumerated() {

                let data = row[i]

                switch data {
                case .null:
                    if options.useNullLiterals {
                        arrayElements.append(nil)
                        dictElements[name] = nil
                    } else {
                        arrayElements.append( options.nullPlaceHolder)
                        dictElements[name] = options.nullPlaceHolder
                    }

                case .integer(let val):
                    arrayElements.append(val)
                    dictElements[name] = val
                case .float(let val):
                    arrayElements.append(val)
                    dictElements[name] = val
                case .text(let str):
                    arrayElements.append(str)
                    dictElements[name] = str
                case .blob(let data):
                    let value: String = {
                        if options.exportRawBlobData {
                            return data.hexEncodedString()
                        } else {
                            return options.blobDataPlaceHolder
                        }
                    }()
                    arrayElements.append(value)
                    dictElements[name] = value
                }

            }

            if options.rowsAsDictionaries {
                rows.append(dictElements)
            } else {
                rows.append(arrayElements)
            }
        })
        tableData[options.rowName] = rows
        return tableData

    }
    
}
