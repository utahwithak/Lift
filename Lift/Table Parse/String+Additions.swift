//
//  String+Additions.swift
//  Lift
//
//  Created by Carl Wieland on 9/29/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Foundation


extension String {
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
}
