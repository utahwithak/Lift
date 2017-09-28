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

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
