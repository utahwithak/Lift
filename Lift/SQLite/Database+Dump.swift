//
//  SQLite+Dump.swift
//  Yield
//
//  Created by Carl Wieland on 5/12/17.
//  Copyright © 2017 Datum. All rights reserved.
//

import Foundation

extension String {
    public var SQLiteEscapedString: String {
        return self.replacingOccurrences(of: "\"", with: "\"\"")
    }
}

extension Database {


    public func importDump(from path: URL) throws {
        guard let bytes = try? Data(contentsOf: path, options: .mappedIfSafe) else {

            return
        }

        try bytes.withUnsafeBytes { (u8Ptr: UnsafePointer<UInt8>) in
            let rawPtr = UnsafeMutableRawPointer(mutating: u8Ptr)

            let start = rawPtr.assumingMemoryBound(to: Int8.self)
            var statementCount = 0

            var remainder:UnsafePointer<Int8>? = UnsafePointer(start)
            var statement: OpaquePointer?
            while let remaining = remainder, sqlite3_prepare_v2(connection, remaining, -1, &statement, &remainder) == SQLITE_OK, let stmt = statement {
                statementCount += 1
                let query = Statement(connection: connection, statement: stmt)
                _ = try query.step()
                if statementCount >= 1403 {
                    let dat = Data(bytesNoCopy: UnsafeMutableRawPointer(mutating: remainder!), count: 1000, deallocator: .none)
                    if let str = String(data: dat, encoding: .utf8) {
                        print("nexts:\(str)")
                    }
                }
            }

        }

        refresh()
        

    }
    

    public func dump(query: String, to helper: DumpHelper) throws {
        var zErr: UnsafeMutablePointer<Int8>?
        helper.database = self
        var weakSelf = helper
        var rc = sqlite3_exec(connection, query, dump_callback, &weakSelf, &zErr)
        if rc == SQLITE_CORRUPT {
            helper.handle.write( "/****** CORRUPTION ERROR *******/\n")
            if let errPtr = zErr {
                let str = String(cString: errPtr)
                helper.handle.write( "/****** \(str) ******/\n")
                sqlite3_free(zErr);
                zErr = nil
            }
            let zQ2 = "\(query) ORDER BY rowid DESC"
            rc = sqlite3_exec(connection, zQ2, dump_callback, &weakSelf, &zErr);
            if rc != SQLITE_OK, let errPtr = zErr {
                helper.handle.write( "/****** ERROR: \(String(cString: errPtr)) ******/\n");
            }

            sqlite3_free(zErr);
        }
    }

    /*
     ** Return a list of pointers to strings which are the names of all
     ** columns in table zTab.   The memory to hold the names is dynamically
     ** allocated and must be released by the caller using a subsequent call
     ** to freeColumnList().
     **
     ** The azCol[0] entry is usually NULL.  However, if zTab contains a rowid
     ** value that needs to be preserved, then azCol[0] is filled in with the
     ** name of the rowid column.
     **
     ** The first regular column in the table is azCol[1].  The list is terminated
     ** by an entry with azCol[i]==0.
     */
    fileprivate func tableColumnList(for table: String, options: DumpHelper) -> [String?]? {
        var azCol: [String?] = [nil]
        var nPK = 0;       /* Number of PRIMARY KEY columns seen */
        var isIPK = false;     /* True if one PRIMARY KEY column of type INTEGER */
        var preserveRowid = options.preserveRowId

        var pStmt: OpaquePointer?
        var zSql = "PRAGMA table_info=\"\(table.SQLiteEscapedString)\""
        var rc = sqlite3_prepare_v2(connection, zSql, -1, &pStmt, nil)

        guard rc == SQLITE_OK else {
            return nil
        }

        while sqlite3_step(pStmt) == SQLITE_ROW {
            if let columnName = sqlite3_column_text(pStmt, 1) {
                azCol.append(String(cString: columnName) )
            } else {
                azCol.append(nil)
            }

            if sqlite3_column_int(pStmt, 5) == 1{
                nPK += 1
                if nPK == 1 && String(cString: sqlite3_column_text(pStmt,2)) ==  "INTEGER" {
                    isIPK = true;
                } else {
                    isIPK = false;
                }
            }
        }
        sqlite3_finalize(pStmt);

        /* The decision of whether or not a rowid really needs to be preserved
         ** is tricky.  We never need to preserve a rowid for a WITHOUT ROWID table
         ** or a table with an INTEGER PRIMARY KEY.  We are unable to preserve
         ** rowids on tables where the rowid is inaccessible because there are other
         ** columns in the table named "rowid", "_rowid_", and "oid".
         */
        if preserveRowid && isIPK {
            /* If a single PRIMARY KEY column with type INTEGER was seen, then it
             ** might be an alise for the ROWID.  But it might also be a WITHOUT ROWID
             ** table or a INTEGER PRIMARY KEY DESC column, neither of which are
             ** ROWID aliases.  To distinguish these cases, check to see if
             ** there is a "pk" entry in "PRAGMA index_list".  There will be
             ** no "pk" index if the PRIMARY KEY really is an alias for the ROWID.
             */
            zSql = "SELECT 1 FROM pragma_index_list(\"\(table.SQLiteEscapedString)\") WHERE origin='pk'";
            rc = sqlite3_prepare_v2(connection, zSql, -1, &pStmt, nil);

            if rc != SQLITE_OK {
                return nil
            }

            rc = sqlite3_step(pStmt);
            sqlite3_finalize(pStmt);
            preserveRowid = rc == SQLITE_ROW;
        }

        if( preserveRowid ){
            /* Only preserve the rowid if we can find a name to use for the
             ** rowid */
            let azRowid = [ "rowid", "_rowid_", "oid" ]

            for rowid in azRowid {

                if azCol.index(where: {$0 == rowid }) == nil {
                    /* At this point, we know that azRowid[j] is not the name of any
                     ** ordinary column in the table.  Verify that azRowid[j] is a valid
                     ** name for the rowid before adding it to azCol[0].  WITHOUT ROWID
                     ** tables will fail this last check */
                    rc = sqlite3_table_column_metadata(connection, nil ,table, rowid, nil, nil, nil, nil, nil);
                    if rc == SQLITE_OK {
                        azCol[0] = rowid
                    }
                    break
                }
            }
        }
        return azCol;
    }
}


