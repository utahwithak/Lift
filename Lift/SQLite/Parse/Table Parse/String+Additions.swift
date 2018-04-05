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
        if (first == "\"" || first == "'" || first == "`") && balancedQoutedString() {
            return self
        }
        if first == "[" && last == "]" {
            return self
        }

        if rangeOfCharacter(from: SQLiteName.invalidChars) != nil {
            var returnVal = self
            if contains("\"") {
                returnVal = self.replacingOccurrences(of: "\"", with: "\"\"")
            }
            return "\"\(returnVal)\""

        } else {
            return self
        }
    }

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

        guard last == first else {
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

        return true
    }
}
