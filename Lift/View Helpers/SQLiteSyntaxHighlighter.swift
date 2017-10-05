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
    private let firstSingleLineComment = "--"
    private let beginFirstMultiLineComment = "/*"
    private let endFirstMultiLineComment = "*/"
    private let keywords = Set<String>(SQLiteSyntaxHighlighter.SQLiteKeywords)

    public var autocompleteWords = Set<String>()

    private let letterCharacterSet = CharacterSet.letters
    private let nameCharacterSet: CharacterSet = {
        return CharacterSet.letters.union(CharacterSet(charactersIn: "_"))
    }()

    private let keywordStartCharacterSet: CharacterSet = {
        let firsts = SQLiteSyntaxHighlighter.SQLiteKeywords.flatMap { $0.first }.map{ String($0) }
        var uniques = Set<String>(firsts)
        uniques.formUnion(firsts.map { $0.lowercased() })
        let joined = uniques.sorted().joined()
        return CharacterSet(charactersIn: joined)
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
    public var commandsColor: [NSAttributedStringKey: NSColor] = [.foregroundColor: NSColor(calibratedRed:0.031, green:0.0, blue:0.855, alpha:1.0)]

    public var commentsColor: [NSAttributedStringKey: NSColor]  = [.foregroundColor: NSColor(calibratedRed:0.0, green:0.45, blue:0.0, alpha:1.0)]

    public var instructionsColor: [NSAttributedStringKey: NSColor]  = [.foregroundColor: NSColor(calibratedRed:0.45, green:0.45, blue:0.45, alpha:1.0)]

    public var keywordsColor: [NSAttributedStringKey: NSColor]  = [.foregroundColor: NSColor(calibratedRed:0.737, green:0.0, blue:0.647, alpha:1.0)]

    public var autocompleteWordsColor: [NSAttributedStringKey: NSColor]  = [.foregroundColor: NSColor(calibratedRed:0.84, green:0.41, blue:0.006, alpha:1.0)]

    public var stringsColor: [NSAttributedStringKey: NSColor]  = [.foregroundColor: NSColor(calibratedRed:0.804, green:0.071, blue:0.153, alpha:1.0)]

    public var variablesColor: [NSAttributedStringKey: NSColor]  = [.foregroundColor: NSColor(calibratedRed:0.73, green:0.0, blue:0.74, alpha:1.0)]

    public var attributesColor: [NSAttributedStringKey: NSColor]  = [.foregroundColor: NSColor(calibratedRed:0.50, green:0.5, blue:0.2, alpha:1.0)]

    public var lineHighlightColor: [NSAttributedStringKey: NSColor]  = [.backgroundColor:NSColor(calibratedRed:0.96, green:0.96, blue:0.71, alpha:1.0)]

    public var numbersColor: [NSAttributedStringKey: NSColor]  = [.foregroundColor: NSColor(calibratedRed:0.031, green:0.0, blue:0.855, alpha:1.0)];


    private var layoutManager: NSLayoutManager?

    private var highlightString: NSMutableAttributedString?


    init(for textView: NSTextView) {
        layoutManager = textView.layoutManager
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
        let beginningOfFirstVisibleLine = (textView.string as NSString).lineRange(for: NSRange(location: visibleRange.location,length: 0)).location
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

    func setColor(_ colorDict: [NSAttributedStringKey: NSColor], for range: NSRange) {
        layoutManager?.setTemporaryAttributes(colorDict, forCharacterRange: range)
        highlightString?.setAttributes(colorDict, range: range)
    }


    func recolor(range: NSRange) {

        // setup
        let documentString =  completeString as NSString
        let documentStringLength = documentString.length
        var effectiveRange = range;
        var rangeOfLine = NSRange(location: 0, length:0);
        var searchRange = NSRange(location: 0, length: 0);
        var searchSyntaxLength = 0;
        var colorStartLocation = 0, colorEndLocation = 0, endOfLine = 0;
        var colorLength = 0
        var endLocationInMultiLine = 0
        var beginLocationInMultiLine = 0
        var queryLocation = 0
        var testCharacter = unichar(0)

        // trace
        //NSLog(@"rangeToRecolor location %i length %i", rangeToReColor.location, rangeToReColor.length);

        // adjust effective range
        //
        // When multiline strings are Colored we need to scan backwards to
        // find where the string might have started if it's "above" the top of the screen.
        //
        let beginFirstStringInMultiLine = documentString.range(of: firstString, options: .backwards, range: NSRange(location:0, length: effectiveRange.location)).location

//        if beginFirstStringInMultiLine != NSNotFound && [[firstLayoutManager temporaryAttributesAtCharacterIndex:beginFirstStringInMultiLine effectiveRange:NULL] isEqualToDictionary:stringsColor]) {
//            NSInteger startOfLine = [documentString lineRangeForRange:NSMakeRange(beginFirstStringInMultiLine, 0)].location;
//            effectiveRange = NSMakeRange(startOfLine, rangeToReColor.length + (rangeToReColor.location - startOfLine));
//        }
        // setup working locations based on the effective range
        var rangeLocation = effectiveRange.location
        var maxRangeLocation = NSMaxRange(effectiveRange);

        // assign range string
        let rangeString = documentString.substring(with: effectiveRange)
        let rangeStringLength = (rangeString as NSString).length

        guard rangeStringLength != 0 else {
            return;
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
                break;
            }

            // don't Color if preceding character is a letter.
            // this prevents us from Coloring numbers in variable names,
            queryLocation = colorStartLocation + rangeLocation;
            if queryLocation > 0, let testCharacter = Unicode.Scalar((documentString as NSString).character(at: queryLocation - 1)) {

                // numbers can occur in variable, class and function names
                // eg: var_1 should not be Colored as a number

                if nameCharacterSet.contains(testCharacter) {
                    continue;
                }
            }

                // don't Color a trailing decimal point as some languages may use it as a line terminator
                if colorEndLocation > 0 {
                    queryLocation = colorEndLocation - 1;

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
                    rangeScanner.scanUpToCharacters(from: keywordStartCharacterSet, into: nil)
                    colorStartLocation = rangeScanner.scanLocation
                    if (colorStartLocation + 1) < rangeStringLength {
                        rangeScanner.scanLocation = colorStartLocation + 1
                    }
                    rangeScanner.scanUpToCharacters(from: keywordEndCharacterSet, into: nil)
                    colorEndLocation = rangeScanner.scanLocation

                    if colorEndLocation > rangeStringLength || colorStartLocation == colorEndLocation {
                        break;
                    }

                    let keywordTestString = documentString.substring(with: NSRange(location: colorStartLocation + rangeLocation, length: colorEndLocation - colorStartLocation)).uppercased()

                    if keywords.contains(keywordTestString) {
                        setColor(keywordsColor, for: NSRange(location: colorStartLocation + rangeLocation, length: rangeScanner.scanLocation - colorStartLocation));
                    }
                }

            }
//
//
//            //
//            // Autocomplete
//            //
//            if ([self.autocompleteWords count] > 0) {
//
//                // reset scanner
//                [rangeScanner mgs_setScanLocation:0];
//
//                // scan range to end
//                while (![rangeScanner isAtEnd]) {
//                    [rangeScanner scanUpToCharactersFromSet:self.keywordStartCharacterSet intoString:nil];
//                    colorStartLocation = [rangeScanner scanLocation];
//                    if ((colorStartLocation + 1) < rangeStringLength) {
//                        [rangeScanner mgs_setScanLocation:(colorStartLocation + 1)];
//                    }
//                    [rangeScanner scanUpToCharactersFromSet:self.keywordEndCharacterSet intoString:nil];
//
//                    colorEndLocation = [rangeScanner scanLocation];
//                    if (colorEndLocation > rangeStringLength || colorStartLocation == colorEndLocation) {
//                        break;
//                    }
//
//                    NSString *autocompleteTestString = nil;
//                    if (!keywordsCaseSensitive) {
//                        autocompleteTestString = [[documentString substringWithRange:NSMakeRange(colorStartLocation + rangeLocation, colorEndLocation - colorStartLocation)] lowercaseString];
//                    } else {
//                        autocompleteTestString = [documentString substringWithRange:NSMakeRange(colorStartLocation + rangeLocation, colorEndLocation - colorStartLocation)];
//                    }
//                    if ([self.autocompleteWords containsObject:autocompleteTestString]) {
//                        if (!reColorKeywordIfAlreadyColored) {
//                            if ([[firstLayoutManager temporaryAttributesAtCharacterIndex:colorStartLocation + rangeLocation effectiveRange:NULL] isEqualToDictionary:commandsColor]) {
//                                continue;
//                            }
//                        }
//
//                        [self setColor:autocompleteWordsColor range:NSMakeRange(colorStartLocation + rangeLocation, [rangeScanner scanLocation] - colorStartLocation)];
//                    }
//                }
//
//            }
//
//
//            //
//            // Second string, first pass
//            //
//
//            if (![self.secondString isEqualToString:@""]) {
//
//                NSError* error= nil;
//                secondStringMatcher = [[NSRegularExpression alloc]initWithPattern:[NSString stringWithFormat:@"%@[^%@\\\\\\r\\n]*+(?:\\\\(?:.|$)[^%@\\\\]*+)*+%@", self.secondString, self.secondString, self.secondString, self.secondString] options:0 error:&error];
//                if(error == nil){
//                    [secondStringMatcher enumerateMatchesInString:rangeString options:NSMatchingReportProgress range:NSMakeRange(0, rangeString.length-1) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
//                        if(result != nil){
//                        NSRange foundRange = result.range;
//                        if(foundRange.location != NSNotFound && foundRange.length > 0){
//                        [self setColor:stringsColor range:NSMakeRange(foundRange.location + rangeLocation + 1, foundRange.length - 1)];
//                        }
//                        }
//
//                        }];
//                }
//                else{
//                    return;
//                }
//
//            }
//
//
//            //
//            // First string
//            //
//
//            if (![self.firstString isEqualToString:@""]) {
//                NSError* error = nil;
//                firstStringMatcher = [[NSRegularExpression alloc] initWithPattern:[NSString stringWithFormat:@"%@[^%@\\\\\\r\\n]*+(?:\\\\(?:.|$)[^%@\\\\\\r\\n]*+)*+%@", self.firstString, self.firstString, self.firstString, self.firstString] options:0 error:&error];
//                if(error == nil){
//                    [firstStringMatcher enumerateMatchesInString:rangeString options:NSMatchingReportProgress range:NSMakeRange(0, rangeString.length-1)  usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
//                        if(result != nil){
//                        NSRange foundRange = result.range;
//                        if(foundRange.location != NSNotFound){
//                        //                                if (![[firstLayoutManager temporaryAttributesAtCharacterIndex:foundRange.location + rangeLocation effectiveRange:NULL] isEqualToDictionary:stringsColor]) {
//                        [self setColor:stringsColor range:NSMakeRange(foundRange.location + rangeLocation + 1, foundRange.length - 1)];
//                        //                                }
//                        }
//                        }
//                        }];
//                }
//                else{
//                    NSLog(@"String error:%@",error);
//                    return;
//                }
//
//            }
//
//
//            //
//            // Attributes
//            //
//
//            // reset scanner
//            [rangeScanner mgs_setScanLocation:0];
//
//            // scan range to end
//            while (![rangeScanner isAtEnd]) {
//                [rangeScanner scanUpToString:@" " intoString:nil];
//                colorStartLocation = [rangeScanner scanLocation];
//                if (colorStartLocation + 1 < rangeStringLength) {
//                    [rangeScanner mgs_setScanLocation:colorStartLocation + 1];
//                } else {
//                    break;
//                }
//                if (![[firstLayoutManager temporaryAttributesAtCharacterIndex:(colorStartLocation + rangeLocation) effectiveRange:NULL] isEqualToDictionary:commandsColor]) {
//                    continue;
//                }
//
//                [rangeScanner scanCharactersFromSet:self.attributesCharacterSet intoString:nil];
//                colorEndLocation = [rangeScanner scanLocation];
//
//                if (colorEndLocation + 1 < rangeStringLength) {
//                    [rangeScanner mgs_setScanLocation:[rangeScanner scanLocation] + 1];
//                }
//
//                if ([documentString characterAtIndex:colorEndLocation + rangeLocation] == '=') {
//                    [self setColor:attributesColor range:NSMakeRange(colorStartLocation + rangeLocation, colorEndLocation - colorStartLocation)];
//                }
//            }
//
//
//
//            //
//            // Color single-line comments
//            //
//
//            for (NSString *singleLineComment in self.singleLineComments) {
//                if (![singleLineComment isEqualToString:@""]) {
//
//                    // reset scanner
//                    [rangeScanner mgs_setScanLocation:0];
//                    searchSyntaxLength = [singleLineComment length];
//
//                    // scan range to end
//                    while (![rangeScanner isAtEnd]) {
//
//                        // scan for comment
//                        [rangeScanner scanUpToString:singleLineComment intoString:nil];
//                        colorStartLocation = [rangeScanner scanLocation];
//
//                        // common case handling
//                        if ([singleLineComment isEqualToString:@"//"]) {
//                            if (colorStartLocation > 0 && [rangeString characterAtIndex:colorStartLocation - 1] == ':') {
//                                [rangeScanner mgs_setScanLocation:colorStartLocation + 1];
//                                continue; // To avoid http:// ftp:// file:// etc.
//                            }
//                        } else if ([singleLineComment isEqualToString:@"#"]) {
//                            if (rangeStringLength > 1) {
//                                rangeOfLine = [rangeString lineRangeForRange:NSMakeRange(colorStartLocation, 0)];
//                                if ([rangeString rangeOfString:@"#!" options:NSLiteralSearch range:rangeOfLine].location != NSNotFound) {
//                                    [rangeScanner mgs_setScanLocation:NSMaxRange(rangeOfLine)];
//                                    continue; // Don't treat the line as a comment if it begins with #!
//                                } else if (colorStartLocation > 0 && [rangeString characterAtIndex:colorStartLocation - 1] == '$') {
//                                    [rangeScanner mgs_setScanLocation:colorStartLocation + 1];
//                                    continue; // To avoid $#
//                                } else if (colorStartLocation > 0 && [rangeString characterAtIndex:colorStartLocation - 1] == '&') {
//                                    [rangeScanner mgs_setScanLocation:colorStartLocation + 1];
//                                    continue; // To avoid &#
//                                }
//                            }
//                        } else if ([singleLineComment isEqualToString:@"%"]) {
//                            if (rangeStringLength > 1) {
//                                if (colorStartLocation > 0 && [rangeString characterAtIndex:colorStartLocation - 1] == '\\') {
//                                    [rangeScanner mgs_setScanLocation:colorStartLocation + 1];
//                                    continue; // To avoid \% in LaTex
//                                }
//                            }
//                        }
//
//                        // If the comment is within an already Colored string then disregard it
//                        if (colorStartLocation + rangeLocation + searchSyntaxLength < documentStringLength) {
//                            if ([[firstLayoutManager temporaryAttributesAtCharacterIndex:colorStartLocation + rangeLocation effectiveRange:NULL] isEqualToDictionary:stringsColor]) {
//                                [rangeScanner mgs_setScanLocation:colorStartLocation + 1];
//                                continue;
//                            }
//                        }
//
//                        // this is a single line comment so we can scan to the end of the line
//                        endOfLine = NSMaxRange([rangeString lineRangeForRange:NSMakeRange(colorStartLocation, 0)]);
//                        [rangeScanner mgs_setScanLocation:endOfLine];
//
//                        // Color the comment
//                        [self setColor:commentsColor range:NSMakeRange(colorStartLocation + rangeLocation, [rangeScanner scanLocation] - colorStartLocation)];
//                    }
//                }
//            } // end for
//
//            //
//            // Second string, second pass
//            //
//
//            if (![self.secondString isEqualToString:@""]) {
//
//                [secondStringMatcher enumerateMatchesInString:rangeString options:NSMatchingReportProgress range:NSMakeRange(0, rangeString.length-1) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
//                    if(result != nil){
//                    NSRange foundRange = result.range;
//                    if(foundRange.location != NSNotFound && foundRange.length > 0){
//                    if ([[firstLayoutManager temporaryAttributesAtCharacterIndex:foundRange.location + rangeLocation effectiveRange:NULL] isEqualToDictionary:stringsColor] || [[firstLayoutManager temporaryAttributesAtCharacterIndex:foundRange.location + rangeLocation effectiveRange:NULL] isEqualToDictionary:commentsColor]) {
//                    return;
//                    }
//
//                    [self setColor:stringsColor range:NSMakeRange(foundRange.location + rangeLocation + 1, foundRange.length - 1)];
//                    }
//                    }
//
//                    }];
//            }

    }
}
