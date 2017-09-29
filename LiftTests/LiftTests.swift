//
//  LiftTests.swift
//  LiftTests
//
//  Created by Carl Wieland on 9/28/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import XCTest
@testable import Lift

class LiftTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testFails() {
        do {
            _ = try SQLiteCreateTableParser.parseSQL("not a correct statement")
            XCTFail("Should have thrown")
        } catch {

        }
        do {
            _ = try SQLiteCreateTableParser.parseSQL("Create Index")
            XCTFail("Should have thrown")
        } catch {

        }
        do {
            _ = try SQLiteCreateTableParser.parseSQL("Create TEMPRORARY Index")
            XCTFail("Should have thrown")
        } catch {

        }
        do {
            _ = try SQLiteCreateTableParser.parseSQL("Create TEMPRORARY Index")
            XCTFail("Should have thrown")
        } catch {

        }
        do {
            _ = try SQLiteCreateTableParser.parseSQL("Create Table(")
            XCTFail("Should have thrown")
        } catch { }

        do {
            _ = try SQLiteCreateTableParser.parseSQL("Create Table    \t(")
            XCTFail("Should have thrown")
        } catch { }
        
        do {
            _ = try SQLiteCreateTableParser.parseSQL("Create temp Table(")
            XCTFail("Should have thrown")
        } catch {

        }
    }

    func testStartOfCreateStatement() {


        do {
            let def = try SQLiteCreateTableParser.parseSQL("CREATE table t1 (column3")
            XCTAssert(!def.isTemp)
            XCTAssert(def.tableName == "t1")
        } catch {
            XCTFail("Should have created def")
        }


        do {
            let def = try SQLiteCreateTableParser.parseSQL("CREATE TEMP table   someTable   \t( \"column 2\")")

            XCTAssert(def.isTemp)
            XCTAssert(def.tableName == "someTable")
        } catch {
            XCTFail("Should have created def")
        }
        do {
            let def = try SQLiteCreateTableParser.parseSQL("CREATE TEMPorary tAbLe \"Sasdf\"\"asdtable\"( column1)")
            XCTAssert(def.isTemp)
            XCTAssert(def.tableName == "Sasdf\"\"asdtable")
        } catch {
            XCTFail("Should have created def")
        }
        do {
            let horriblName = try SQLiteCreateTableParser.parseSQL("CREATE TABLE \"(((((horrible\"\"name\"\"to\"\"parse)\"(pure, evil)")
            XCTAssert(horriblName.tableName == "(((((horrible\"\"name\"\"to\"\"parse)")
            let def = try SQLiteCreateTableParser.parseSQL("create table \"   \"\"( ( ( ( (( ( (\"\"\"(pure, evil);")
            XCTAssert(def.tableName == "   \"\"( ( ( ( (( ( (\"\"")

            let simplTab = try SQLiteCreateTableParser.parseSQL("create table \" Simple Table With Spaces \"(pure, evil);")
            XCTAssert(simplTab.tableName == " Simple Table With Spaces ")


            let badTab = try SQLiteCreateTableParser.parseSQL("create table \"  Table With ( \"\"( \\(\" )) \"\")\"\"\"\"(pure, evil);")
            XCTAssert(badTab.tableName == "  Table With ( \"\"( \\(\" )) \"\")\"\"\"")



        } catch {
            XCTFail("Should have acceppted all")

        }
    }

    func testColumnNameParsing() {
        do {
            var def = try SQLiteCreateTableParser.parseSQL("CREATE TABLE t1(\"pure\", evil)")
            XCTAssert(def.columns[0].name == "pure")
            def = try SQLiteCreateTableParser.parseSQL("CREATE TABLE t1(\"pure\"\"\", evil)")
            XCTAssert(def.columns[0].name == "pure\"\"")

            def = try SQLiteCreateTableParser.parseSQL("CREATE TABLE t1(\"pureasdf _ asdf\\();.\"\"\", evil)")
            XCTAssert(def.columns[0].name == "pureasdf _ asdf\\();.\"\"")

            def = try SQLiteCreateTableParser.parseSQL("CREATE TABLE t1(no_qoutes_just_unders, evil)")
            XCTAssert(def.columns[0].name == "no_qoutes_just_unders")
            def = try SQLiteCreateTableParser.parseSQL("CREATE TABLE t1(simpleName , evil)")
            XCTAssert(def.columns[0].name == "simpleName")

            def = try SQLiteCreateTableParser.parseSQL("CREATE TABLE t1(simple\"\"Na_me, evil)")
            XCTAssert(def.columns[0].name == "simple\"\"Na_me")


        } catch {
            XCTFail("Should have acceppted all")

        }
    }

    func testColumnTypeParsing() {
        do {
            var def = try SQLiteCreateTableParser.parseSQL("CREATE TABLE t1(\"pure\" INT, evil)")
            XCTAssert(def.columns[0].name == "pure")
            XCTAssert(def.columns[0].type == "INT")
            def = try SQLiteCreateTableParser.parseSQL("CREATE TABLE t1(\"pure\"\"\" \"Type val\", evil NULL)")
            XCTAssert(def.columns[0].name == "pure\"\"")
            XCTAssert(def.columns[0].type == "Type val")
            XCTAssert(def.columns[1].name == "evil")
            XCTAssert(def.columns[1].type == "NULL")

            def = try SQLiteCreateTableParser.parseSQL("CREATE TABLE t1(nothingElse)")
            XCTAssert(def.columns[0].name == "nothingElse")
            XCTAssert(def.columns[0].type.isEmpty)

            def = try SQLiteCreateTableParser.parseSQL("CREATE TABLE t1(\"pureasdf _ asdf\\();.\"\"\", evil)")
            XCTAssert(def.columns[0].name == "pureasdf _ asdf\\();.\"\"")

            def = try SQLiteCreateTableParser.parseSQL("CREATE TABLE t1(no_qoutes_just_unders, evil)")
            XCTAssert(def.columns[0].name == "no_qoutes_just_unders")
            def = try SQLiteCreateTableParser.parseSQL("CREATE TABLE t1(simpleName , evil)")
            XCTAssert(def.columns[0].name == "simpleName")

            def = try SQLiteCreateTableParser.parseSQL("CREATE TABLE t1(simple\"\"Na_me, evil)")
            XCTAssert(def.columns[0].name == "simple\"\"Na_me")

            def = try SQLiteCreateTableParser.parseSQL("CREATE TABLE t1(name0 type, name2 type2, name3 type3, name4 type4)")
            XCTAssert(def.columns.count == 4)
            XCTAssert(def.columns.reduce(true, { $0 && !$1.type.isEmpty}))
            XCTAssert(def.columns.reduce(true, { $0 && $1.name.rawValue.hasPrefix("name")}))

        } catch {
            XCTFail("Should have acceppted all")

        }
    }

    func testTablePrimaryKeyConstraints() {
        do {
            var def = try SQLiteCreateTableParser.parseSQL("CREATE TABLE tableT(\"some column\" INTEGER, colo2 INT, PRIMARY KEY (colo2)")
            XCTAssert(!def.tableConstraints.isEmpty)
            XCTAssert(def.tableConstraints.first is PrimaryKeyTableConstraint)
            XCTAssert(!(def.tableConstraints[0] as! PrimaryKeyTableConstraint).indexedColumns.isEmpty)
            XCTAssert((def.tableConstraints[0] as! PrimaryKeyTableConstraint).indexedColumns[0].columnName == "colo2")

            def = try SQLiteCreateTableParser.parseSQL("CREATE TABLE tableT(\"some column\" INTEGER, colo2 INT, CONSTRAINT abcd PRIMARY KEY (colo2, \"some column\")")
            XCTAssert(!def.tableConstraints.isEmpty)
            XCTAssert(def.tableConstraints.first is PrimaryKeyTableConstraint)
            XCTAssert(!(def.tableConstraints[0] as! PrimaryKeyTableConstraint).indexedColumns.isEmpty)
            XCTAssert((def.tableConstraints[0] as! PrimaryKeyTableConstraint).name == "abcd")
            XCTAssert((def.tableConstraints[0] as! PrimaryKeyTableConstraint).indexedColumns[0].columnName == "colo2")
            XCTAssert(((def.tableConstraints[0] as! PrimaryKeyTableConstraint).indexedColumns.last?.columnName.rawValue ?? "") == "some column")


            def = try SQLiteCreateTableParser.parseSQL("CREATE TABLE tableT(\"some column\" INTEGER, colo2 INT, CONSTRAINT abcd PRIMARY KEY (colo2, \"some column\") ON CONFLICT ROLLBACK")
            XCTAssert(!def.tableConstraints.isEmpty)
            XCTAssert(def.tableConstraints.first is PrimaryKeyTableConstraint)
            XCTAssert(!(def.tableConstraints[0] as! PrimaryKeyTableConstraint).indexedColumns.isEmpty)
            XCTAssert((def.tableConstraints[0] as! PrimaryKeyTableConstraint).name == "abcd")
            XCTAssert((def.tableConstraints[0] as! PrimaryKeyTableConstraint).indexedColumns[0].columnName == "colo2")
            XCTAssert(((def.tableConstraints[0] as! PrimaryKeyTableConstraint).indexedColumns.last?.columnName.rawValue ?? "") == "some column")
            XCTAssert((def.tableConstraints[0] as! PrimaryKeyTableConstraint).conflictClause != nil)
            XCTAssert((def.tableConstraints[0] as! PrimaryKeyTableConstraint).conflictClause!.resolution == .rollback)

            def = try SQLiteCreateTableParser.parseSQL("CREATE TABLE tableT(\"some column\" INTEGER, colo2 INT, CONSTRAINT abcd PRIMARY KEY (colo2, \"some column\") ON CONFLICT ROLLBACK")
            if let res = (def.tableConstraints[0] as? PrimaryKeyTableConstraint)?.conflictClause?.resolution {
                XCTAssert( res == .rollback)
            } else {
                XCTFail("Should have had a resolution")
            }

            def = try SQLiteCreateTableParser.parseSQL("CREATE TABLE tableT(\"some column\" INTEGER, colo2 INT, CONSTRAINT abcd PRIMARY KEY (colo2, \"some column\") ON CONFLICT ABORT")
            if let res = (def.tableConstraints[0] as? PrimaryKeyTableConstraint)?.conflictClause?.resolution {
                XCTAssert( res == .abort)
            } else {
                XCTFail("Should have had a resolution")
            }
            def = try SQLiteCreateTableParser.parseSQL("CREATE TABLE tableT(\"some column\" INTEGER, colo2 INT, CONSTRAINT abcd PRIMARY KEY (colo2, \"some column\") ON CONFLICT IGNORE")
            if let res = (def.tableConstraints[0] as? PrimaryKeyTableConstraint)?.conflictClause?.resolution {
                XCTAssert( res == .ignore)
            } else {
                XCTFail("Should have had a resolution")
            }

            def = try SQLiteCreateTableParser.parseSQL("CREATE TABLE tableT(\"some column\" INTEGER, colo2 INT, CONSTRAINT abcd PRIMARY KEY (colo2, \"some column\") ON CONFLICT FAIL")
            if let res = (def.tableConstraints[0] as? PrimaryKeyTableConstraint)?.conflictClause?.resolution {
                XCTAssert( res == .fail)
            } else {
                XCTFail("Should have had a resolution")
            }

            def = try SQLiteCreateTableParser.parseSQL("CREATE TABLE tableT(\"some column\" INTEGER, colo2 INT, CONSTRAINT abcd PRIMARY KEY (colo2, \"some column\") ON CONFLICT REPLACE")
            if let res = (def.tableConstraints[0] as? PrimaryKeyTableConstraint)?.conflictClause?.resolution {
                XCTAssert( res == .replace)
            } else {
                XCTFail("Should have had a resolution")
            }




        } catch {
            XCTFail("Should have acceppted all")
        }
    }

    private func checkArray<T: Equatable>(expected: [T], got: [T]) -> Bool {

        if expected.count != got.count {
            return false
        }

        var allMatch = true
        for (index, value) in got.enumerated() {
            allMatch = allMatch && value == expected[index]
        }
        return allMatch
    }


    func testUniqueTableConstraints() {
        do {
            let def = try SQLiteCreateTableParser.parseSQL("CREATE TABLE   simpleTable   \t( cola, colb, colc, cold, CONSTRAINT abcd UNIQUE ( cola, colb) ON CONFLICT ABORT, PRIMARY KEY (colc), CONSTRAINT uniqu2 UNIQUE (cold)")
            XCTAssert(def.tableName == "simpleTable")

            let constraints = def.tableConstraints

            guard constraints.count == 3 else {
                XCTFail("Not correct count")
                return
            }

            if let firstUnique = constraints[0] as? UniqueTableConstraint {
                XCTAssert(firstUnique.name == "abcd")
                XCTAssert(firstUnique.indexedColumns.count == 2)
                XCTAssert(checkArray(expected: ["cola","colb"], got: firstUnique.indexedColumns.map({ $0.columnName.rawValue })))
                if let conf = firstUnique.conflictClause {
                    XCTAssert(conf.resolution == .abort)
                } else {
                    XCTFail("Should have had a conflict clause")
                }

            } else {
                XCTFail("Invalid constraint type")
            }

            if let firstUnique = constraints[1] as? PrimaryKeyTableConstraint {

                XCTAssert(firstUnique.indexedColumns.count == 1)
                XCTAssert(checkArray(expected: ["colc"], got: firstUnique.indexedColumns.map({ $0.columnName.rawValue })))
                XCTAssert(firstUnique.conflictClause == nil)

            } else {
                XCTFail("Invalid constraint type")
            }

            if let firstUnique = constraints[2] as? UniqueTableConstraint {
                XCTAssert(firstUnique.name == "uniqu2")

                XCTAssert(firstUnique.indexedColumns.count == 1)
                XCTAssert(checkArray(expected: ["cold"], got: firstUnique.indexedColumns.map({ $0.columnName.rawValue })))
                XCTAssert(firstUnique.conflictClause == nil)
            } else {
                XCTFail("Invalid constraint type")
            }


        } catch {
            XCTFail("Should have created def")
        }
    }


    func testCheckTableExpressions() {
        do {
            let def = try SQLiteCreateTableParser.parseSQL("CREATE TABLE simpleTable(cola,colb,colc,cold,CONSTRAINT con1 CHECK ( \"(( \"\" ((\"),CONSTRAINT con2 CHECK( cola in (\"abcd)\", \"af(sd)\") or colb == 123), Constraint con3 CHECK (cold == 1234))")
            XCTAssert(def.tableName == "simpleTable")

            let constraints = def.tableConstraints

            guard constraints.count == 3 else {
                XCTFail("Invalid check constraint count")
                return
            }

            XCTAssert(constraints.reduce(true, {$0 && $1 is CheckTableConstraint}))

            

        } catch {
            XCTFail("Should have created def")
        }
    }


//    func testPerformanceExample() {
//        // This is an example of a performance test case.
//        self.measure {
//            // Put the code you want to measure the time of here.
//        }
//    }
//
}
