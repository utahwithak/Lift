//
//  SQLiteSyntaxHighlighter.swift
//  Lift
//
//  Created by Carl Wieland on 10/4/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Cocoa

class SQLiteSyntaxHighlighter {

    private static let SQLiteKeywords: [String] = ["ABORT", "ACTION", "ADD", "AFTER", "ALL", "ALTER", "ANALYZE", "AND", "AS", "ASC", "ATTACH", "AUTOINCREMENT", "BEFORE", "BEGIN", "BETWEEN", "BY", "CASCADE", "CASE", "CAST", "CHECK", "COLLATE", "COLUMN", "COMMIT", "CONFLICT", "CONSTRAINT", "CREATE", "CROSS", "CURRENT_DATE", "CURRENT_TIME", "CURRENT_TIMESTAMP", "DATABASE", "DEFAULT", "DEFERRABLE", "DEFERRED", "DELETE", "DESC", "DETACH", "DISTINCT", "DROP", "EACH", "ELSE", "END", "ESCAPE", "EXCEPT", "EXCLUSIVE", "EXISTS", "EXPLAIN", "FAIL", "FOR", "FOREIGN", "FROM", "FULL", "GLOB", "GROUP", "HAVING", "IF", "IGNORE", "IMMEDIATE", "IN", "INDEX", "INDEXED", "INITIALLY", "INNER", "INSERT", "INSTEAD", "INTERSECT", "INTO", "IS", "ISNULL", "JOIN", "KEY", "LEFT", "LIKE", "LIMIT", "MATCH", "NATURAL", "NO", "NOT", "NOTNULL", "NULL", "OF", "OFFSET", "ON", "OR", "ORDER", "OUTER", "PLAN", "PRAGMA", "PRIMARY", "QUERY", "RAISE", "RECURSIVE", "REFERENCES", "REGEXP", "REINDEX", "RELEASE", "RENAME", "REPLACE", "RESTRICT", "RIGHT", "ROLLBACK", "ROW", "SAVEPOINT", "SELECT", "SET", "TABLE", "TEMP", "TEMPORARY", "THEN", "TO", "TRANSACTION", "TRIGGER", "UNION", "UNIQUE", "UPDATE", "USING", "VACUUM", "VALUES", "VIEW", "VIRTUAL", "WHEN", "WHERE", "WITH", "WITHOUT", "ROWID"]

    private let firstString = "'"
    private let secondString = "\""
    private let singleLineComment = "--"
    private let beginFirstMultiLineComment = "/*"
    private let endFirstMultiLineComment = "*/"
    private let keywords = Set<String>(SQLiteSyntaxHighlighter.SQLiteKeywords)

    public var autocompleteWords = Set<String>()

    private let letterCharacterSet = CharacterSet.letters
    private let nameCharacterSet: CharacterSet = {
        return CharacterSet.letters.union(CharacterSet(charactersIn: "_"))
    }()

    private let keywordEndCharacterSet: CharacterSet = {
        var temporaryCharacterSet = CharacterSet.whitespacesAndNewlines
        temporaryCharacterSet.formUnion(CharacterSet.symbols)
        temporaryCharacterSet.formUnion(CharacterSet.punctuationCharacters)
        temporaryCharacterSet.remove(charactersIn: "_-") // common separators in variable names
        return temporaryCharacterSet
    }()

    private let numberCharacterSet = CharacterSet(charactersIn: "0123456789.")

    private let decimalPoint = ".".utf16.first

    // Colors
    public var commandsColor: [NSAttributedString.Key: NSColor] = [.foregroundColor: NSColor(calibratedRed: 0.031, green: 0.0, blue: 0.855, alpha: 1.0)]

    public var commentsColor: [NSAttributedString.Key: NSColor]  = [.foregroundColor: NSColor(calibratedRed: 0.0, green: 0.45, blue: 0.0, alpha: 1.0)]

    public var instructionsColor: [NSAttributedString.Key: NSColor]  = [.foregroundColor: NSColor(calibratedRed: 0.45, green: 0.45, blue: 0.45, alpha: 1.0)]

