//
//  CreateColumnConstraintDefinitions.swift
//  Lift
//
//  Created by Carl Wieland on 9/17/18.
//  Copyright © 2018 Datum Apps. All rights reserved.
//

import Foundation

class CreateColumnConstraintDefinitions: NSObject {

    let existingConstraints: [ColumnConstraint]?

    override init() {
        existingConstraints = nil
    }

    init(constraints: [ColumnConstraint]) {
        self.existingConstraints = constraints
        if let defaultConst = constraints.compactMap({ $0 as? DefaultColumnConstraint}).first {
            defaultConstraint = CreateDefaultValue(existing: defaultConst)
        }
        if let primaryKey = constraints.compactMap({ $0 as? PrimaryKeyColumnConstraint}).first {
            self.primaryKey = CreatePrimaryKey(existing: primaryKey)
        }
        if let nonNull = constraints.compactMap({ $0 as? NotNullColumnConstraint}).first {
            self.nonNull = CreateNonNull(existing: nonNull)
        }
        if let unique = constraints.compactMap({ $0 as? UniqueColumnConstraint}).first {
            self.unique = CreateUnique(existing: unique)
        }
    }

    @objc dynamic var primaryKey: CreatePrimaryKey?
    @objc dynamic var nonNull: CreateNonNull?
    @objc dynamic var unique: CreateUnique?
    @objc dynamic var check: CreateCheckConstraint?
    @objc dynamic var defaultConstraint: CreateDefaultValue?
    @objc dynamic var collate: CreateCollateConstraint?

    var columnConstraints: [ColumnConstraint] {

        var constraints = [ColumnConstraint]()
        if let primary = primaryKey, primary.enabled {
            constraints.append(primary.constraint)
        }

        if let nonNull = nonNull, nonNull.enabled {
            constraints.append(nonNull.constraint)
        }

        if let unique = unique, unique.enabled {
            constraints.append(unique.toConstraint)
        }

        if let check = check, check.enabled {
            constraints.append(check.toConstraint)
        }

        if let defaultConstraint = defaultConstraint, defaultConstraint.enabled {
            constraints.append(defaultConstraint.toConstraint)
        }

        if let collate = collate, collate.enabled {
            constraints.append(collate.toConstraint)
        }

        return constraints
    }

}
