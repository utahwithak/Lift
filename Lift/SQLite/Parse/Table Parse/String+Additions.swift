//
//  String+Additions.swift
//  Lift
//
//  Created by Carl Wieland on 9/29/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Foundation

extension String {
    //
    //    public var unescapeXMLString: String {
    //        var cpy = self
    //        cpy = cpy.replacingOccurrences(of:"&amp;" , with:"&" , options: .literal, range: nil)
    //        cpy = cpy.replacingOccurrences(of:"&quot;", with:"\"", options: .literal, range: nil)
    //        cpy = cpy.replacingOccurrences(of:"&#x27;", with:"'" , options: .literal, range: nil)
    //        cpy = cpy.replacingOccurrences(of:"&#39;" , with:"'" , options: .literal, range: nil)
    //        cpy = cpy.replacingOccurrences(of:"&#x92;", with:"'" , options: .literal, range: nil)
    //        cpy = cpy.replacingOccurrences(of:"&#x96;", with:"-" , options: .literal, range: nil)
    //        cpy = cpy.replacingOccurrences(of:"&gt;"  , with:">" , options: .literal, range: nil)
    //        cpy = cpy.replacingOccurrences(of:"&lt;"  , with:"<" , options: .literal, range: nil)
    //        return cpy
    //    }
    //
    //    public var xmlSafeString: String {
    //        var cpy = self
    //        cpy = cpy.replacingOccurrences(of:"&" , with:"&amp;" , options: .literal, range: nil)
    //        cpy = cpy.replacingOccurrences(of:"&quot;", with:"\"", options: .literal, range: nil)
    //        cpy = cpy.replacingOccurrences(of:"&#x27;", with:"'" , options: .literal, range: nil)
    //        cpy = cpy.replacingOccurrences(of:"&#39;" , with:"'" , options: .literal, range: nil)
    //        cpy = cpy.replacingOccurrences(of:"&#x92;", with:"'" , options: .literal, range: nil)
    //        cpy = cpy.replacingOccurrences(of:"&#x96;", with:"-" , options: .literal, range: nil)
    //        cpy = cpy.replacingOccurrences(of:"&gt;"  , with:">" , options: .literal, range: nil)
    //        cpy = cpy.replacingOccurrences(of:"&lt;"  , with:"<" , options: .literal, range: nil)
    //        return cpy
    //    }

    func CSVFormattedString(qouted: Bool, separator: String) -> String {

        let safeQoute = qouted || self.rangeOfCharacter(from: CharacterSet.newlines) != nil ||  self.contains(separator)

        let content: String
        if self.contains("\"") {
            content = self.replacingOccurrences(of: "\"", with: "\"\"")
            return safeQoute ? String(format: "\"%@\"", content) : content
        } else {
            return safeQoute ? String(format: "\"%@\"", self) : self
        }

    }

    func sqliteSafeString() -> String {
        guard let first = first else {
            return self
        }

        if (first == "\"" || first == "'" || first == "`") && balancedQoutedString() {
            return self
        }

        if first == "[" && last == "]" {
            return self
        }

        if rangeOfCharacter(from: SQLiteName.invalidChars) != nil || !CharacterSet.decimalDigits.isDisjoint(with: CharacterSet(first.unicodeScalars)) || String.SQLiteKeywords.contains(self.uppercased()) {
            var returnVal = self
            if contains("\"") {
                returnVal = self.replacingOccurrences(of: "\"", with: "\"\"")
            }
            return "\"\(returnVal)\""

        } else {
            return self
        }
    }

    private static let SQLiteKeywords = ["ABORT", "ACTION", "ADD", "AFTER", "ALL", "ALTER", "ANALYZE", "AND", "AS", "ASC", "ATTACH", "AUTOINCREMENT", "BEFORE", "BEGIN", "BETWEEN", "BY", "CASCADE", "CASE", "CAST", "CHECK", "COLLATE", "COLUMN", "COMMIT", "CONFLICT", "CONSTRAINT", "CREATE", "CROSS", "CURRENT_DATE", "CURRENT_TIME", "CURRENT_TIMESTAMP", "DATABASE", "DEFAULT", "DEFERRABLE", "DEFERRED", "DELETE", "DESC", "DETACH", "DISTINCT", "DROP", "EACH", "ELSE", "END", "ESCAPE", "EXCEPT", "EXCLUSIVE", "EXISTS", "EXPLAIN", "FAIL", "FOR", "FOREIGN", "FROM", "FULL", "GLOB", "GROUP", "HAVING", "IF", "IGNORE", "IMMEDIATE", "IN", "INDEX", "INDEXED", "INITIALLY", "INNER", "INSERT", "INSTEAD", "INTERSECT", "INTO", "IS", "ISNULL", "JOIN", "KEY", "LEFT", "LIKE", "LIMIT", "MATCH", "NATURAL", "NO", "NOT", "NOTNULL", "NULL", "OF", "OFFSET", "ON", "OR", "ORDER", "OUTER", "PLAN", "PRAGMA", "PRIMARY", "QUERY", "RAISE", "RECURSIVE", "REFERENCES", "REGEXP", "REINDEX", "RELEASE", "RENAME", "REPLACE", "RESTRICT", "RIGHT", "ROLLBACK", "ROW", "SAVEPOINT", "SELECT", "SET", "TABLE", "TEMP", "TEMPORARY", "THEN", "TO", "TRANSACTION", "TRIGGER", "UNION", "UNIQUE", "UPDATE", "USING", "VACUUM", "VALUES", "VIEW", "VIRTUAL", "WHEN", "WHERE", "WITH", "WITHOUT", "ROWID", "INTEGER", "TEXT", "BLOB", "NULL", "REAL", "FALSE", "TRUE"]

    func querySafeString() -> String {
        if (first == "\"" || first == "'" || first == "`") && balancedQoutedString() {
            return self
        }
        if first == "[" && last == "]" {
            return self
        }

        var returnVal = self
        if contains("\"") {
            returnVal = self.replacingOccurrences(of: "\"", with: "\"\"")
        }
        return "\"\(returnVal)\""
    }

    //checks starting with ( and ending with ) can have internal () and qoutes, with sqlite style double qoutes
    func isBalanced() -> Bool {
        //check if we are balanced
        var sawQoute = false
        var charStack = [Character]()
        for char in self {

            if sawQoute {
                sawQoute = false

                if char == "\"" {
                    continue // double qoute literal, skip it
                } else {
                    assert(charStack.last == "\"")
                    _ = charStack.removeLast()
                }
            }

            switch char {
            case "\"":
                if charStack.last == "(" {
                    charStack.append(char)
                } else {
                    sawQoute = true
                }

            case "(":

                if charStack.last == "\"" {
                    continue
                } else {
                    charStack.append(char)
                }

            case ")":

                if charStack.last == "(" {
                    _ = charStack.removeLast()
                }
            default:

                continue
            }
        }
        return charStack.isEmpty
    }

    /// Checks if the first char matches the last. allows for doulbe quotes
    ///
    /// - Returns: if it is balanced
    func balancedQoutedString() -> Bool {
        guard let first = first else {
            return false
        }

        guard last == first, count > 1 else {
            return false
        }

        if count == 2 {
            return true
        }

        var sawQuote = false
        for char in self.dropFirst().dropLast() {

            if char == first {
                if sawQuote {
                    sawQuote = false
                } else {
                    sawQuote = true
                }
            } else {
                if sawQuote {
                    return false
                }
            }
        }
        //There should always be an even number of quotes in a balanced string. 
        if sawQuote {
            return false
        }
        return true
    }
}
