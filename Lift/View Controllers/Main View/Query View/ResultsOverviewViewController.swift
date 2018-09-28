//
//  ResultsOverviewViewController.swift
//  Lift
//
//  Created by Carl Wieland on 11/13/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Cocoa

protocol ResultsOverviewDelegate: class {
    func shouldSelect(identifier: String)
}

class ResultsOverviewViewController: NSViewController {

    @IBOutlet weak var progressIndicator: NSProgressIndicator!

    weak var delegate: ResultsOverviewDelegate?

    @objc dynamic var stillLoading = false {
        willSet {
            willChangeValue(forKey: #keyPath(ResultsOverviewViewController.results))
        }
        didSet {
            didChangeValue(forKey: #keyPath(ResultsOverviewViewController.results))
            updateProgressIndicator()
        }
    }

    @objc var results = [ExecuteQueryResult]()

    override func viewDidLoad() {
        super.viewDidLoad()
        updateProgressIndicator()
    }

    private func updateProgressIndicator() {
        if stillLoading {
            progressIndicator?.animator().isHidden = false
            progressIndicator?.startAnimation(nil)
        } else {
            progressIndicator?.animator().isHidden = true
        }
    }

    @objc dynamic var selectedIndexes = IndexSet() {
        didSet {
            if let selectedIndex = selectedIndexes.first {
                let result = results[selectedIndex]
                if !result.rows.isEmpty {
                    delegate?.shouldSelect(identifier: result.identifier)
                }
            }
        }
    }
}
