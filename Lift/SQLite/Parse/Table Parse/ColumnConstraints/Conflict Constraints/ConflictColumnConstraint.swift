//
//  ConflictColumnConstraint.swift
//  Lift
//
//  Created by Carl Wieland on 9/29/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Foundation

protocol ConflictColumnConstraint: ColumnConstraint {
    var conflictClause: ConflictClause? { get }

}
