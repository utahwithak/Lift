//
//  PrimaryKeySection.swift
//  Lift
//
//  Created by Carl Wieland on 10/25/18.
//  Copyright © 2018 Datum Apps. All rights reserved.
//

import Foundation

class PrimaryKeySection: NSObject, ConstraintSection {

    @objc dynamic var constraintTypeName: String {
        return "Primary Key"
    }

    @objc dynamic var hasConstraint = true {
        didSet {
            if hasConstraint {
                children.append("A")
                children.append("B")
            } else {
                children.removeAll()
            }
        }
    }

    @objc dynamic var constraintName: String?
    @objc dynamic var autoincrement = false
    @objc dynamic var sortOrder: Int = 0
    var conflictClause: ConflictClause?

    init(primaryKey: CreateColumnConstraintDefinitions.CreatePrimaryKey?) {
        if let primaryKey = primaryKey {
            hasConstraint = true
            constraintName = primaryKey.constraintName
            autoincrement = primaryKey.autoincrement
            sortOrder = primaryKey.sortOrder
            conflictClause = primaryKey.conflictClause
        }
    }

    var constraint: CreateColumnConstraintDefinitions.CreatePrimaryKey {
        let key = CreateColumnConstraintDefinitions.CreatePrimaryKey()
        key.constraintName = constraintName
        key.autoincrement = autoincrement
        key.sortOrder = sortOrder
        key.conflictClause = conflictClause
        return key
    }

    @objc dynamic var children = [Any]()
    
}