    public var keywordsColor: [NSAttributedString.Key: NSColor]  = [.foregroundColor: NSColor(calibratedRed: 0.737, green: 0.0, blue: 0.647, alpha: 1.0)]

    public var autocompleteWordsColor: [NSAttributedString.Key: NSColor]  = [.foregroundColor: NSColor(calibratedRed: 0.84, green: 0.41, blue: 0.006, alpha: 1.0)]

    public var stringsColor: [NSAttributedString.Key: NSColor]  = [.foregroundColor: NSColor(calibratedRed: 0.804, green: 0.071, blue: 0.153, alpha: 1.0)]

    public var variablesColor: [NSAttributedString.Key: NSColor]  = [.foregroundColor: NSColor(calibratedRed: 0.73, green: 0.0, blue: 0.74, alpha: 1.0)]

    public var attributesColor: [NSAttributedString.Key: NSColor]  = [.foregroundColor: NSColor(calibratedRed: 0.50, green: 0.5, blue: 0.2, alpha: 1.0)]

    public var lineHighlightColor: [NSAttributedString.Key: NSColor]  = [.backgroundColor: NSColor(calibratedRed: 0.96, green: 0.96, blue: 0.71, alpha: 1.0)]

    public var numbersColor: [NSAttributedString.Key: NSColor]  = [.foregroundColor: NSColor(calibratedRed: 0.031, green: 0.0, blue: 0.855, alpha: 1.0)]

    private var layoutManager: NSLayoutManager?

    private var highlightString: NSMutableAttributedString?

    private let secondStringMatcher: NSRegularExpression?
    private let firstStringMatcher: NSRegularExpression?

