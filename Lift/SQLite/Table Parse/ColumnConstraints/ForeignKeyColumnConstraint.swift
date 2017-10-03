//
//  ForeignKeyColumnConstraint.swift
//  Lift
//
//  Created by Carl Wieland on 9/29/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Foundation

class ForeignKeyColumnConstraint: ColumnConstraint {

    var clause: ForeignKeyClause

    init(with name: SQLiteName?, from scanner: Scanner) throws {
        clause = try ForeignKeyClause(from: scanner)
        super.init(name: name)
    }
}
