//
//  XMLExportOptions.swift
//  Yield
//
//  Created by Carl Wieland on 5/1/17.
//  Copyright © 2017 Datum. All rights reserved.
//

import Foundation

class XMLExportOptions: ExportOptions {

    override init() {
        super.init()
        nullPlaceHolder = ""
    }

    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
    /// Include All tables in single file or separate file per table. Combined would be something like:
    /// <Database> 
    ///   <table name="A"> ...
    ///   </table>
    ///   <table name="B">
    ///    ....
    /// </Database>
    @objc dynamic var separateFilePerTable: Bool = false

    /// Output files pretty-printed XML
    ///
    @objc dynamic var prettyPrint: Bool = false

    /// name for the element in the XML Document
    /// something like: <`rowName` ...> ... </`rowName`>
    ///
    @objc dynamic var rowName: String = "Row"

    @objc dynamic var dataSectionName: String = "data"

    @objc dynamic var rootNodeName: String = "database"

    @objc dynamic var useNamesForElements: Bool = true

    @objc dynamic var includeProperties: Bool = true

    /// converts options into the `XMLNode.Option` int val
    ///
    var exportOptions: XMLNode.Options {
        var options: XMLNode.Options = []
        if prettyPrint {
            options.insert(.nodePrettyPrint)
        }

        return options

    }
    
}
