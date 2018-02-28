//
//  ViewParsingTests.swift
//  LiftTests
//
//  Created by Carl Wieland on 2/28/18.
//  Copyright © 2018 Datum Apps. All rights reserved.
//

import XCTest
@testable import Lift

class ViewParsingTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testSimpleParse() {
        let statement = "CREATE TEMP VIEW abcd AS SELECT * FROM SQLITE_MASTER"
        do {
            let def = try SQLiteCreateViewParser.parse(sql: statement)
            XCTAssert(def.name == "abcd")
            XCTAssert(def.isTemp)
            XCTAssert(def.selectStatement == "SELECT * FROM SQLITE_MASTER")
        } catch {
            XCTFail("Should have been able to parse")
        }
    }
    func testSimpleCParse() {
        let statement = "CREATE TEMP VIEW abcd (a, \"b c\", d)AS SELECT * FROM SQLITE_MASTER"
        do {
            let def = try SQLiteCreateViewParser.parse(sql: statement)
            XCTAssert(def.name == "abcd")
            XCTAssert(def.columns.count == 3)
            XCTAssert(def.columns[0] == "a")
            XCTAssert(def.columns[1].cleanedVersion == "b c")
            XCTAssert(def.columns[2].cleanedVersion == "d")

            XCTAssert(def.isTemp)
            XCTAssert(def.selectStatement == "SELECT * FROM SQLITE_MASTER")
        } catch {
            XCTFail("Should have been able to parse")
        }
    }
}
