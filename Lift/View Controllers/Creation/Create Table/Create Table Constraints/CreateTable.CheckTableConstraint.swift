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
        @objc dynamic var enabled: Bool = false
        @objc dynamic var name: String?
        @objc dynamic var expression = ""

        init(existing: CheckTableConstraint) {
            self.name = existing.name
            self.expression = existing.checkExpression
            enabled = true
        }

        override init() {
        }

        var toDefinition: CheckTableConstraint? {
            guard enabled else {
                return nil
            }
            return CheckTableConstraint(name: name, expression: expression)
        }
    }
}
