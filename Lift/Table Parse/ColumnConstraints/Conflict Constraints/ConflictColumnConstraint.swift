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

    init(with name: String, from scanner: Scanner) throws {
        conflictClause = try ConflictClause(from: scanner)

        super.init(name: name)
    }
}
