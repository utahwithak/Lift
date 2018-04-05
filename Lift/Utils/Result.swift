//
//  Result.swift
//  Lift
//
//  Created by Carl Wieland on 10/6/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Foundation

enum Result<T, U> {
    case success(T)
    case failure(U)
}
