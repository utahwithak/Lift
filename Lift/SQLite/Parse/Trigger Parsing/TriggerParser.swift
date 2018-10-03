//
//  TriggerParser.swift
//  Lift
//
//  Created by Carl Wieland on 10/2/18.
//  Copyright © 2018 Datum Apps. All rights reserved.
//

import Foundation

final class TriggerParser {
    private init() {}

    struct Trigger {
        enum Timing {
            case before
            case after
            case insteadOf
            case unspecified
        }

        enum Action {
            case delete
            case insert
            case update(columns: [String]?)
        }

        var name = ""
        var timing: Timing = .unspecified
        var action: Action = .delete
        var tableName = ""
        var forEachRow = false
        var whenExpression: String?
        var sql: String = ""
    }

    ///https://www.sqlite.org/lang_createtrigger.html
    static func parseTrigger(from sql: String) throws -> Trigger {
        let stringScanner = Scanner(string: sql)
        stringScanner.caseSensitive = false

        guard stringScanner.scanString("CREATE ", into: nil) else {
            throw ParserError.notCreateStatement
        }
        guard stringScanner.scanString("TRIGGER ", into: nil) else {
            throw ParserError.notATableStatement
        }

        var trigger = Trigger()
        trigger.name = try SQLiteCreateTableParser.parseStringOrName(from: stringScanner)

        if stringScanner.scanString("BEFORE ", into: nil) {
            trigger.timing = .before
        } else if stringScanner.scanString("AFTER ", into: nil) {
            trigger.timing = .after
        } else if stringScanner.scanString("INSTEAD ", into: nil) && stringScanner.scanString("OF", into: nil) {
            trigger.timing = .insteadOf
        }

        if stringScanner.scanString("DELETE ", into: nil) {
            trigger.action = .delete
        } else if stringScanner.scanString("INSERT ", into: nil) {
            trigger.action = .insert
        } else if stringScanner.scanString("UPDATE ", into: nil) {
            if stringScanner.scanString("OF", into: nil) {
                var names = [String]()
                repeat {
                    let name = try SQLiteCreateTableParser.parseStringOrName(from: stringScanner)
                    names.append(name)
                } while stringScanner.scanString(", ", into: nil)

            } else {
                trigger.action = .update(columns: nil)
            }
        } else {
            throw ParserError.unexpectedError("Expected ACTION, found:\(String(sql.dropFirst(stringScanner.scanLocation)))")
        }

        guard stringScanner.scanString("ON", into: nil) else {
            throw ParserError.unexpectedError("Expected ON, found:\(String(sql.dropFirst(stringScanner.scanLocation)))")
        }

        trigger.tableName = try SQLiteCreateTableParser.parseStringOrName(from: stringScanner)

        if stringScanner.scanString("FOR", into: nil) {
            guard stringScanner.scanString("EACH", into: nil) else {
                throw ParserError.unexpectedError("Expected EACH, found:\(String(sql.dropFirst(stringScanner.scanLocation)))")

            }
            guard stringScanner.scanString("ROW", into: nil) else {
                throw ParserError.unexpectedError("Expected ROW, found:\(String(sql.dropFirst(stringScanner.scanLocation)))")

            }
            trigger.forEachRow = true
        }

        if stringScanner.scanString("WHEN", into: nil) {
            var whenExp: NSString?
            guard stringScanner.scanUpTo("BEGIN", into: &whenExp) else {
                throw ParserError.unexpectedError("Expected to parse to BEGIN, found:\(String(sql.dropFirst(stringScanner.scanLocation)))")
            }
            trigger.whenExpression = whenExp as String?
        }

        guard stringScanner.scanString("BEGIN", into: nil) else {
            throw ParserError.unexpectedError("Expected BEGIN, found:\(String(sql.dropFirst(stringScanner.scanLocation)))")
        }

        var triggerStatments: NSString?
        guard stringScanner.scanUpTo("END", into: &triggerStatments), let statements = triggerStatments as String? else {
            throw ParserError.unexpectedError("Expected to parse to END, found:\(String(sql.dropFirst(stringScanner.scanLocation)))")
        }

        trigger.sql = statements

        guard stringScanner.scanString("END", into: nil) else {
            throw ParserError.unexpectedError("Expected END, found:\(String(sql.dropFirst(stringScanner.scanLocation)))")
        }

        return trigger
    }
}
