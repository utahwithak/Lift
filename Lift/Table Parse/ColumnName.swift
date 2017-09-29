//
//  ColumnName.swift
//  Lift
//
//  Created by Carl Wieland on 9/29/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Foundation

struct ColumnName {
    let rawValue: String


}

func == (lhs: ColumnName, rhs: String) -> Bool {
    return lhs.rawValue == rhs
}
