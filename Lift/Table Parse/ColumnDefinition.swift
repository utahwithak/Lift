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

    public var type: SQLiteName?

    public var columnConstraints = [ColumnConstraint]()

    init?(from scanner: Scanner) throws {

        name = try SQLiteCreateTableParser.parseStringOrName(from: scanner)
        if name.rawValue.isEmpty {
            return nil
        }
        if let constraint = try ColumnConstraint.parseConstraint(from: scanner) {
            type = nil
            columnConstraints.append(constraint)
        } else {
            type = try SQLiteCreateTableParser.parseStringOrName(from: scanner)
        }

        while let constraint = try ColumnConstraint.parseConstraint(from: scanner) {
            columnConstraints.append(constraint)
        }

        
    }



   

}
