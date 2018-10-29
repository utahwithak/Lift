//
//  CreateTable.CheckTableConstraint.swift
//  Lift
//
//  Created by Carl Wieland on 10/26/18.
//  Copyright © 2018 Datum Apps. All rights reserved.
//

import Foundation
extension CreateTableConstraintDefinitions {

    class CreateCheckConstraint: NSObject {

        @objc dynamic var name: String?
        @objc dynamic var expression = ""

        init(existing: CreateCheckConstraint) {
            self.name = existing.name
            self.expression = existing.expression
        }

        override init() {
        }

        var toDefinition: CheckTableConstraint {
            return CheckTableConstraint(name: name, expression: expression)
        }
    }
}
