//
//  CreateTable.ForeignKeyTable.swift
//  Lift
//
//  Created by Carl Wieland on 10/26/18.
//  Copyright © 2018 Datum Apps. All rights reserved.
//

import Foundation
extension CreateTableConstraintDefinitions {

    class CreateForeignKeyConstraint: NSObject {

        @objc dynamic var name: String?
        @objc dynamic var columns = [CreateColumnDefinition]()

        private var clause = ForeignKeyClause(destination: "", columns: [])

        init(existing: CreateForeignKeyConstraint) {
            self.name = existing.name
            self.columns = existing.columns
            self.clause = existing.clause
        }

        override init() {
        }

        var toDefinition: ForeignKeyTableConstraint {
            return ForeignKeyTableConstraint(name: name, fromColumns: columns.map { $0.name }, clause: clause)
        }
    }
}