    init(for textView: NSTextView) {
        layoutManager = textView.layoutManager

        secondStringMatcher = try? NSRegularExpression(pattern: String(format: "%@[^%@\\\\\\r\\n]*+(?:\\\\(?:.|$)[^%@\\\\]*+)*+%@", secondString, secondString, secondString, secondString), options: [])
        firstStringMatcher = try? NSRegularExpression(pattern: String(format: "%@[^%@\\\\\\r\\n]*+(?:\\\\(?:.|$)[^%@\\\\\\r\\n]*+)*+%@", firstString, self.firstString, firstString, firstString), options: [])

        NotificationCenter.default.addObserver(self, selector: #selector(textDidChange), name: NSText.didChangeNotification, object: textView)

    }

    @objc dynamic func textDidChange(notification: NSNotification) {
        guard let textView = notification.object as? NSTextView else {
            return
        }

        highlight(textView)
    }

    func highlight(_ textView: NSTextView) {
        guard let layoutManager = textView.layoutManager, let visibleRect = textView.enclosingScrollView?.contentView.documentVisibleRect,
            let container = textView.textContainer else {
                return
        }

        let visibleRange = layoutManager.glyphRange(forBoundingRect: visibleRect, in: container)
        let beginningOfFirstVisibleLine = (textView.string as NSString).lineRange(for: NSRange(location: visibleRange.location, length: 0)).location
        let endOfLastVisibleLine = NSMaxRange((completeString as NSString).lineRange(for: NSRange(location: NSMaxRange(visibleRange), length: 0)))
        recolor(range: NSRange(location: beginningOfFirstVisibleLine, length: endOfLastVisibleLine - beginningOfFirstVisibleLine))

    }

    var completeString: String {
        return layoutManager?.textStorage?.string ?? ""
    }

    func removeColors(from range: NSRange) {
        layoutManager?.removeTemporaryAttribute(.foregroundColor, forCharacterRange: range)
    }

    func removeAllColors() {
        let wholeRange = NSRange(location: 0, length: (completeString as NSString).length)
        removeColors(from: wholeRange)
    }

    func setColor(_ colorDict: [NSAttributedString.Key: NSColor], for range: NSRange) {
        layoutManager?.setTemporaryAttributes(colorDict, forCharacterRange: range)
        highlightString?.setAttributes(colorDict, range: range)
    }

    func recolorAll() {
        let wholeRange = NSRange(location: 0, length: (completeString as NSString).length)
        recolor(range: wholeRange)
    }

    func recolor(range: NSRange) {

        // setup
        let documentString =  completeString as NSString
        let documentStringLength = documentString.length
        let effectiveRange = range
        var searchSyntaxLength = 0
        var colorStartLocation = 0, colorEndLocation = 0, endOfLine = 0
        var queryLocation = 0

        // setup working locations based on the effective range
        let rangeLocation = effectiveRange.location
        let maxRangeLocation = NSMaxRange(effectiveRange)

        // assign range string
        let rangeString = documentString.substring(with: effectiveRange)
        let rangeStringLength = (rangeString as NSString).length

        guard rangeStringLength != 0 else {
            return
        }

        // allocate the range scanner
        let rangeScanner = Scanner(string: rangeString)
        rangeScanner.charactersToBeSkipped = nil

        // allocate the document scanner
        let documentScanner = Scanner(string: documentString as String)
        documentScanner.charactersToBeSkipped = nil

        // unColor the range
        removeColors(from: effectiveRange)

        rangeScanner.scanLocation = 0

        // scan range to end
        while !rangeScanner.isAtEnd {

            // scan up to a number character
            rangeScanner.scanUpToCharacters(from: numberCharacterSet, into: nil)
            colorStartLocation = rangeScanner.scanLocation

            // scan to number end
            rangeScanner.scanCharacters(from: numberCharacterSet, into: nil)
            colorEndLocation = rangeScanner.scanLocation

            if colorStartLocation == colorEndLocation {
                break
            }

            // don't Color if preceding character is a letter.
            // this prevents us from Coloring numbers in variable names,
            queryLocation = colorStartLocation + rangeLocation
            if queryLocation > 0, let testCharacter = Unicode.Scalar((documentString as NSString).character(at: queryLocation - 1)) {

                // numbers can occur in variable, class and function names
                // eg: var_1 should not be Colored as a number

                if nameCharacterSet.contains(testCharacter) {
                    continue
                }
            }

            // don't Color a trailing decimal point as some languages may use it as a line terminator
            if colorEndLocation > 0 {
                queryLocation = colorEndLocation - 1

                if (rangeString as NSString).character(at: queryLocation) == decimalPoint {
                    colorEndLocation -= 1
                }
            }

            setColor(numbersColor, for: NSRange(location: colorStartLocation + rangeLocation, length: colorEndLocation - colorStartLocation))
        }

        //
        // Keywords
        //

        if !keywords.isEmpty {

            // reset scanner
            rangeScanner.scanLocation = 0

            // scan range to end
            while !rangeScanner.isAtEnd {
                rangeScanner.scanUpToCharacters(from: letterCharacterSet, into: nil)
                colorStartLocation = rangeScanner.scanLocation
                if (colorStartLocation + 1) < rangeStringLength {
                    rangeScanner.scanLocation = colorStartLocation + 1
                }
                rangeScanner.scanUpToCharacters(from: keywordEndCharacterSet, into: nil)
                colorEndLocation = rangeScanner.scanLocation

                if colorEndLocation > rangeStringLength || colorStartLocation == colorEndLocation {
                    break
                }

                let keywordTestString = documentString.substring(with: NSRange(location: colorStartLocation + rangeLocation, length: colorEndLocation - colorStartLocation)).uppercased()

                if keywords.contains(keywordTestString) {
                    setColor(keywordsColor, for: NSRange(location: colorStartLocation + rangeLocation, length: rangeScanner.scanLocation - colorStartLocation))
                }
            }

        }

        //
        // Autocomplete
        //
        if !autocompleteWords.isEmpty {

            rangeScanner.scanLocation = 0

            while !rangeScanner.isAtEnd {
                rangeScanner.scanUpToCharacters(from: letterCharacterSet, into: nil)
                colorStartLocation = rangeScanner.scanLocation
                if (colorStartLocation + 1) < rangeStringLength {
                    rangeScanner.scanLocation = colorStartLocation + 1
                }
                rangeScanner.scanUpToCharacters(from: keywordEndCharacterSet, into: nil)
                colorEndLocation = rangeScanner.scanLocation

                if colorEndLocation > rangeStringLength || colorStartLocation == colorEndLocation {
                    break
                }

                let autocompleteTestString = documentString.substring(with: NSRange(location: colorStartLocation + rangeLocation, length: colorEndLocation - colorStartLocation))

                if autocompleteWords.contains(autocompleteTestString) {
                    setColor(autocompleteWordsColor, for: NSRange(location: colorStartLocation + rangeLocation, length: rangeScanner.scanLocation - colorStartLocation))
                }
            }

        }

        //
        //
        // Second string, first pass
        //

        if let matcher = secondStringMatcher {
            matcher.enumerateMatches(in: rangeString, options: .reportProgress, range: NSRange(location: 0, length: (rangeString as NSString).length - 1), using: { (result, _, _) in
                guard let foundRange = result?.range, foundRange.location != NSNotFound && foundRange.length > 0 else {
                    return
                }

                self.setColor(stringsColor, for: NSRange(location: foundRange.location + rangeLocation, length: foundRange.length))
            })
        }

        //
        // First string
        //

        if let matcher = firstStringMatcher {
            matcher.enumerateMatches(in: rangeString, options: .reportProgress, range: NSRange(location: 0, length: (rangeString as NSString).length - 1), using: { (result, _, _) in
                guard let foundRange = result?.range, foundRange.location != NSNotFound && foundRange.length > 0 else {
                    return
                }

                self.setColor(stringsColor, for: NSRange(location: foundRange.location + rangeLocation, length: foundRange.length))
            })
        }

                    //
                    // Color single-line comments

                // reset scanner
                rangeScanner.scanLocation = 0
                searchSyntaxLength = (singleLineComment as NSString).length

                // scan range to end
                while !rangeScanner.isAtEnd {

                    // scan for comment
                    rangeScanner.scanUpTo(singleLineComment, into: nil)
                    colorStartLocation = rangeScanner.scanLocation

                    var colorize = true
                    // If the comment is within an already Colored string then disregard it
                    if colorStartLocation + rangeLocation + searchSyntaxLength < documentStringLength {
                        if let attributes = layoutManager?.temporaryAttributes(atCharacterIndex: colorStartLocation + rangeLocation, effectiveRange: nil), (stringsColor as NSDictionary).isEqual(attributes) {
                            if colorStartLocation < maxRangeLocation {
                                rangeScanner.scanLocation = colorStartLocation + 1

                            }
                            colorize = false
                        }
                    }

                    // this is a single line comment so we can scan to the end of the line
                    endOfLine = NSMaxRange((rangeString as NSString).lineRange(for: NSRange(location: colorStartLocation, length: 0)))
                    rangeScanner.scanLocation = endOfLine
                    if colorize {
                        // Color the comment
                        setColor(commentsColor, for: NSRange(location: colorStartLocation + rangeLocation, length: rangeScanner.scanLocation - colorStartLocation))
                    }
                }

                    //
                    // Second string, second pass
                    //
        if let matcher = secondStringMatcher {
            matcher.enumerateMatches(in: rangeString, options: .reportProgress, range: NSRange(location: 0, length: (rangeString as NSString).length), using: { (result, _, _) in
                guard let foundRange = result?.range, foundRange.location != NSNotFound && foundRange.length > 0 else {
                    return
                }

                if let attributes = layoutManager?.temporaryAttributes(atCharacterIndex: foundRange.location + rangeLocation, effectiveRange: nil), (attributes as NSDictionary).isEqual(commentsColor) || (attributes as NSDictionary).isEqual(stringsColor) {
                    return
                }

                self.setColor(stringsColor, for: NSRange(location: foundRange.location + rangeLocation, length: foundRange.length))
            })

        }

    }
}
