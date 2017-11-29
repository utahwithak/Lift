//
//  Database+Options.swift
//  Lift
//
//  Created by Carl Wieland on 11/20/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Foundation

extension Database {

    @objc dynamic public var extensionsAllowed: Bool {
        set {

            willChangeValue(forKey: "extensionsAllowed")
            if !SQLite3ConfigHelper.setExtensionsEnabled(newValue, forConnection: connection) {
                print("Failed to set extensions allowed correctly!")
            }
            didChangeValue(forKey: "extensionsAllowed")
        }
        get {
            return SQLite3ConfigHelper.extensionsEnabled(for: connection)
        }
    }

    @objc dynamic public var foreignKeysEnabled: Bool {
        get {
            return SQLite3ConfigHelper.foreignKeysEnabled(for: connection)
        }
        set {
            willChangeValue(forKey: "foreignKeysEnabled")
            if !SQLite3ConfigHelper.setForeignKeysEnabled(newValue, forConnection: connection) {
                print("Failed to set fkeys correctly enabled/disabled")
            }
            didChangeValue(forKey: "foreignKeysEnabled")
        }
    }

    @objc dynamic public var isFTS3TokenizerEnabled: Bool {
        get {
            return SQLite3ConfigHelper.fts3TokenizerEnabled(for: connection)
        }
        set {
            willChangeValue(forKey: "isFTS3TokenizerEnabled")

            if !SQLite3ConfigHelper.setFTS3TokenizerEnabled(newValue, forConnection: connection) {
                print("Failed to set toknizer!")
            }
            didChangeValue(forKey: "isFTS3TokenizerEnabled")

        }
    }

    @objc dynamic public var triggersEnabled: Bool {
        get {
            return SQLite3ConfigHelper.triggersEnabled(for: connection)
        }
        set {
            willChangeValue(forKey: "triggersEnabled")

            if !SQLite3ConfigHelper.setTriggersEnabled(newValue, forConnection: connection) {
                print("Failed to set triggersEnabled!")
            }
            didChangeValue(forKey: "triggersEnabled")

        }
    }

}
