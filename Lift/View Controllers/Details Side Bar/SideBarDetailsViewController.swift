//
//  SideBarDetailsViewController.swift
//  Lift
//
//  Created by Carl Wieland on 10/5/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Cocoa

protocol DetailsContentProvider: class {
    var preferredSections: [DetailSection] { get }
}

enum DetailSection {
    case database
    case table

    
}


class SideBarDetailsViewController: LiftViewController {

    weak var contentProvider: DetailsContentProvider? {
        didSet {
            sections = contentProvider?.preferredSections ?? [.database]
        }
    }

    var sections: [DetailSection] = [.database, .table]

}
