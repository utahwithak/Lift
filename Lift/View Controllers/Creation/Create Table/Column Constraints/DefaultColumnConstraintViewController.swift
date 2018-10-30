//
//  DefaultColumnConstraintViewController.swift
//  Lift
//
//  Created by Carl Wieland on 10/29/18.
//  Copyright © 2018 Datum Apps. All rights reserved.
//

import AppKit

class DefaultColumnConstraintViewController: NSViewController {

    @IBOutlet weak var customField: NSTextField!
    @IBOutlet weak var radioHolder: NSView!
    var constraint: CreateColumnConstraintDefinitions.CreateDefaultValue? {
        return (representedObject as? CreateColumnDefinition)?.constraints.defaultConstraint
    }

    override func viewDidLoad() {
        if let value = constraint?.value {

            var tag = 0
            switch DefaultValue(text: value) {
            case .null:
                tag = 1
            case .TRUE:
                tag = 2
            case .FALSE:
                tag = 3
            case .current_time:
                tag = 4
            case .current_date:
                tag = 5
            case .current_timestamp:
                tag = 6
            default:
                tag = 7
            }

            if tag == 7 {
                constraint?.isEditingDefaultValue = true
            }
            for view in radioHolder.subviews {
                if let button = (view as? NSButton) {
                    button.state = (button.tag == tag) ? .on : .off
                }
            }
        }
    }

    @IBAction func defaultValueChanged(_ sender: NSButton) {
        constraint?.isEditingDefaultValue = false
        switch sender.tag {
        case 1:
            constraint?.value = "NULL"
        case 2:
            constraint?.value = "TRUE"
        case 3:
            constraint?.value = "FALSE"
        case 4:
            constraint?.value = "CURRENT_TIME"
        case 5:
            constraint?.value = "CURRENT_DATE"
        case 6:
            constraint?.value = "CURRENT_TIMESTAMP"
        case 7:
            constraint?.value = ""
            constraint?.isEditingDefaultValue = true
            customField.becomeFirstResponder()
        default:
            print("Tag:\(sender.tag)")
        }
    }
}
