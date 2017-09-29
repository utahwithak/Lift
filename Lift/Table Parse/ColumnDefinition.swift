//
//  ColumnDefinition.swift
//  Lift
//
//  Created by Carl Wieland on 9/28/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Foundation


class ColumnDefinition {

    public var name: ColumnName

    public var type = ""

    init?(from scanner: Scanner) throws {

        let colName = try SQLiteCreateTableParser.parseStringOrName(from: scanner)
        if colName.isEmpty {
            return nil
        }
        name = ColumnName(rawValue: colName)
        type = try SQLiteCreateTableParser.parseStringOrName(from: scanner)


        
    }



   

}
