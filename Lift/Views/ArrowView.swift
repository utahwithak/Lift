
//
//  ArrowView.swift
//  Exhume
//
//  Created by Carl Wieland on 9/27/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Cocoa

class ArrowPoint {
    weak var view: GraphTableView?
    let columns: [String]

    init(view: GraphTableView, columns: [String]) {
        self.view = view
        self.columns = columns
    }
}

class ArrowView: NSView {

    let from: ArrowPoint
    let to: ArrowPoint

    init(from: ArrowPoint, to: ArrowPoint) {
        self.from = from
        self.to = to

        super.init(frame: .zero)

        super.wantsLayer = true

        refreshPath()

    }
    override var wantsDefaultClipping: Bool {
        return false
    }

    func refreshPath() {
        defer {
            setNeedsDisplay(self.frame)
        }

        guard let fromView = from.view, let toView = to.view else {
            path = nil
            return
        }

        if from.columns.count > 1 {
            path = NSBezierPath()

            var fromColumnPoints = from.columns.map { fromView.outPoint(for: $0)}
            let avgFromY = fromColumnPoints.reduce(0, { $0 + $1.y}) / CGFloat(fromColumnPoints.count)

            let fromConnectionPoint = CGPoint(x: fromColumnPoints[0].x + 50, y: avgFromY)

            for fromPoint in fromColumnPoints {
                path?.move(to: fromPoint)
                let c1 = CGPoint(x: fromPoint.x + 25, y: fromPoint.y)
                let c2 = CGPoint(x: fromConnectionPoint.x - 25,y: fromConnectionPoint.y)
                path?.curve(to: fromConnectionPoint, controlPoint1: c1, controlPoint2: c2)
            }

            var inPoints: [CGPoint] = to.columns.map {
                let point = toView.inPoint(for: $0)
                return point
            }
            let avgToY = inPoints.reduce(0, {$0 + $1.y}) / CGFloat(inPoints.count)

            let toConnectionPoint = CGPoint(x: inPoints[0].x - 50, y: avgToY)

            path?.move(to: fromConnectionPoint)

            let connectorC1 = CGPoint(x: fromConnectionPoint.x + 50, y: fromConnectionPoint.y)
            let connectorC2 = CGPoint(x: toConnectionPoint.x - 50, y: toConnectionPoint.y)
            path?.curve(to: toConnectionPoint, controlPoint1: connectorC1, controlPoint2: connectorC2)

            for toPoint in inPoints {
                path?.move(to: toConnectionPoint)
                let c1 = CGPoint(x: toConnectionPoint.x + 25, y: toConnectionPoint.y)
                let c2 = CGPoint(x: toPoint.x - 25,y: toPoint.y)
                path?.curve(to: toPoint, controlPoint1: c1, controlPoint2: c2)
            }

        } else {

            guard let fromCol = from.columns.first, let toCol = to.columns.first else {
                return
            }

            let fromPoint = fromView.outPoint(for: fromCol)
            let toPoint = toView.inPoint(for: toCol)

            let fromX = CGPoint(x: fromPoint.x + 50, y: fromPoint.y);
            let toX = CGPoint(x: toPoint.x - 50, y: toPoint.y);

            path = NSBezierPath()
            path?.move(to: fromPoint)

            path?.curve(to: toPoint, controlPoint1: fromX, controlPoint2: toX)
        }

    }

    required init?(coder decoder: NSCoder) {
        fatalError()
    }

    public private(set) var path: NSBezierPath?



}
