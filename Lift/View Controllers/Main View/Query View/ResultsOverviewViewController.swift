//
//  ResultsOverviewViewController.swift
//  Lift
//
//  Created by Carl Wieland on 11/13/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Cocoa

class ResultsOverviewViewController: NSViewController {

    @objc dynamic var stillLoading = false {
        willSet {
            willChangeValue(forKey: #keyPath(ResultsOverviewViewController.results))
        }
        didSet {
            didChangeValue(forKey: #keyPath(ResultsOverviewViewController.results))
        }
    }

    @objc var results = [ExecuteQueryResult]()


}
