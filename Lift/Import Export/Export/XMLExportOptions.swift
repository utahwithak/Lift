//
//  XMLExportOptions.swift
//  Yield
//
//  Created by Carl Wieland on 5/1/17.
//  Copyright © 2017 Datum. All rights reserved.
//

import Foundation

class XMLExportOptions: ExportOptions {

    /// Include All tables in single file or separate file per table. Combined would be something like:
    /// <Database> 
    ///   <tableA> ...
    ///   </tableA>
    ///   <tableB>
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

    /// use attribues on an element named `rowName`
    ///
    @objc dynamic var useAttributes: Bool = false

    @objc dynamic var rootNodeName: String = "database"

    @objc dynamic var useNamesForElements: Bool = true

    @objc dynamic var allowInvalidXML: Bool = false

    @objc dynamic var alwaysIncludeProperties: Bool = true

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
