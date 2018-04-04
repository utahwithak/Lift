//
//  ConflictColumnConstraint.swift
//  Lift
//
//  Created by Carl Wieland on 9/29/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Foundation

class ConflictColumnConstraint: ColumnConstraint {

    var conflictClause: ConflictClause?

    override init(name: SQLiteName? = nil) {
        super.init(name: name)
    }

    init(with name: SQLiteName?, from scanner: Scanner) throws {
        conflictClause = try ConflictClause(from: scanner)

        super.init(name: name)
    }

    init(copying: ConflictColumnConstraint) {
        conflictClause = copying.conflictClause?.copy
        super.init(name: copying.constraintName)
    }

}
