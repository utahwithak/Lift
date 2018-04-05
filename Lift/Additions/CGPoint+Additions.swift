//
//  CGPoint+Additions.swift
//  Exhume
//
//  Created by Carl Wieland on 9/27/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Foundation

extension CGPoint {

    mutating func translateX(_ x: CGFloat) {
        self.x += x
    }

    mutating func translateY(_ y: CGFloat) {
        self.y += y
    }

    static func + ( lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }

    static func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }

    static func * (lhs: CGPoint, rhs: CGFloat) -> CGPoint {
        return CGPoint(x: lhs.x * rhs, y: lhs.y * rhs)

    }

    static func / (lhs: CGPoint, rhs: CGFloat) -> CGPoint {
        return CGPoint(x: lhs.x / rhs, y: lhs.y / rhs)

    }

    mutating func scale(by value: CGFloat) {
        x *= value
        y *= value
    }

    func scaled(by value: CGFloat) -> CGPoint {
        return CGPoint(x: x * value, y: y * value)
    }

    var length: CGFloat {
        return CGFloat(sqrt(x * x + y * y))
    }

    func normalized() -> CGPoint {
        let l = self.length
        return CGPoint(x: x / l, y: y / l)
    }

}
