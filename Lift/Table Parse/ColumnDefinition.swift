//
//  ColumnDefinition.swift
//  Lift
//
//  Created by Carl Wieland on 9/28/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Foundation


class ColumnDefinition {

    public var name: SQLiteName

    public var type = ""

    public var columnConstraints = [ColumnConstraint]()

    init?(from scanner: Scanner) throws {

        let colName = try SQLiteCreateTableParser.parseStringOrName(from: scanner)
        if colName.isEmpty {
            return nil
        }
        name = SQLiteName(rawValue: colName)
        type = try SQLiteCreateTableParser.parseStringOrName(from: scanner)

        while let constraint = try ColumnConstraint.parseConstraint(from: scanner) {
            columnConstraints.append(constraint)
        }

        
    }



   

}
