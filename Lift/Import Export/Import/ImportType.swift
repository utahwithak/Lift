//
//  ImportType.swift
//  Lift
//
//  Created by Carl Wieland on 1/2/18.
//  Copyright © 2018 Datum Apps. All rights reserved.
//

import Foundation
import SwiftXLSX

enum ImportType {

    case failed
    case xml(XMLDocument)
    case json(Any)
    case sqlite(Database)
    case xlsx(XLSXDocument)
    case text(String, String.Encoding)

    static func importType(for url: URL) -> ImportType {
        SQLiteDocumentPresenter.addPresenters(for: url)
        if let db = try? Database(type: .aux(path: url)) {
            db.refresh()
            if !db.tables.isEmpty {
                return .sqlite(db)
            }
        }

        guard var data = try? Data(contentsOf: url, options: .mappedIfSafe) else {
            return .failed
        }

        do {
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            return .json(json)

        } catch {
            print("file's not JSON")
        }

        if let workbook = try? XLSXDocument(path: url) {
            return .xlsx(workbook)
        } else if let doc = try? XMLDocument(contentsOf: url, options: []) {
            return .xml(doc)
        }

        let len = data.count
        let simpleString = data.withUnsafeMutableBytes { ptr -> ImportType? in

            guard let unsafePtr = UnsafeMutableRawPointer(ptr.baseAddress) else {
                return nil
            }
            if let str = String(bytesNoCopy: unsafePtr, length: len, encoding: .utf8, freeWhenDone: false) {
                return .text(str, .utf8)
            } else if let rom = String(bytesNoCopy: unsafePtr, length: len, encoding: .macOSRoman, freeWhenDone: false) {
                return .text(rom, .macOSRoman)
            }
            return nil
        }

        if let type = simpleString {
            return type
        } else {
            return .failed
        }
    }

}
