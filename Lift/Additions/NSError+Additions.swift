//
//  NSError+Additions.swift
//  Lift
//
//  Created by Carl Wieland on 11/14/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Foundation
extension NSError {

    static let liftDomain = "com.datumapps.lift"
    convenience init(code: ErrorCodes, description: String) {
        self.init(domain: NSError.liftDomain, code: code.rawValue, userInfo: [NSLocalizedDescriptionKey: description])
    }

    enum ErrorCodes: Int {
        case unknownOperationError  = -1
        case noQueryError           = -2
        case unableToCreateFile     = -3
        case invalidUsage           = -4
        case integrityCheck         = -5
        case userCanceled           = -6
        case invalidBind            = -7
        case invalidColumn          = -8
        case invalidTable           = -9
        case noDatabase             = -10

    }


    static let unknownOperationError = NSError(code: .unknownOperationError, description: NSLocalizedString("Operation Failed, unknown error occurred", comment: "Unknown error description"))

    static let noQueryError = NSError(code: .noQueryError, description: NSLocalizedString("No Query Error", comment: "Missing query when attempting to execute"))

    static let unableToCreateFileError = NSError(code: .unableToCreateFile, description: NSLocalizedString("Failed to create file", comment: "Unable to create CSV file error"))

    static let invalidUsage = NSError(code: .invalidUsage, description: NSLocalizedString("Invalid usage!", comment: "Invalid usage error message"))

    static let integretyCheckError = NSError(code: .integrityCheck, description: NSLocalizedString("Invalid return from Integrity check!", comment: "Message when the inetrigty check returns something unexpected!"))

    static let userCanceledError = NSError(code: .userCanceled, description: NSLocalizedString("User Canceled", comment: "Error description when canceling in the middle of a query"))

    static let invalidBindError = NSError(code: .invalidBind, description: NSLocalizedString("Attempting to bind an argument thats not there!", comment: " Error when attempting to bind an argument thats not there"))

    static let invalidColumnError = NSError(code: .invalidColumn, description: NSLocalizedString("Invalid column info", comment: "Error message when there is invalid format for pragma table_info"))

    static let invalidTableError = NSError(code: .invalidTable, description: NSLocalizedString("Invalid table data row", comment: "Invalid sqlite master row data error"))

    static let noDatabaseError = NSError(code: .noDatabase, description: NSLocalizedString("No Database!", comment: "No database error"))

    var isUserCanceledError: Bool {
        return code == ErrorCodes.userCanceled.rawValue && domain == NSError.liftDomain
    }
}
