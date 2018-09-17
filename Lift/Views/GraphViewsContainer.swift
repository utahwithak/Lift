//
//  GraphViewContainer.swift
//  Lift
//
//  Created by Carl Wieland on 10/9/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Cocoa

protocol GraphContainerViewDelegate: class {
    func containerView(_ containerView: GraphViewsContainer, didSelect view: NSView?)
}

class GraphViewsContainer: NSView {

    var arrowViews = [ArrowView]()

    weak var delegate: GraphContainerViewDelegate?

    var selectedView: NSView? {
        didSet {
            delegate?.containerView(self, didSelect: selectedView)
        }
    }

    override func mouseDown(with event: NSEvent) {
        let location = convert(event.locationInWindow, from: nil)
        guard let view = viewUnder(point: location) else {
            clearSelection()
            return
        }

        if view != selectedView {
            clearSelection()
            selectView(view)
        }

        moveView(with: event)

    }

    func moveView(with event: NSEvent) {

        guard let selectedView = selectedView else {
            return
        }

        let movingArrows = arrowViews.filter {
            return $0.to.view?.view == selectedView || $0.from.view?.view == selectedView
        }

        var isMoving = false
        var lastPoint = convert(event.locationInWindow, from: nil)

        while let curEvent = self.window?.nextEvent(matching: [.leftMouseUp, .leftMouseDragged]), curEvent.type != .leftMouseUp {
            self.autoscroll(with: curEvent)
            let curPoint = convert(curEvent.locationInWindow, from: nil)
            if !isMoving && ((abs(curPoint.x - lastPoint.x) >= 2.0) || (abs(curPoint.y - lastPoint.y) >= 2.0)) {
                isMoving = true
            }
            if isMoving {
                var allNeedRefresh = false

                if lastPoint != curPoint {
                    selectedView.frame = selectedView.frame.offsetBy(dx: curPoint.x - lastPoint.x, dy: curPoint.y - lastPoint.y)
                    if selectedView.frame.minX < 0 {
                        frame.size.width -= selectedView.frame.minX
                        for view in subviews {
                            view.frame = view.frame.offsetBy(dx: -1 * selectedView.frame.minX, dy: 0)
                        }
                        allNeedRefresh = true

                    }

                    if selectedView.frame.minY < 0 {
                        frame.size.height -= selectedView.frame.minY
                        for view in subviews {
                            view.frame = view.frame.offsetBy(dx: 0, dy: -1 * selectedView.frame.minY)
                        }
                        allNeedRefresh = true
                    }
                }
                lastPoint = curPoint

                if allNeedRefresh {
                    arrowViews.forEach({ $0.refreshPath() })
                } else {
                    movingArrows.forEach({ $0.refreshPath()})
                }

                self.setNeedsDisplay(self.bounds)

            }
        }
    }

    func viewUnder(point: CGPoint) -> NSView? {
        return subviews.first(where: { $0.frame.contains(point) })
    }

    func selectView(_ view: NSView) {
        clearSelection()
        selectedView = view
        bringSubviewToFront(view)
        view.layer?.borderColor = NSColor.blue.cgColor
        view.shadow?.shadowColor = NSColor.blue
    }

    func clearSelection() {
        selectedView?.layer?.borderColor = NSColor.darkGray.cgColor
        selectedView?.shadow?.shadowColor = NSColor.lightGray
        selectedView = nil
    }

    func bringSubviewToFront(_ view: NSView) {
        view.removeFromSuperview()
        addSubview(view, positioned: .above, relativeTo: nil)
    }

    override func draw(_ dirtyRect: NSRect) {
        let thisViewSize = self.bounds

        NSColor(named: "graphViewBackground")?.set()
        __NSRectFill(dirtyRect)
        NSColor(named: "graphViewGridLines")?.set()

        let gridWidth = thisViewSize.size.width
        let gridHeight = thisViewSize.size.height

        var i: CGFloat = 0
        NSBezierPath.defaultLineWidth = 1

        let gridOffset: CGFloat = 20
        while i < gridWidth {

            i += gridOffset
            var lineShift: CGFloat = 0.5
            if Int(i) % 100 == 0 {
                lineShift = 0
                NSBezierPath.defaultLineWidth = 2
            } else {
                NSBezierPath.defaultLineWidth = 1
            }

            let x = i + lineShift
            let startPoint = CGPoint(x: x, y: lineShift)
            let endPoint = CGPoint(x: x, y: gridHeight + lineShift)
            NSBezierPath.strokeLine(from: startPoint, to: endPoint)

        }

        i = 0
        while i < gridHeight {

            i += gridOffset
            var lineShift: CGFloat = 0.5
            if Int(i) % 100 == 0 {
                lineShift = 0
                NSBezierPath.defaultLineWidth = 2
            } else {
                NSBezierPath.defaultLineWidth = 1
            }

            let y = i + lineShift
            let startPoint = CGPoint(x: lineShift, y: y)
            let endPoint = CGPoint(x: gridWidth + lineShift, y: y)
            NSBezierPath.strokeLine(from: startPoint, to: endPoint)
        }

        NSColor.black.set()
        NSBezierPath.defaultLineWidth = 3
        for view in arrowViews {
            view.path?.lineWidth = 3
            view.path?.stroke()
        }
    }
}
