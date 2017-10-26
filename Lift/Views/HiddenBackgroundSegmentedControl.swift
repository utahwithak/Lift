//
//  HiddenBackgroundSegmentedControl.swift
//  Lift
//
//  Created by Carl Wieland on 10/26/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Cocoa

class HiddenSegmentedCell: NSSegmentedCell {

    var frames = [Int: NSRect]()

    override func draw(withFrame cellFrame: NSRect, in controlView: NSView) {
        let image = NSImage(size: cellFrame.size)
        image.lockFocus()
        super.draw(withFrame: cellFrame, in: controlView)
        image.unlockFocus()
        for i in 0..<segmentCount {
            drawSegment(i, inFrame: frames[i]!, with: controlView)
        }
    }

    override func setSelected(_ selected: Bool, forSegment segment: Int) {

        if !selected {
            return
        }

        (0..<segmentCount).forEach { super.setSelected(false, forSegment: $0)}
        super.setSelected(selected, forSegment: segment)


    }

    override func drawSegment(_ segment: Int, inFrame frame: NSRect, with controlView: NSView) {
        frames[segment] = frame
        super.drawSegment(segment, inFrame: frame, with: controlView)
    }

    override func highlightColor(withFrame cellFrame: NSRect, in controlView: NSView) -> NSColor? {
        return NSColor.systemBlue
    }
    override var controlTint: NSControlTint {
        set {}
        get {return .blueControlTint}
    }
}

