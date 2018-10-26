//
//  ConstraintSection.swift
//  Lift
//
//  Created by Carl Wieland on 10/25/18.
//  Copyright © 2018 Datum Apps. All rights reserved.
//

import Foundation

@objc protocol ConstraintSection: NSObjectProtocol {
    @objc var hasConstraint: Bool { get set }
    @objc var constraintTypeName: String { get }
    @objc var constraintName: String? { get set }

}
