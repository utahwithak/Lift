//
//  LineNumberView.swift
//  Lift
//
//  Created by Carl Wieland on 10/3/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Cocoa

class LineNumberView: NSRulerView {

    private static let DEFAULT_THICKNESS: CGFloat = 22.0
    private static let RULER_MARGIN: CGFloat = 5.0

    private var backgroundColor = NSColor.white

    private var  invalidCharacterIndex = 0

    var font: NSFont?

    var textColor: NSColor?

    init(scrollView: NSScrollView) {
        super.init(scrollView: scrollView, orientation: .verticalRuler)
        clientView = scrollView.documentView
    }

    required init(coder: NSCoder) {
        super.init(coder: coder)
    }

    private var lineIndices = [Int]()

    override func awakeFromNib() {
        self.clientView = self.scrollView?.documentView
    }

    private var defaultFont: NSFont {
        return NSFont(name: "Menlo", size: NSFont.systemFontSize(for: .mini))!
    }

    private var defaultTextColor: NSColor {
        return NSColor.init(calibratedWhite: 0.42, alpha: 1)
    }

    private var defaultAlternateTextColor: NSColor {
        return NSColor.white
    }

    override var clientView: NSView? {
        didSet {
            let oldClient = oldValue
            guard oldClient != clientView else {
                return
            }

            if let oldStorage = (oldClient as? NSTextView)?.textStorage {
                NotificationCenter.default.removeObserver(self, name: NSTextStorage.didProcessEditingNotification, object: oldStorage)
            }

            guard let newStorage = (clientView as? NSTextView)?.textStorage else {
                return
            }

            NotificationCenter.default.addObserver(self, selector: #selector(textStorageDidProcessEditing), name: NSTextStorage.didProcessEditingNotification, object: newStorage)

            invalidateLineIndices(from: 0)


        }
    }

    override func textStorageDidProcessEditing(_ notification: Notification) {
        guard let storage = notification.object as? NSTextStorage else {
            return
        }

        // Invalidate the line indices. They will be recalculated and re-cached on demand.
        let range = storage.editedRange
        if range.location != NSNotFound {
            invalidateLineIndices(from: range.location)
            needsDisplay = true
        }
    }

    var count: Int {
        return lineIndices.count
    }

    override var requiredThickness: CGFloat {

        let lineCount = count
        var digits = 1;
        if lineCount > 0 {
            digits = Int(log10(Double(lineCount)) + 1)
        }

        let sampleString = [String](repeating:"8", count: digits).joined()

        let stringSize = (sampleString as NSString).size(withAttributes:  textAttributes)
        
        // Round up the value. There is a bug on 10.4 where the display gets all wonky when scrolling if you don't
        // return an integral value here.
        return ceil(max(LineNumberView.DEFAULT_THICKNESS, stringSize.width + LineNumberView.RULER_MARGIN * 2));
    }

    lazy var textAttributes: [NSAttributedStringKey: Any] = {
        let font = self.font ?? defaultFont
        let color = textColor ?? defaultTextColor
        return [.font: font, .foregroundColor: color]
    }()



    private func invalidateLineIndices(from characterIndex: Int) {
        invalidCharacterIndex = min(characterIndex, invalidCharacterIndex);
    }

    private func calculateLines() {
        guard let textView = clientView as? NSTextView else {
            print("Invalid client view!")
            return
        }

        let text = textView.string as NSString
        let stringLength = text.length
        let count = lineIndices.count

        var charIndex = 0;
        var lineIndex = lineNumber(for: invalidCharacterIndex)
        if count > 0 {
            charIndex = lineIndices[lineIndex]
        }

        repeat {
            if lineIndex < count {
                lineIndices[lineIndex] = charIndex
            } else {
                lineIndices.append(charIndex)
            }

            charIndex = NSMaxRange(text.lineRange(for: NSRange(location: charIndex, length: 0)));
            lineIndex += 1
        } while charIndex < stringLength;

        if lineIndex < count {
            lineIndices.removeLast(count - lineIndex)
        }

        invalidCharacterIndex = Int.max

        // Check if text ends with a new line.

        var lineEnd = 0
        var contentEnd = 0
        (text as NSString).getLineStart(nil, end: &lineEnd, contentsEnd: &contentEnd, for: NSRange(location: lineIndices.last!, length: 0))

        if contentEnd < lineEnd {
            lineIndices.append(charIndex)
        }

        // See if we need to adjust the width of the view
        let oldThickness = ruleThickness
        let newThickness = requiredThickness
        if fabs(oldThickness - newThickness) > 1 {
            DispatchQueue.main.async {
                self.ruleThickness = newThickness
            }
        }


    }

    private func lineNumber(for charIndex: Int) -> Int {

        // Binary search
        var left = 0;
        var right = lineIndices.count
        while (right - left) > 1 {
            let mid = (right + left) / 2;
            let lineStart = lineIndices[mid]

            if charIndex < lineStart {
                right = mid;
            } else if charIndex > lineStart {
                left = mid;
            } else {
                return mid;
            }
        }
        return left;
    }

    private let nullRange = NSMakeRange(NSNotFound, 0);

    func drawBackground() {
        let bounds = self.bounds

        backgroundColor.set()

        __NSRectFill(bounds);
        NSColor(calibratedWhite: 0.58, alpha: 1).set()
        NSBezierPath.strokeLine(from: NSPoint(x: bounds.maxX - 0.5, y: bounds.minY), to: NSPoint(x: bounds.maxX - 0.5, y: bounds.maxY))

    }

    override func drawHashMarksAndLabels(in rect: NSRect) {

        let boundWidth = NSWidth(bounds)

        drawBackground()


        guard let textView = clientView as? NSTextView, let layoutManager = textView.layoutManager, let container = textView.textContainer, let visibleRect = scrollView?.contentView.bounds else {
            print("invalid client view!")
            return
        }

        let yinset = textView.textContainerInset.height

        if invalidCharacterIndex < Int.max {
            calculateLines()
        }

        let lines = lineIndices

        // Find the characters that are currently visible
        let glyphRange = layoutManager.glyphRange(forBoundingRect: visibleRect, in: container)
        var range =  layoutManager.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)

        // Fudge the range a tad in case there is an extra new line at end.
        // It doesn't show up in the glyphs so would not be accounted for.
        range.length += 1

        let count = lines.count
        let start = lineNumber(for: range.location)
        guard start < count else {
            return
        }

        let context = NSStringDrawingContext()
        let textAttributes = self.textAttributes
        for line in start..<count {

            let index = lines[line]

            if NSLocationInRange(index, range) {
                var rectCount = 0
                let rects = layoutManager.rectArray(forCharacterRange: NSRange(location: index, length: 0),
                                                    withinSelectedCharacterRange: nullRange,
                                                    in: container,
                                                    rectCount: &rectCount)

                if let rects = rects, rectCount > 0 {
                    // Note that the ruler view is only as tall as the visible
                    // portion. Need to compensate for the clipview's coordinates.
                    let ypos = yinset + NSMinY(rects[0]) - NSMinY(visibleRect)

                    // Line numbers are internally stored starting at 0
                    let labelText = NSString(format:"%jd", line + 1)

                    let stringSize = labelText.size(withAttributes: textAttributes)

                    // Draw string flush right, centered vertically within the line
                    let textRect = NSRect(x: boundWidth - stringSize.width - LineNumberView.RULER_MARGIN,
                                          y: ypos + (NSHeight(rects[0]) - stringSize.height) / 2.0,
                                      width: boundWidth - LineNumberView.RULER_MARGIN * 2.0,
                                     height: NSHeight(rects[0]))
                    labelText.draw(with: textRect, options: [.usesLineFragmentOrigin], attributes: textAttributes, context: context)
                }
            }
            if index > NSMaxRange(range) {
                break;
            }
        }

    }
}
