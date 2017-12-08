//
//  NSError+Additions.swift
//  Lift
//
//  Created by Carl Wieland on 11/14/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Foundation

extension NSError {
    var isUserCanceledError: Bool {
        return code == LiftError.userCanceled.rawValue && domain == LiftError.errorDomain
    }
}


enum LiftError: Int, CustomNSError {

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
    case unknownBindType        = -11

    public static var errorDomain: String {
        return "com.datumapps.lift"
    }

    var errorCode: Int {
        return self.rawValue
    }

    // To make it work when casting to NSError's
    var errorUserInfo: [String: Any] {
        return [NSLocalizedDescriptionKey: localizedDescription]
    }

    var localizedDescription: String {
        switch self {
            case .unknownOperationError: return NSLocalizedString("Operation Failed, unknown error occurred", comment: "Unknown error description")
            case .noQueryError: return NSLocalizedString("No Query Error", comment: "Missing query when attempting to execute")
            case .unableToCreateFile: return NSLocalizedString("Failed to create file", comment: "Unable to create CSV file error")
            case .invalidUsage: return NSLocalizedString("Invalid usage!", comment: "Invalid usage error message")
            case .integrityCheck: return NSLocalizedString("Invalid return from Integrity check!", comment: "Message when the inetrigty check returns something unexpected!")
            case .userCanceled: return NSLocalizedString("User Canceled", comment: "Error description when canceling in the middle of a query")
            case .invalidBind: return NSLocalizedString("Attempting to bind an argument thats not there!", comment: " Error when attempting to bind an argument thats not there")
            case .invalidColumn: return NSLocalizedString("Invalid column info", comment: "Error message when there is invalid format for pragma table_info")
            case .invalidTable: return NSLocalizedString("Invalid table data row", comment: "Invalid sqlite master row data error")
            case .noDatabase: return  NSLocalizedString("No Database!", comment: "No database error")
            case .unknownBindType: return NSLocalizedString("Unable to bind value, unknown type", comment: "Attempted to bind object with unknown type.")
        }
    }
}
