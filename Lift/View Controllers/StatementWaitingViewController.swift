//
//  StatementWaitingViewController.swift
//  Lift
//
//  Created by Carl Wieland on 10/6/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Cocoa

enum OperationType {
    case statement(String)
    case customCall( () throws -> Bool )
}

protocol StatementWaitingViewDelegate: class {
    func waitingView(_ view: StatementWaitingViewController, finishedSuccessfully: Bool)
}

class StatementWaitingViewController: LiftViewController {

    var operation: OperationType!

    @IBOutlet weak var activityIndicator: NSProgressIndicator!

    @IBOutlet weak var indicatorHeight: NSLayoutConstraint!

    @IBOutlet weak var errorViewHeightConstraint: NSLayoutConstraint!

    weak var delegate: StatementWaitingViewDelegate?

    @IBOutlet weak var errorLabelHeight: NSLayoutConstraint!

    @IBOutlet weak var errorLabel: NSTextField!

    override func viewDidLoad() {
        super.viewDidLoad()

        errorViewHeightConstraint.constant = 0

        activityIndicator.startAnimation(nil)

        switch operation! {
        case .statement(let statement):
            document?.database.executeStatementInBackground(statement) {[weak self] (error) in
                self?.activityIndicator.stopAnimation(self)
                self?.indicatorHeight.constant = 0
                if let error = error {
                    self?.handleError(error)
                } else {
                    self?.handleSuccess()
                }
            }
        case .customCall(let operation):
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                do {
                    let success = try operation()
                    if success {
                        DispatchQueue.main.async {
                            self?.handleSuccess()
                        }
                    } else {
                        DispatchQueue.main.async {
                            self?.handleError(NSError.unknownOperationError)
                        }
                    }
                } catch {
                    DispatchQueue.main.async {
                        self?.handleError(error)
                    }
                }
            }

        }


    }

    func handleSuccess() {
        delegate?.waitingView(self, finishedSuccessfully: true)
    }

    @IBAction func toggleError(_ sender: NSButton) {
        if sender.state == .on {
            errorLabelHeight.constant = 56
        } else {
            errorLabelHeight.constant = 0
        }
    }
    func handleError(_ error: Error) {
        errorViewHeightConstraint.constant = 150
        errorLabel.stringValue = error.localizedDescription
        errorLabelHeight.constant = 56

    }
    @IBAction func abortOperation(_ sender: Any) {
        // even though we failed, report success and
        // abort the operation completly
        //
        delegate?.waitingView(self, finishedSuccessfully: true)

    }

    @IBAction func dismissWaitingView(_ sender: Any) {
        delegate?.waitingView(self, finishedSuccessfully: false)
    }

    @IBOutlet weak var abortOperationButton: NSButton!

    @IBOutlet weak var dimissViewButton: NSButton!
}
