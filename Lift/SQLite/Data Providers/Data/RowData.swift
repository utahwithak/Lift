//
//  RowData.swift
//  Lift
//
//  Created by Carl Wieland on 10/18/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Foundation

struct RowData {

    init(row: [SQLiteData]) {
        self.data = row
    }

    let data: [SQLiteData]

    lazy var datas: [CellData] = {
        return self.data.map {
            switch $0 {
            case .text(let strVal):
                return CellData(type: .text, displayValue: strVal)
            case .blob:
                return CellData(type: .blob, displayValue: "<blob>")
            case .null:
                return CellData(type: .null, displayValue: "null")
            case .integer(let int):
                return CellData(type: .integer, displayValue: "\(int)")
            case .float(let dbl):
                return CellData(type: .float, displayValue: "\(dbl)")
            }
        }
    }()

    func first(_ x: Int) -> ArraySlice<SQLiteData> {
        return data[0..<x]
    }

    func columns(matching searchString: String) -> IndexSet {
        var set = IndexSet()
        for (index, sqliteData) in data.enumerated() where sqliteData.forEditing.localizedCaseInsensitiveContains(searchString) {
            set.insert(index)
        }
        return set
    }

    subscript (index: Int) -> CellData {
        mutating get {
            return datas[index]
        }
    }

    static func json(from data: [RowData], inSelection sel: SelectionBox, columnNames: [String], map: [Int: Int], keepGoingCheck: (() -> Bool)? = nil) -> String? {

        var holder = [Any]()
        for row in sel.startColumn...sel.endRow {
            var curRow = [String: Any]()
            for rawCol in sel.startColumn...sel.endColumn {
                let col = map[rawCol]!
                let rowIndex = columnNames[col]
                switch data[row].data[col] {
                case .text(let text):
                    curRow[rowIndex] = text
                case .integer(let intVal):
                    curRow[rowIndex] = intVal
                case .float(let dVal):
                    curRow[rowIndex] = dVal
                case .null:
                    break
                case .blob(let data):
                    curRow[rowIndex] = data.hexEncodedString()
                }

                if let check = keepGoingCheck, !check() {
                    return nil
                }

            }
            holder.append(curRow)
        }

        let objForJSON: Any
        if holder.count == 1 {
            objForJSON = holder[0]
        } else {
            objForJSON = holder
        }
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: objForJSON, options: .prettyPrinted)
            return String(data: jsonData, encoding: .utf8)
        } catch {
            print("Failed to conver to JSON")
            return nil
        }

    }

    static func csv(from data: [RowData], inSelection sel: SelectionBox, map: [Int: Int], keepGoingCheck: (() -> Bool)? = nil ) -> String? {

        var writer = ""
        let separator = ","
        let lineEnding = "\n"

        for row in sel.startRow...sel.endRow {
            for rawCol in sel.startColumn...sel.endColumn {
                let col = map[rawCol]!

                let rawData = data[row].data[col]
                switch rawData {
                case .text(let text):
                    writer.append(text.CSVFormattedString(qouted: false, separator: separator))
                case .integer(let intVal):
                    writer.append(intVal.description)
                case .float(let dVal):
                    writer.append(dVal.description)
                case .null:
                    break
                case .blob(let data):
                    writer.write("<\(data.hexEncodedString())>")
                }
                if rawCol < sel.endColumn {
                    writer.write(separator)
                }

                if let check = keepGoingCheck, !check() {
                    return nil
                }
            }
            if row < sel.endRow {
                writer.write(lineEnding)
            }

        }
        return writer
    }
}

struct CellData {
    let type: SQLiteDataType
    let displayValue: String
}