class DumpHelper {
    let handle: Writer
    var errorCount = 0
    var writableSchema = false
    var preserveRowId = true

    var database: Database!
    let progressHandler: (String) -> Void

    init(handle: Writer, progressHandler: @escaping (String)-> Void) {
        self.handle = handle
        handle.open()
        self.progressHandler = progressHandler
    }
    
    deinit {
        handle.close()
    }
}



fileprivate func dump_callback( pArg: UnsafeMutableRawPointer?, nArg: Int32, azArg:UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?, azNotUsed:UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?) -> Int32 {

    guard let helper = pArg?.assumingMemoryBound(to: DumpHelper.self).pointee else {
        return 1
    }

    guard nArg == 3, let tbl = azArg?[0], let tpe = azArg?[1], let sql = azArg?[2] else { return 1 }

    let zTable = String(cString: tbl)
    let zType = String(cString: tpe)
    let zSql = String(cString: sql)
    do {
        if zTable == "sqlite_sequence" {
            helper.handle.write( "DELETE FROM sqlite_sequence;\n")
        } else if sqlite3_strglob("sqlite_stat?", zTable) == 0 {
            helper.handle.write( "ANALYZE sqlite_master;\n")
        } else if zTable.hasPrefix("sqlite_") {
            return 0;
        } else if zSql.hasPrefix("CREATE VIRTUAL TABLE") {

            if !helper.writableSchema {
                helper.handle.write( "PRAGMA writable_schema=ON;\n")
                helper.writableSchema = true
            }
            let zIns = "INSERT INTO sqlite_master(type,name,tbl_name,rootpage,sql) VALUES('table','\(zTable.SQLiteEscapedString)','\(zTable.SQLiteEscapedString)',0,'\(zSql.SQLiteEscapedString)');\n"
            helper.handle.write( zIns)
            return 0;
        } else {
            if( sqlite3_strglob("CREATE TABLE ['\"]*", zSql)==0 ){
                let trimmed = zSql.replacingOccurrences(of: "CREATE TABLE ", with: "")
                helper.handle.write( "CREATE TABLE IF NOT EXISTS \(trimmed);\n");
            }else{
                helper.handle.write( "\(zSql);\n")
            }

        }

        if zType == "table" {
            var sSelect = ""
            var sTable = ""

            guard let azCol = helper.database.tableColumnList(for: zTable, options: helper) else {
                helper.errorCount += 1
                return 0;
            }
            let colString = azCol.compactMap({$0}).map({"\"\($0.SQLiteEscapedString)\""}).joined(separator: ",")

            /* Always quote the table name, even if it appears to be pure ascii,
             ** in case it is a keyword. Ex:  INSERT INTO "table" ... */
            sTable.append("\"\(zTable.SQLiteEscapedString)\"")

            /* If preserving the rowid, add a column list after the table name.
             ** In other words:  "INSERT INTO tab(rowid,a,b,c,...) VALUES(...)"
             ** instead of the usual "INSERT INTO tab VALUES(...)".
             */
            if azCol[0] != nil {
                sTable.append("(\(colString))")
            }

            /* Build an appropriate SELECT statement */

            sSelect = "SELECT \(colString) FROM \"\(zTable.SQLiteEscapedString)\""
            helper.progressHandler(zTable)
            let query = try Query(connection: helper.database.connection, query: sSelect)

            try query.processRows(handler: { rowData in
                if rowData.isEmpty {
                    return
                }
                
                let strVals = rowData.map {
                    switch $0 {
                    case .null:
                        return "NULL"
                    case .text(let str):
                        return "\"\(str.SQLiteEscapedString)\""
                    case .integer(let int):
                        return "\(int)"
                    case .float(let dbl):
                        return "\(dbl)"
                    case .blob(let data):
                        return "X'\(data.hexEncodedString())'"
                    }
                }.joined(separator: ",")

                helper.handle.write( "INSERT INTO \(sTable) VALUES(\(strVals));\n")



                
            })
            
        }
    } catch {
        print("Dump fail:\(error)")
        helper.errorCount += 1
    }
    return 0;
    
}
